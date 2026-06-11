output "provider_arns" {
  description = "Map of OIDC provider ARNs, keyed by provider key."
  value       = { for k, v in aws_iam_openid_connect_provider.this : k => v.arn }
}

output "role_arns" {
  description = "Map of IAM role ARNs, keyed by role key."
  value       = { for k, v in aws_iam_role.this : k => v.arn }
}

output "role_names" {
  description = "Map of IAM role names, keyed by role key."
  value       = { for k, v in aws_iam_role.this : k => v.name }
}
