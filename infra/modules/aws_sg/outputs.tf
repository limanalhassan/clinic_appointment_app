output "security_group_ids" {
  description = "Security group IDs by security group key."
  value       = { for k, v in aws_security_group.this : k => v.id }
}

output "security_group_arns" {
  description = "Security group ARNs by security group key."
  value       = { for k, v in aws_security_group.this : k => v.arn }
}
