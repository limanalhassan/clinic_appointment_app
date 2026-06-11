variable "repositories" {
  description = "Map of ECR repositories to create. Each key is a unique identifier, value contains repository configuration."
  type = map(object({
    name                 = string
    image_tag_mutability = optional(string, "IMMUTABLE")
    scan_on_push         = optional(bool, true)
    force_delete         = optional(bool, false)
    encryption_type      = optional(string, "AES256")
    kms_key              = optional(string, null)
    lifecycle_policy     = optional(string, null)
  }))
  default = {}
}

variable "tags" {
  description = "Common tags to apply to all repositories"
  type        = map(string)
  default     = {}
}

variable "repository_tags" {
  description = "Map of repository-specific tags, keyed by repository key"
  type        = map(map(string))
  default     = {}
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = ""
}
