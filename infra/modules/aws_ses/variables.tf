variable "email_identities" {
  description = "Map of SES email identities to verify (email addresses only). Use domain_identities for domains."
  type = map(object({
    name = string # Email address (e.g. noreply@example.com)
  }))
  default = {}
}

variable "domain_identities" {
  description = "Map of SES domain identities to verify. Each key is a unique identifier, value is the domain name."
  type = map(object({
    name = string # Domain (e.g. example.com)
  }))
  default = {}
}

variable "configuration_sets" {
  description = "Map of SES configuration sets to create. Each key is a unique identifier."
  type = map(object({
    name                       = string
    reputation_metrics_enabled = optional(bool, false)
    sending_enabled            = optional(bool, true)
    # Optional: event_destination blocks (separate resource in AWS)
  }))
  default = {}
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "client" {
  description = "Client name for naming conventions"
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name for naming conventions"
  type        = string
  default     = ""
}
