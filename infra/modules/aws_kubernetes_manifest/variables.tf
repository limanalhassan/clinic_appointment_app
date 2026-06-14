variable "manifests" {
  description = "Map of Kubernetes manifests to apply. Each value must contain a decoded manifest map (use yamldecode in the caller)."
  type        = any
  default     = {}
}

variable "labels" {
  description = "Map of kubernetes_labels resources to create."
  type = map(object({
    api_version = string
    kind        = string
    namespace   = optional(string, "default")
    name        = string
    labels      = map(string)
  }))
  default = {}
}

variable "annotations" {
  description = "Map of kubernetes_annotations resources to create."
  type = map(object({
    api_version = string
    kind        = string
    namespace   = optional(string, "default")
    name        = string
    annotations = map(string)
  }))
  default = {}
}
