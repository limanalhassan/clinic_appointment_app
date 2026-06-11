output "repository_urls" {
  description = "Map of ECR repository URLs, keyed by repository key"
  value       = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of ECR repository ARNs, keyed by repository key"
  value       = { for k, v in aws_ecr_repository.this : k => v.arn }
}

output "repository_names" {
  description = "Map of ECR repository names, keyed by repository key"
  value       = { for k, v in aws_ecr_repository.this : k => v.name }
}

output "registry_ids" {
  description = "Map of ECR registry IDs (AWS account ID), keyed by repository key"
  value       = { for k, v in aws_ecr_repository.this : k => v.registry_id }
}
