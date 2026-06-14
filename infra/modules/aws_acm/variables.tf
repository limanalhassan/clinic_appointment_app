variable "certificates" {
  description = "Map of ACM certificates to create. Each key is a unique identifier, value contains certificate configuration."
  type = map(object({
    domain_name               = string                     # Primary domain name (e.g., example.com)
    subject_alternative_names = optional(list(string), []) # Additional domain names (SANs)
    validation_method         = string                     # DNS or EMAIL
    validation_option = optional(list(object({
      domain_name       = string # Domain name to validate (must be in domain_name or subject_alternative_names)
      validation_domain = string # Domain to use for validation (e.g., _example.com)
    })), [])
    # DNS Validation (if validation_method = "DNS")
    route53_hosted_zone_key = optional(string) # Route53 hosted zone key for automatic DNS validation (requires vpc_route53_hosted_zone_ids)
    # Email Validation (if validation_method = "EMAIL")
    # No additional fields needed - AWS sends email to domain registrant
    tags = optional(map(string), {}) # Certificate-specific tags
  }))
  default = {}
}

variable "vpc_route53_hosted_zone_ids" {
  description = "Map of Route53 hosted zone IDs, keyed by hosted zone key (for resolving route53_hosted_zone_key references). Used for automatic DNS validation."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags to apply to all certificates"
  type        = map(string)
  default     = {}
}

variable "certificate_tags" {
  description = "Map of certificate-specific tags, keyed by certificate key"
  type        = map(map(string))
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

