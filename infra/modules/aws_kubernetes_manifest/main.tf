resource "kubernetes_manifest" "this" {
  for_each = var.manifests

  manifest = each.value.manifest

  field_manager {
    name            = each.value.field_manager
    force_conflicts = each.value.force_conflicts
  }
}

resource "kubernetes_labels" "this" {
  for_each = var.labels

  api_version = each.value.api_version
  kind        = each.value.kind

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  labels = each.value.labels
}

resource "kubernetes_annotations" "this" {
  for_each = var.annotations

  api_version = each.value.api_version
  kind        = each.value.kind

  metadata {
    name      = each.value.name
    namespace = each.value.namespace
  }

  annotations = each.value.annotations
}
