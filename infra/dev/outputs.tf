# VPC
output "vpc_ids" {
  value = module.dev.vpc_ids
}

output "subnet_ids_nested" {
  value = module.dev.subnet_ids_nested
}

# Security Groups
output "security_group_ids" {
  value = module.dev.security_group_ids
}

# IAM
output "iam_role_arns" {
  value = module.dev.iam_role_arns
}

# RDS
output "rds_instance_endpoints" {
  value = module.dev.rds_instance_endpoints
}

output "rds_instance_addresses" {
  value = module.dev.rds_instance_addresses
}

output "rds_instance_ids" {
  value = module.dev.rds_instance_ids
}

output "rds_instance_arns" {
  value = module.dev.rds_instance_arns
}

output "rds_credentials_secret_arns" {
  value = module.dev.rds_credentials_secret_arns
}

# ACM
output "acm_certificate_arns" {
  value = module.dev.acm_certificate_arns
}

# ECR
output "ecr_repository_urls" {
  value = module.dev.ecr_repository_urls
}

output "ecr_repository_arns" {
  value = module.dev.ecr_repository_arns
}

output "ecr_repository_names" {
  value = module.dev.ecr_repository_names
}

# SQS
output "sqs_queue_urls" {
  value = module.dev.sqs_queue_urls
}

output "sqs_queue_arns" {
  value = module.dev.sqs_queue_arns
}

output "sqs_queue_names" {
  value = module.dev.sqs_queue_names
}

# EKS
output "kubeconfig_command" {
  description = "Run this to configure kubectl access to the cluster."
  value       = "aws eks update-kubeconfig --name ${module.dev.eks_cluster_name} --region ${local.config.region} --profile ${local.config.profile}"
}

output "eks_cluster_name" {
  value = module.dev.eks_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.dev.eks_cluster_endpoint
}

output "eks_cluster_arn" {
  value = module.dev.eks_cluster_arn
}

# Helm releases (KEDA + ArgoCD)
output "helm_release_statuses" {
  value = { for k, v in module.addons.release_statuses : k => v }
}

