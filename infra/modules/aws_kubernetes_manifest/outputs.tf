output "manifest_names" {
  description = "Map of applied manifest names, keyed by manifest key."
  value = {
    for k, v in kubernetes_manifest.this : k => v.manifest["metadata"]["name"]
  }
}

output "manifest_kinds" {
  description = "Map of applied manifest kinds, keyed by manifest key."
  value = {
    for k, v in kubernetes_manifest.this : k => v.manifest["kind"]
  }
}
