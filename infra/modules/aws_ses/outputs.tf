output "domain_identity_arns" {
  description = "Map of SES domain identity ARNs, keyed by identity key"
  value       = { for k, v in aws_ses_domain_identity.this : k => v.arn }
}

output "domain_identities" {
  description = "Map of domain names, keyed by identity key"
  value       = { for k, v in aws_ses_domain_identity.this : k => v.domain }
}

output "email_identities" {
  description = "Map of verified email addresses, keyed by identity key"
  value       = { for k, v in aws_ses_email_identity.this : k => v.email }
}

output "configuration_set_names" {
  description = "Map of configuration set names, keyed by set key"
  value       = { for k, v in aws_ses_configuration_set.this : k => v.name }
}
