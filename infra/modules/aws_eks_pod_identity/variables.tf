variable "associations" {
  description = "Map of Pod Identity associations to create. Each key creates one IAM role and one EKS pod identity association."
  type = map(object({
    role_name       = string
    namespace       = string
    service_account = string
    inline_policy   = optional(string, null)
    policy_arns     = optional(list(string), [])
  }))
  default = {}
}

variable "cluster_name" {
  description = "EKS cluster name the associations are created against."
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "association_tags" {
  description = "Map of association-specific tags, keyed by association key."
  type        = map(map(string))
  default     = {}
}
