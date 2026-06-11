output "release_names" {
  description = "Map of deployed Helm release names, keyed by release key"
  value       = { for k, v in helm_release.this : k => v.name }
}

output "release_namespaces" {
  description = "Map of deployed Helm release namespaces, keyed by release key"
  value       = { for k, v in helm_release.this : k => v.namespace }
}

output "release_statuses" {
  description = "Map of deployed Helm release statuses, keyed by release key"
  value       = { for k, v in helm_release.this : k => v.status }
}
