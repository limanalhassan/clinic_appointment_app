# golden_module

Orchestrates all AWS infrastructure for a single environment. Reads JSON config files from the caller's `configs/` directory and wires together VPC, security groups, IAM, RDS, ACM, ECR, SQS, EKS, SES, and Pod Identity.

Called from an environment root (e.g. `infra/dev/`). The root module owns the backend, providers, and any resources that require runtime cluster credentials (Helm releases, Kubernetes manifests).

## Usage

```hcl
module "dev" {
  source      = "../modules/golden_module"
  env         = local.config.env
  config_root = path.module
}
```

`config_root` must be `path.module` from the caller — inside the module, `path.module` resolves to the module directory, not the caller's directory. All `file()` calls use `${var.config_root}/configs/...` to read the caller's config files.

## Config files

All configs live in `${config_root}/configs/`. Missing or empty files are safe — each uses `merge(default, try(jsondecode(file(...)), {}))`.

| File | Required | Creates |
|---|---|---|
| `config.json` | Yes | Base metadata: env, region, client, profile, tags |
| `config_vpc.json` | No | VPCs, subnets, route tables, IGW, NAT |
| `config_sg.json` | No | Security groups with ingress/egress rules |
| `config_iam.json` | No | IAM roles |
| `config_rds.json` | No | RDS instances + subnet groups + Secrets Manager credentials |
| `config_acm.json` | No | ACM certificates (DNS or email validation) |
| `config_ecr.json` | No | ECR repositories with lifecycle policies |
| `config_sqs.json` | No | SQS queues |
| `config_eks.json` | No | EKS cluster (Auto Mode) |
| `config_ses.json` | No | SES domain/email identities + configuration sets |
| `config_pod_identity.json` | No | EKS Pod Identity associations (IAM roles for pods) |

## Modules wired

```
golden_module
├── aws_vpc              — VPCs, subnets, IGW, NAT gateways
├── aws_sg               — Security groups (references VPC IDs by key)
├── aws_iam              — IAM roles
├── aws_rds              — RDS instances, subnet groups, Secrets Manager credentials
├── aws_acm              — ACM certificates
├── aws_ecr              — ECR repositories
├── aws_sqs              — SQS queues
├── aws_eks              — EKS cluster (Auto Mode via terraform-aws-modules/eks)
├── aws_ses              — SES identities and configuration sets
└── aws_eks_pod_identity — Pod Identity associations (links service accounts to IAM roles)
```

Helm releases (KEDA, ArgoCD) and Kubernetes manifests (EC2NodeClass, NodePool, IngressClass) are **not** in this module — they require the Kubernetes and Helm providers which need a live cluster endpoint. They are deployed from the environment root after this module runs.

## RDS credentials

The `aws_rds` module generates a random password and stores credentials as a JSON secret in Secrets Manager under the name set in `config_rds.json → credentials_secret_name`. Format: `{"username": "...", "password": "...", "host": "...", "port": ..., "dbname": "..."}`. No separate secrets config file is needed.

## Pod Identity

Pod Identity associations link a Kubernetes service account (namespace + name) to an IAM role. The IAM role trust policy uses `pods.eks.amazonaws.com` — no OIDC provider or IRSA annotation needed. Inline IAM policies are stored as JSON files in `infra/templates/policies/inline_policies/` and referenced by filename in `config_pod_identity.json`.

## Variables

| Name | Type | Description |
|---|---|---|
| `env` | string | Environment name (e.g. `dev`, `prod`) |
| `config_root` | string | Absolute path to the env folder — pass `path.module` from the caller |

## Key outputs

| Output | Description |
|---|---|
| `vpc_ids`, `subnet_ids` | VPC and subnet IDs by key |
| `security_group_ids` | Security group IDs by key |
| `rds_instance_endpoints`, `rds_instance_addresses` | RDS endpoints by database key |
| `rds_credentials_secret_arns` | Secrets Manager ARNs for RDS credentials |
| `ecr_repository_urls` | ECR URLs by repository key |
| `sqs_queue_urls`, `sqs_queue_arns` | SQS queue details by queue key |
| `eks_cluster_name`, `eks_cluster_endpoint`, `eks_cluster_arn` | EKS cluster details |
| `pod_identity_role_arns` | IAM role ARNs for Pod Identity associations by key |
| `ses_domain_identity_arns` | SES domain identity ARNs |
| `acm_certificate_arns` | ACM certificate ARNs by certificate key |
