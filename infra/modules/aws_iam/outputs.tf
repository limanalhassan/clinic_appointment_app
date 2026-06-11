output "role_ids" {
  description = "Map of IAM role IDs, keyed by the role key (includes both created and imported)"
  value       = { for k, v in local.roles_combined : k => v.id }
}

output "role_arns" {
  description = "Map of IAM role ARNs, keyed by the role key (includes both created and imported)"
  value       = { for k, v in local.roles_combined : k => v.arn }
}

output "role_names" {
  description = "Map of IAM role names, keyed by the role key (includes both created and imported)"
  value       = { for k, role in local.processed_roles : k => role.name }
}

output "instance_profile_names" {
  description = "Map of IAM instance profile names, keyed by the role key (only for roles with create_instance_profile = true)"
  value = {
    for k, role in local.processed_roles : k => (
      role.create_instance_profile == true ? (
        role.id != null ? data.aws_iam_instance_profile.existing[k].name : aws_iam_instance_profile.this[k].name
      ) : null
    )
    if role.create_instance_profile == true
  }
}

output "instance_profile_arns" {
  description = "Map of IAM instance profile ARNs, keyed by the role key (only for roles with create_instance_profile = true)"
  value = {
    for k, role in local.processed_roles : k => (
      role.create_instance_profile == true ? (
        role.id != null ? data.aws_iam_instance_profile.existing[k].arn : aws_iam_instance_profile.this[k].arn
      ) : null
    )
    if role.create_instance_profile == true
  }
}

