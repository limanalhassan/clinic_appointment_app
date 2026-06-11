# ============================================================================
# VPC
# ============================================================================

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_ids" {
  value = module.vpc.vpc_ids
}

output "subnet_ids" {
  value = module.vpc.subnet_ids
}

output "subnet_ids_nested" {
  value = module.vpc.subnet_ids_nested
}

# ============================================================================
# Security Groups
# ============================================================================

output "security_group_ids" {
  value = module.security_groups.security_group_ids
}

output "security_group_arns" {
  value = module.security_groups.security_group_arns
}

# ============================================================================
# IAM
# ============================================================================

output "iam_role_arns" {
  value = module.iam.role_arns
}

output "iam_role_names" {
  value = module.iam.role_names
}

# ============================================================================
# RDS
# ============================================================================

output "rds_instance_ids" {
  value = module.rds.database_instance_ids
}

output "rds_instance_arns" {
  value = module.rds.database_instance_arns
}

output "rds_instance_endpoints" {
  value = module.rds.database_instance_endpoints
}

output "rds_instance_addresses" {
  value = module.rds.database_instance_addresses
}

output "rds_instance_ports" {
  value = module.rds.database_instance_ports
}

output "rds_credentials_secret_arns" {
  value = module.rds.credentials_secret_arns
}

# ============================================================================
# ACM
# ============================================================================

output "acm_certificate_arns" {
  value = module.acm.certificate_arns
}

# ============================================================================
# ECR
# ============================================================================

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  value = module.ecr.repository_arns
}

output "ecr_repository_names" {
  value = module.ecr.repository_names
}

# ============================================================================
# SQS
# ============================================================================

output "sqs_queue_urls" {
  value = module.sqs.queue_urls
}

output "sqs_queue_arns" {
  value = module.sqs.queue_arns
}

output "sqs_queue_names" {
  value = module.sqs.queue_names
}

# ============================================================================
# EKS
# ============================================================================

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_certificate" {
  value = module.eks.cluster_ca_certificate
}

output "eks_cluster_arn" {
  value = module.eks.cluster_arn
}

# ============================================================================
# SES
# ============================================================================

output "ses_domain_identity_arns" {
  value = module.ses.domain_identity_arns
}

output "ses_configuration_set_names" {
  value = module.ses.configuration_set_names
}

# ============================================================================
# Pod Identity
# ============================================================================

output "pod_identity_role_arns" {
  value = module.pod_identity.role_arns
}

output "pod_identity_role_names" {
  value = module.pod_identity.role_names
}

output "pod_identity_association_ids" {
  value = module.pod_identity.association_ids
}
