output "database_instance_ids" {
  description = "RDS instance IDs by database key."
  value       = { for k, v in aws_db_instance.this : k => v.id }
}

output "database_instance_arns" {
  description = "RDS instance ARNs by database key."
  value       = { for k, v in aws_db_instance.this : k => v.arn }
}

output "database_instance_endpoints" {
  description = "RDS instance endpoints (host:port) by database key."
  value       = { for k, v in aws_db_instance.this : k => v.endpoint }
}

output "database_instance_addresses" {
  description = "RDS instance hostnames by database key."
  value       = { for k, v in aws_db_instance.this : k => v.address }
}

output "database_instance_ports" {
  description = "RDS instance ports by database key."
  value       = { for k, v in aws_db_instance.this : k => v.port }
}

output "credentials_secret_arns" {
  description = "Secrets Manager secret ARNs for RDS credentials by database key."
  value       = { for k, v in aws_secretsmanager_secret.credentials : k => v.arn }
}
