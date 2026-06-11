variable "oidc_providers" {
  description = "Map of OIDC providers to create. Each key is a unique identifier, value contains provider configuration."
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
  }))
  default = {}
}

variable "provider_tags" {
  description = "Map of provider-specific tags, keyed by provider key."
  type        = map(map(string))
  default     = {}
}

variable "roles" {
  description = "Map of IAM roles to create. Each role trusts one OIDC provider scoped to a subject claim."
  type = map(object({
    role_name     = string
    provider_key  = string
    subject       = string
    audience      = optional(string, "sts.amazonaws.com")
    inline_policy = optional(string, null)
  }))
  default = {}
}

variable "role_tags" {
  description = "Map of role-specific tags, keyed by role key."
  type        = map(map(string))
  default     = {}
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}
