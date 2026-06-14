locals {
  config = jsondecode(file("${var.config_root}/configs/config.json"))
  config_vpc = merge(
    { vpcs = {} },
    try(jsondecode(file("${var.config_root}/configs/config_vpc.json")), {})
  )
  config_sg = merge(
    { security_groups = {} },
    try(jsondecode(file("${var.config_root}/configs/config_sg.json")), {})
  )
  config_iam = merge(
    { roles = {} },
    try(jsondecode(file("${var.config_root}/configs/config_iam.json")), {})
  )
  config_rds = merge(
    { databases = {}, database_tags = {} },
    try(jsondecode(file("${var.config_root}/configs/config_rds.json")), {})
  )
  config_acm = merge(
    { certificates = {}, certificate_tags = {} },
    try(jsondecode(file("${var.config_root}/configs/config_acm.json")), {})
  )
  config_ecr = merge(
    { repositories = {}, repository_tags = {} },
    try(jsondecode(file("${var.config_root}/configs/config_ecr.json")), {})
  )
  config_sqs = merge(
    { queues = {}, queue_tags = {} },
    try(jsondecode(file("${var.config_root}/configs/config_sqs.json")), {})
  )
  config_pod_identity = merge(
    { associations = {}, association_tags = {} },
    try(jsondecode(file("${var.config_root}/configs/config_pod_identity.json")), {})
  )
  config_eks = merge(
    { cluster = {} },
    try(jsondecode(file("${var.config_root}/configs/config_eks.json")), {})
  )
  config_ses = merge(
    { domain_identities = {}, email_identities = {}, configuration_sets = {} },
    try(jsondecode(file("${var.config_root}/configs/config_ses.json")), {})
  )
  config_github_oidc = merge(
    { providers = {}, provider_tags = {}, roles = {}, role_tags = {} },
    try(jsondecode(file("${var.config_root}/configs/config_github_oidc.json")), {})
  )
}

################################################
#                 VPC Module                   #
################################################

module "vpc" {
  source = "../../modules/aws_vpc"

  vpcs = local.config_vpc.vpcs
  tags = local.config.tags
}

################################################
#               Security Groups                #
################################################

module "security_groups" {
  source = "../../modules/aws_sg"

  vpc_ids         = module.vpc.vpc_ids
  security_groups = local.config_sg.security_groups
  tags            = local.config.tags

  depends_on = [module.vpc]
}

################################################
#               IAM Module                     #
################################################

module "iam" {
  source = "../../modules/aws_iam"

  roles = local.config_iam.roles
  tags  = local.config.tags
  env   = local.config.tags.env
}

################################################
#               RDS Module                     #
################################################

module "rds" {
  source = "../../modules/aws_rds"

  vpc_subnet_ids         = module.vpc.subnet_ids
  vpc_security_group_ids = module.security_groups.security_group_ids
  databases              = local.config_rds.databases
  tags                   = local.config.tags
  database_tags          = local.config_rds.database_tags

  depends_on = [module.vpc, module.security_groups]
}

################################################
#               ACM Module                     #
################################################

module "acm" {
  source = "../../modules/aws_acm"

  certificates                = local.config_acm.certificates
  vpc_route53_hosted_zone_ids = {}
  tags                        = local.config.tags
  certificate_tags            = local.config_acm.certificate_tags
}

################################################
#               ECR Module                     #
################################################

module "ecr" {
  source = "../../modules/aws_ecr"

  repositories    = local.config_ecr.repositories
  tags            = local.config.tags
  repository_tags = local.config_ecr.repository_tags
  env             = local.config.env
}

################################################
#               SQS Module                     #
################################################

module "sqs" {
  source = "../../modules/aws_sqs"

  queues     = local.config_sqs.queues
  tags       = local.config.tags
  queue_tags = local.config_sqs.queue_tags
  client     = local.config.client
  env        = local.config.env
}

################################################
#               EKS Module                     #
################################################

module "eks" {
  source = "../../modules/aws_eks"

  cluster_name                             = local.config_eks.cluster.name
  kubernetes_version                       = local.config_eks.cluster.kubernetes_version
  endpoint_public_access                   = local.config_eks.cluster.endpoint_public_access
  enable_cluster_creator_admin_permissions = local.config_eks.cluster.enable_cluster_creator_admin_permissions
  compute_config                           = local.config_eks.cluster.compute_config
  vpc_id                                   = module.vpc.vpc_id
  subnet_ids                               = [for key in local.config_eks.cluster.subnet_keys : module.vpc.subnet_ids[key]]
  tags                                     = local.config.tags

  depends_on = [module.vpc]
}

################################################
#               SES Module                     #
################################################

module "ses" {
  source = "../../modules/aws_ses"

  domain_identities  = local.config_ses.domain_identities
  email_identities   = local.config_ses.email_identities
  configuration_sets = local.config_ses.configuration_sets
  tags               = local.config.tags
  env                = local.config.env
}

################################################
#           EKS Pod Identity Module            #
################################################

locals {
  pod_identity_associations = {
    for k, v in local.config_pod_identity.associations : k => {
      role_name       = v.role_name
      namespace       = v.namespace
      service_account = v.service_account
      policy_arns     = lookup(v, "policy_arns", [])
      inline_policy   = lookup(v, "policy_file", null) != null ? file("${var.config_root}/../templates/policies/inline_policies/${v.policy_file}") : lookup(v, "inline_policy", null)
    }
  }
}

module "pod_identity" {
  source = "../../modules/aws_eks_pod_identity"

  associations     = local.pod_identity_associations
  cluster_name     = module.eks.cluster_name
  tags             = local.config.tags
  association_tags = local.config_pod_identity.association_tags

  depends_on = [module.eks]
}

################################################
#           GitHub OIDC Module                 #
################################################

locals {
  github_oidc_roles = {
    for k, v in local.config_github_oidc.roles : k => {
      role_name     = v.role_name
      provider_key  = v.provider_key
      subject       = v.subject
      audience      = lookup(v, "audience", "sts.amazonaws.com")
      inline_policy = lookup(v, "policy_file", null) != null ? file("${var.config_root}/../templates/policies/inline_policies/${v.policy_file}") : lookup(v, "inline_policy", null)
    }
  }
}

module "github_oidc" {
  source = "../../modules/aws_github_oidc"

  oidc_providers = local.config_github_oidc.providers
  provider_tags  = local.config_github_oidc.provider_tags
  roles          = local.github_oidc_roles
  role_tags      = local.config_github_oidc.role_tags
  tags           = local.config.tags
}
