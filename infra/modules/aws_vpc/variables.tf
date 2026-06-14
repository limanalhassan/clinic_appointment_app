variable "vpcs" {
  description = "Map of VPCs to create. Each key is a unique identifier, value contains VPC configuration."
  type = map(object({
    vpc_cidr                = string
    enable_dns_support      = optional(bool, true)
    enable_dns_hostnames    = optional(bool, true)
    instance_tenancy        = optional(string, "default")
    create_internet_gateway = optional(bool, true)
    create_nat_gateway      = optional(bool, false)
    nat_gateway_subnet_id   = optional(string, "")
    nat_gateway_subnet_key  = optional(string, "")
    vpc_name                = optional(string, "")
    igw_name                = optional(string, "")
    nat_gateway_name        = optional(string, "")
    subnets = optional(map(object({
      cidr_block                      = string
      availability_zone               = optional(string)
      map_public_ip_on_launch         = optional(bool, false)
      assign_ipv6_address_on_creation = optional(bool, false)
      ipv6_cidr_block                 = optional(string)
    })), {})
    route_tables = optional(map(object({
      routes = optional(list(object({
        cidr_block                 = optional(string)
        ipv6_cidr_block            = optional(string)
        gateway_id                 = optional(string)
        nat_gateway_id             = optional(string)
        use_internet_gateway       = optional(bool, false)
        use_nat_gateway            = optional(bool, false)
        egress_only_gateway_id     = optional(string)
        transit_gateway_id         = optional(string)
        vpc_endpoint_id            = optional(string)
        network_interface_id       = optional(string)
        destination_prefix_list_id = optional(string)
        carrier_gateway_id         = optional(string)
        local_gateway_id           = optional(string)
        vpc_peering_connection_id  = optional(string)
      })), [])
      subnet_associations = optional(list(string), [])
    })), {})
    subnet_tags      = optional(map(map(string)), {})
    route_table_tags = optional(map(map(string)), {})
  }))
  default = {}
  validation {
    condition = alltrue([
      for vpc_key, vpc in var.vpcs : can(cidrhost(vpc.vpc_cidr, 0))
    ])
    error_message = "All VPC CIDR blocks must be valid CIDR blocks."
  }
}

variable "tags" {
  description = "A map of tags to assign to all VPC resources"
  type        = map(string)
  default     = {}
}
