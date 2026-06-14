# VPC IDs, CIDRs, and ARNs (keyed by VPC key)
output "vpc_ids" {
  description = "Map of VPC IDs, keyed by VPC key"
  value       = { for k, v in aws_vpc.this : k => v.id }
}

output "vpc_cidr_blocks" {
  description = "Map of VPC CIDR blocks, keyed by VPC key"
  value       = { for k, v in aws_vpc.this : k => v.cidr_block }
}

output "vpc_arns" {
  description = "Map of VPC ARNs, keyed by VPC key"
  value       = { for k, v in aws_vpc.this : k => v.arn }
}

# Internet Gateway IDs (keyed by VPC key, null if not created)
output "internet_gateway_ids" {
  description = "Map of Internet Gateway IDs, keyed by VPC key (null if not created)"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => (
      var.vpcs[vpc_key].create_internet_gateway ? aws_internet_gateway.this[vpc_key].id : null
    )
  }
}

# NAT Gateway IDs and Public IPs (keyed by VPC key, null if not created)
output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs, keyed by VPC key (null if not created)"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => (
      var.vpcs[vpc_key].create_nat_gateway ? aws_nat_gateway.this[vpc_key].id : null
    )
  }
}

output "nat_gateway_public_ips" {
  description = "Map of NAT Gateway public IP addresses, keyed by VPC key (null if not created)"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => (
      var.vpcs[vpc_key].create_nat_gateway ? aws_nat_gateway.this[vpc_key].public_ip : null
    )
  }
}

# Subnet IDs and CIDRs (nested map: VPC key -> subnet key -> ID/CIDR)
output "subnet_ids_nested" {
  description = "Nested map of subnet IDs: first level is VPC key, second level is subnet key"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => {
      for subnet_key in keys(coalesce(var.vpcs[vpc_key].subnets, {})) : subnet_key => (
        aws_subnet.this["${vpc_key}-${subnet_key}"].id
      )
    }
  }
}

output "subnet_cidrs_nested" {
  description = "Nested map of subnet CIDR blocks: first level is VPC key, second level is subnet key"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => {
      for subnet_key in keys(coalesce(var.vpcs[vpc_key].subnets, {})) : subnet_key => (
        aws_subnet.this["${vpc_key}-${subnet_key}"].cidr_block
      )
    }
  }
}

# Route Table IDs (nested map: VPC key -> route table key -> ID)
output "route_table_ids_nested" {
  description = "Nested map of route table IDs: first level is VPC key, second level is route table key"
  value = {
    for vpc_key in keys(var.vpcs) : vpc_key => {
      for rt_key in keys(coalesce(var.vpcs[vpc_key].route_tables, {})) : rt_key => (
        aws_route_table.this["${vpc_key}-${rt_key}"].id
      )
    }
  }
}

# Default Security Group IDs (keyed by VPC key)
output "default_security_group_ids" {
  description = "Map of default security group IDs, keyed by VPC key"
  value       = { for k, v in aws_vpc.this : k => v.default_security_group_id }
}

# Legacy outputs for backward compatibility (single VPC use case)
# These return the first VPC's values if only one VPC exists, or null if multiple VPCs exist
output "vpc_id" {
  description = "ID of the first VPC (legacy output for backward compatibility). Use vpc_ids[\"vpc_key\"] for multiple VPCs."
  value       = length(aws_vpc.this) == 1 ? values(aws_vpc.this)[0].id : null
}

output "vpc_cidr_block" {
  description = "CIDR block of the first VPC (legacy output for backward compatibility). Use vpc_cidr_blocks[\"vpc_key\"] for multiple VPCs."
  value       = length(aws_vpc.this) == 1 ? values(aws_vpc.this)[0].cidr_block : null
}

output "vpc_arn" {
  description = "ARN of the first VPC (legacy output for backward compatibility). Use vpc_arns[\"vpc_key\"] for multiple VPCs."
  value       = length(aws_vpc.this) == 1 ? values(aws_vpc.this)[0].arn : null
}

output "internet_gateway_id" {
  description = "ID of the first VPC's Internet Gateway (legacy output for backward compatibility). Use internet_gateway_ids[\"vpc_key\"] for multiple VPCs."
  value = length(aws_vpc.this) == 1 ? (
    var.vpcs[keys(var.vpcs)[0]].create_internet_gateway ? aws_internet_gateway.this[keys(var.vpcs)[0]].id : null
  ) : null
}

output "nat_gateway_id" {
  description = "ID of the first VPC's NAT Gateway (legacy output for backward compatibility). Use nat_gateway_ids[\"vpc_key\"] for multiple VPCs."
  value = length(aws_vpc.this) == 1 ? (
    var.vpcs[keys(var.vpcs)[0]].create_nat_gateway ? aws_nat_gateway.this[keys(var.vpcs)[0]].id : null
  ) : null
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the first VPC's NAT Gateway (legacy output for backward compatibility). Use nat_gateway_public_ips[\"vpc_key\"] for multiple VPCs."
  value = length(aws_vpc.this) == 1 ? (
    var.vpcs[keys(var.vpcs)[0]].create_nat_gateway ? aws_nat_gateway.this[keys(var.vpcs)[0]].public_ip : null
  ) : null
}

output "default_security_group_id" {
  description = "ID of the first VPC's default security group (legacy output for backward compatibility). Use default_security_group_ids[\"vpc_key\"] for multiple VPCs."
  value       = length(aws_vpc.this) == 1 ? values(aws_vpc.this)[0].default_security_group_id : null
}

# Legacy flat subnet_ids output (first VPC's subnets only, for backward compatibility)
output "subnet_ids" {
  description = "Map of subnet IDs from the first VPC, keyed by subnet key (legacy output for backward compatibility). Use subnet_ids[\"vpc_key\"][\"subnet_key\"] for multiple VPCs. ⚠️ Warning: This only returns subnets from the first VPC. If you have multiple VPCs, use the nested subnet_ids map instead."
  value = length(aws_vpc.this) > 0 ? (
    {
      for subnet_key in keys(coalesce(var.vpcs[keys(var.vpcs)[0]].subnets, {})) : subnet_key => (
        aws_subnet.this["${keys(var.vpcs)[0]}-${subnet_key}"].id
      )
    }
  ) : {}
}

output "subnet_cidrs" {
  description = "Map of subnet CIDR blocks from the first VPC, keyed by subnet key (legacy output for backward compatibility). Use subnet_cidrs[\"vpc_key\"][\"subnet_key\"] for multiple VPCs. ⚠️ Warning: This only returns subnets from the first VPC. If you have multiple VPCs, use the nested subnet_cidrs map instead."
  value = length(aws_vpc.this) > 0 ? (
    {
      for subnet_key in keys(coalesce(var.vpcs[keys(var.vpcs)[0]].subnets, {})) : subnet_key => (
        aws_subnet.this["${keys(var.vpcs)[0]}-${subnet_key}"].cidr_block
      )
    }
  ) : {}
}

output "route_table_ids" {
  description = "Map of route table IDs from the first VPC, keyed by route table key (legacy output for backward compatibility). Use route_table_ids[\"vpc_key\"][\"rt_key\"] for multiple VPCs. ⚠️ Warning: This only returns route tables from the first VPC. If you have multiple VPCs, use the nested route_table_ids map instead."
  value = length(aws_vpc.this) > 0 ? (
    {
      for rt_key in keys(coalesce(var.vpcs[keys(var.vpcs)[0]].route_tables, {})) : rt_key => (
        aws_route_table.this["${keys(var.vpcs)[0]}-${rt_key}"].id
      )
    }
  ) : {}
}
