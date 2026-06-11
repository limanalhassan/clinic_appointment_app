variable "vpc_ids" {
  description = "Map of VPC IDs by VPC key, used to resolve vpc_key references in security group configs."
  type        = map(string)
  default     = {}
}

variable "security_groups" {
  description = "Map of security group configurations keyed by a logical name."
  type = map(object({
    name        = string
    description = string
    vpc_key     = string
    ingress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
    egress_rules = list(object({
      description = string
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    }))
  }))
  default = {}
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}
