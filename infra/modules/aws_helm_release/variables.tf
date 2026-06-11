variable "releases" {
  description = "Map of Helm releases to deploy. Each key is a unique identifier, value contains release configuration."
  type = map(object({
    name             = string
    repository       = string
    chart            = string
    chart_version    = string
    namespace        = string
    create_namespace = optional(bool, true)
    wait             = optional(bool, true)
    timeout          = optional(number, 300)
    values_yaml      = optional(string, null)
  }))
  default = {}
}
