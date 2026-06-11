locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )
}

# VPCs
resource "aws_vpc" "this" {
  for_each = var.vpcs

  cidr_block           = each.value.vpc_cidr
  instance_tenancy     = each.value.instance_tenancy
  enable_dns_support   = each.value.enable_dns_support
  enable_dns_hostnames = each.value.enable_dns_hostnames

  tags = merge(
    local.common_tags,
    {
      Name = each.value.vpc_name != "" ? each.value.vpc_name : "VPC-${each.key}"
    }
  )
}

# Internet Gateways (one per VPC)
resource "aws_internet_gateway" "this" {
  for_each = {
    for vpc_key, vpc in var.vpcs : vpc_key => vpc
    if vpc.create_internet_gateway
  }

  vpc_id = aws_vpc.this[each.key].id

  tags = merge(
    local.common_tags,
    {
      Name = each.value.igw_name != "" ? each.value.igw_name : "IGW-${each.key}"
    }
  )
}

# Elastic IPs for NAT Gateways (one per VPC)
resource "aws_eip" "nat" {
  for_each = {
    for vpc_key, vpc in var.vpcs : vpc_key => vpc
    if vpc.create_nat_gateway
  }

  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]

  tags = merge(
    local.common_tags,
    {
      Name = "${each.value.nat_gateway_name != "" ? each.value.nat_gateway_name : "NAT Gateway-${each.key}"} EIP"
    }
  )
}

# NAT Gateways (one per VPC)
resource "aws_nat_gateway" "this" {
  for_each = {
    for vpc_key, vpc in var.vpcs : vpc_key => vpc
    if vpc.create_nat_gateway
  }

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.nat_gateway_subnet_key != "" ? aws_subnet.this["${each.key}-${each.value.nat_gateway_subnet_key}"].id : each.value.nat_gateway_subnet_id
  depends_on    = [aws_internet_gateway.this]

  tags = merge(
    local.common_tags,
    {
      Name = each.value.nat_gateway_name != "" ? each.value.nat_gateway_name : "NAT Gateway-${each.key}"
    }
  )
}

# Subnets (scoped to each VPC)
resource "aws_subnet" "this" {
  for_each = {
    for pair in flatten([
      for vpc_key, vpc in var.vpcs : [
        for subnet_key, subnet in coalesce(vpc.subnets, {}) : {
          key         = "${vpc_key}-${subnet_key}"
          vpc_key     = vpc_key
          subnet_key  = subnet_key
          subnet      = subnet
          subnet_tags = lookup(coalesce(vpc.subnet_tags, {}), subnet_key, {})
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id                  = aws_vpc.this[each.value.vpc_key].id
  cidr_block              = each.value.subnet.cidr_block
  availability_zone       = each.value.subnet.availability_zone
  map_public_ip_on_launch = each.value.subnet.map_public_ip_on_launch
  assign_ipv6_address_on_creation = each.value.subnet.assign_ipv6_address_on_creation
  ipv6_cidr_block         = each.value.subnet.ipv6_cidr_block

  tags = merge(
    local.common_tags,
    {
      Name = each.value.subnet_key
    },
    each.value.subnet_tags
  )
}

# Route Tables (scoped to each VPC)
resource "aws_route_table" "this" {
  for_each = {
    for pair in flatten([
      for vpc_key, vpc in var.vpcs : [
        for rt_key, rt in coalesce(vpc.route_tables, {}) : {
          key              = "${vpc_key}-${rt_key}"
          vpc_key          = vpc_key
          rt_key           = rt_key
          route_table_tags = lookup(coalesce(vpc.route_table_tags, {}), rt_key, {})
        }
      ]
    ]) : pair.key => pair
  }

  vpc_id = aws_vpc.this[each.value.vpc_key].id

  tags = merge(
    local.common_tags,
    {
      Name = each.value.rt_key
    },
    each.value.route_table_tags
  )
}

# IPv4 Routes
resource "aws_route" "ipv4" {
  for_each = {
    for route in flatten([
      for vpc_key, vpc in var.vpcs : [
        for rt_key, rt in coalesce(vpc.route_tables, {}) : [
          for route_idx, route in coalesce(rt.routes, []) : {
            key      = "${vpc_key}-${rt_key}-route-${route_idx}-ipv4"
            vpc_key  = vpc_key
            rt_key   = rt_key
            config   = route
          }
        ]
      ]
    ]) : route.key => route
    if route.config.cidr_block != null
  }

  route_table_id = aws_route_table.this["${each.value.vpc_key}-${each.value.rt_key}"].id

  destination_cidr_block     = each.value.config.cidr_block
  gateway_id                 = each.value.config.use_internet_gateway && var.vpcs[each.value.vpc_key].create_internet_gateway ? aws_internet_gateway.this[each.value.vpc_key].id : each.value.config.gateway_id
  nat_gateway_id             = each.value.config.use_nat_gateway && var.vpcs[each.value.vpc_key].create_nat_gateway ? aws_nat_gateway.this[each.value.vpc_key].id : each.value.config.nat_gateway_id
  transit_gateway_id         = each.value.config.transit_gateway_id
  vpc_endpoint_id            = each.value.config.vpc_endpoint_id
  network_interface_id       = each.value.config.network_interface_id
  destination_prefix_list_id = each.value.config.destination_prefix_list_id
  carrier_gateway_id         = each.value.config.carrier_gateway_id
  local_gateway_id           = each.value.config.local_gateway_id
  vpc_peering_connection_id  = each.value.config.vpc_peering_connection_id
}

# IPv6 Routes
resource "aws_route" "ipv6" {
  for_each = {
    for route in flatten([
      for vpc_key, vpc in var.vpcs : [
        for rt_key, rt in coalesce(vpc.route_tables, {}) : [
          for route_idx, route in coalesce(rt.routes, []) : {
            key     = "${vpc_key}-${rt_key}-route-${route_idx}-ipv6"
            vpc_key = vpc_key
            rt_key  = rt_key
            config  = route
          }
        ]
      ]
    ]) : route.key => route
    if route.config.ipv6_cidr_block != null
  }

  route_table_id = aws_route_table.this["${each.value.vpc_key}-${each.value.rt_key}"].id

  destination_ipv6_cidr_block = each.value.config.ipv6_cidr_block
  egress_only_gateway_id     = each.value.config.egress_only_gateway_id
  transit_gateway_id         = each.value.config.transit_gateway_id
  vpc_endpoint_id            = each.value.config.vpc_endpoint_id
  network_interface_id        = each.value.config.network_interface_id
  carrier_gateway_id         = each.value.config.carrier_gateway_id
  local_gateway_id           = each.value.config.local_gateway_id
  vpc_peering_connection_id   = each.value.config.vpc_peering_connection_id
}

# Route Table Associations
resource "aws_route_table_association" "this" {
  for_each = {
    for assoc in flatten([
      for vpc_key, vpc in var.vpcs : [
        for rt_key, rt in coalesce(vpc.route_tables, {}) : [
          for subnet_key in coalesce(rt.subnet_associations, []) : {
            key      = "${vpc_key}-${rt_key}-${subnet_key}"
            vpc_key  = vpc_key
            rt_key   = rt_key
            subnet_key = subnet_key
          }
        ]
      ]
    ]) : assoc.key => assoc
  }

  subnet_id      = aws_subnet.this["${each.value.vpc_key}-${each.value.subnet_key}"].id
  route_table_id = aws_route_table.this["${each.value.vpc_key}-${each.value.rt_key}"].id
}
