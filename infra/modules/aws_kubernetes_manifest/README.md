# aws_kubernetes_manifest

Applies Kubernetes manifests, labels, and annotations to a cluster using the Kubernetes Terraform provider. Manifests are decoded from YAML template files in the caller before being passed in — this module only applies them.

Called directly from the environment root module (not inside golden_module) because the Kubernetes provider must be configured at root level with the cluster endpoint and CA certificate.

Supports:
- `kubernetes_manifest` — any CRD or native resource (EC2NodeClass, NodePool, IngressClass, IngressClassParams, etc.)
- `kubernetes_labels` — add labels to existing resources without owning the full resource
- `kubernetes_annotations` — add annotations to existing resources
