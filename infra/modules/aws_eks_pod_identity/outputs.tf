output "role_arns" {
  description = "Map of IAM role ARNs, keyed by association key."
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of IAM role names, keyed by association key."
  value       = { for k, v in aws_iam_role.this : k => v.name }
}

output "association_ids" {
  description = "Map of EKS pod identity association IDs, keyed by association key."
  value       = { for k, v in aws_eks_pod_identity_association.this : k => v.association_id }
}
