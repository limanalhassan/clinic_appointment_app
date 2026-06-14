variable "roles" {
  description = "Map of IAM roles to create or import. Each key is a unique identifier, value contains role configuration."
  type = map(object({
    name                    = string
    description             = optional(string)
    assume_role_policy      = optional(string)      # Direct JSON string
    assume_role_policy_file = optional(string)      # File name in assume-role/ folder (takes precedence)
    id                      = optional(string)      # If provided, imports existing role by name instead of creating new one
    create_instance_profile = optional(bool, false) # Create instance profile with same name as role
    inline_policies = optional(map(object({
      name        = string
      policy      = optional(string) # Direct JSON string
      policy_file = optional(string) # File name in policies/ folder (takes precedence)
    })), {})
    managed_policy_arns = optional(list(string), []) # List of AWS managed policy ARNs to attach
    tags                = optional(map(string), {})
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to all IAM roles and instance profiles"
  type        = map(string)
  default     = {}
}

variable "env" {
  description = "Environment name (e.g., prod, uat, dev) for use in policy templates"
  type        = string
  default     = ""
}

