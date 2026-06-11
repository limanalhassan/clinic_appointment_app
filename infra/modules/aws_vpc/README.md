# VPC Module

Manages multiple VPCs with subnets, route tables, IGW, and optional NAT Gateway. Key-based; legacy outputs for single VPC.

## Usage

```hcl
module "vpc" {
  source = "../../../modules/aws_vpc"

  vpcs = {
    main = {
      vpc_cidr = "10.0.0.0/16"
      
      subnets = {
        public1 = {
          cidr_block        = "10.0.1.0/24"
          availability_zone = "us-east-1a"
          map_public_ip_on_launch = true
        }
        public2 = {
          cidr_block        = "10.0.2.0/24"
          availability_zone = "us-east-1b"
          map_public_ip_on_launch = true
        }
      }
    }
  }

  tags = {
    Environment = "prod"
  }
}
```

### JSON Configuration Example

```json
{
  "vpcs": {
    "main": {
      "vpc_cidr": "10.0.0.0/16",
      "vpc_name": "Main VPC",
      "create_internet_gateway": true,
      "create_nat_gateway": true,
      "nat_gateway_subnet_key": "public1",
      "subnets": {
        "public1": {
          "cidr_block": "10.0.1.0/24",
          "availability_zone": "us-east-1a",
          "map_public_ip_on_launch": true
        },
        "private1": {
          "cidr_block": "10.0.10.0/24",
          "availability_zone": "us-east-1a"
        }
      },
      "route_tables": {
        "public": {
          "routes": [{
            "cidr_block": "0.0.0.0/0",
            "use_internet_gateway": true
          }],
          "subnet_associations": ["public1"]
        }
      }
    }
  }
}
```

## Inputs

### Required Variables

| Name | Type | Description |
|------|------|-------------|
| `vpcs` | `map(object)` | Map of VPCs to create. Each key is a unique VPC identifier. See VPC Object Structure below. |

### Optional Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Common tags to apply to all VPC resources |

### VPC Object Structure

Each VPC in the `vpcs` map has the following structure:

```hcl
{
  vpc_cidr                = string              # Required: CIDR block for the VPC
  enable_dns_support      = optional(bool, true)
  enable_dns_hostnames    = optional(bool, true)
  instance_tenancy         = optional(string, "default")
  create_internet_gateway = optional(bool, true)
  create_nat_gateway      = optional(bool, false)
  nat_gateway_subnet_id   = optional(string, "")      # External subnet ID
  nat_gateway_subnet_key  = optional(string, "")      # Subnet key from this VPC's subnets
  vpc_name                = optional(string, "")
  igw_name                = optional(string, "")
  nat_gateway_name        = optional(string, "")
  subnets                 = optional(map(object), {})  # See Subnet Object Structure
  route_tables            = optional(map(object), {})  # See Route Table Object Structure
  subnet_tags             = optional(map(map(string)), {})
  route_table_tags        = optional(map(map(string)), {})
}
```

### Subnet Object Structure

```hcl
{
  cidr_block                      = string              # Required
  availability_zone              = optional(string)
  map_public_ip_on_launch         = optional(bool, false)
  assign_ipv6_address_on_creation = optional(bool, false)
  ipv6_cidr_block                = optional(string)
}
```

### Route Table Object Structure

```hcl
{
  routes = optional(list(object({
    cidr_block                = optional(string)
    ipv6_cidr_block          = optional(string)
    gateway_id                = optional(string)
    nat_gateway_id            = optional(string)
    use_internet_gateway      = optional(bool, false)  # Auto-use IGW from this VPC
    use_nat_gateway           = optional(bool, false)  # Auto-use NAT Gateway from this VPC
    egress_only_gateway_id    = optional(string)
    transit_gateway_id        = optional(string)
    vpc_endpoint_id           = optional(string)
    network_interface_id      = optional(string)
    destination_prefix_list_id = optional(string)
    carrier_gateway_id        = optional(string)
    local_gateway_id          = optional(string)
    vpc_peering_connection_id = optional(string)
  })), [])
  subnet_associations = optional(list(string), [])  # List of subnet keys to associate
}
```

## Outputs

### Multiple VPC Outputs (Recommended)

| Name | Type | Description |
|------|------|-------------|
| `vpc_ids` | `map(string)` | Map of VPC IDs, keyed by VPC key |
| `vpc_cidr_blocks` | `map(string)` | Map of VPC CIDR blocks, keyed by VPC key |
| `vpc_arns` | `map(string)` | Map of VPC ARNs, keyed by VPC key |
| `internet_gateway_ids` | `map(string)` | Map of IGW IDs, keyed by VPC key (null if not created) |
| `nat_gateway_ids` | `map(string)` | Map of NAT Gateway IDs, keyed by VPC key (null if not created) |
| `nat_gateway_public_ips` | `map(string)` | Map of NAT Gateway public IPs, keyed by VPC key (null if not created) |
| `subnet_ids_nested` | `map(map(string))` | Nested map: VPC key -> subnet key -> subnet ID |
| `subnet_cidrs_nested` | `map(map(string))` | Nested map: VPC key -> subnet key -> subnet CIDR |
| `route_table_ids_nested` | `map(map(string))` | Nested map: VPC key -> route table key -> route table ID |
| `default_security_group_ids` | `map(string)` | Map of default security group IDs, keyed by VPC key |

### Legacy Outputs (Backward Compatibility)

For single VPC use cases, these outputs return the first VPC's values:

| Name | Type | Description |
|------|------|-------------|
| `vpc_id` | `string` | ID of the first VPC (null if multiple VPCs) |
| `vpc_cidr_block` | `string` | CIDR block of the first VPC (null if multiple VPCs) |
| `vpc_arn` | `string` | ARN of the first VPC (null if multiple VPCs) |
| `internet_gateway_id` | `string` | IGW ID of the first VPC (null if multiple VPCs or not created) |
| `nat_gateway_id` | `string` | NAT Gateway ID of the first VPC (null if multiple VPCs or not created) |
| `nat_gateway_public_ip` | `string` | NAT Gateway public IP of the first VPC (null if multiple VPCs or not created) |
| `subnet_ids` | `map(string)` | **⚠️ First VPC only** - Map of subnet IDs from the first VPC, keyed by subnet key |
| `subnet_cidrs` | `map(string)` | **⚠️ First VPC only** - Map of subnet CIDRs from the first VPC, keyed by subnet key |
| `route_table_ids` | `map(string)` | **⚠️ First VPC only** - Map of route table IDs from the first VPC, keyed by route table key |
| `default_security_group_id` | `string` | Default security group ID of the first VPC (null if multiple VPCs) |

### Output Usage Examples

```hcl
# Multiple VPCs - use nested outputs
module "vpc" {
  source = "../../../modules/aws_vpc"
  vpcs   = { ... }
}

# Access specific VPC
output "main_vpc_id" {
  value = module.vpc.vpc_ids["main"]
}

# Access subnets from specific VPC
output "main_public_subnet" {
  value = module.vpc.subnet_ids_nested["main"]["public1"]
}

# Single VPC - legacy outputs work
module "vpc" {
  source = "../../../modules/aws_vpc"
  vpcs = {
    main = { ... }
  }
}

# Legacy outputs work for single VPC
output "vpc_id" {
  value = module.vpc.vpc_id  # Returns main VPC's ID
}

output "subnet_ids" {
  value = module.vpc.subnet_ids  # Returns main VPC's subnets
}
```

## Notes

- **VPC Isolation**: Each VPC in the map is completely independent with its own subnets, route tables, and gateways
- **Subnet Keys**: Subnet keys are scoped to each VPC - you can use the same subnet key in different VPCs
- **Route Table Associations**: Route table `subnet_associations` reference subnet keys from the same VPC
- **Auto-Reference Gateways**: Use `use_internet_gateway = true` or `use_nat_gateway = true` in routes to automatically reference the IGW/NAT Gateway created by this module for that VPC
- **External Resources**: Routes can also reference external gateway/NAT IDs directly using `gateway_id` or `nat_gateway_id`
- **NAT Gateway Subnet**: NAT Gateway can reference a subnet from the same VPC using `nat_gateway_subnet_key`, or an external subnet using `nat_gateway_subnet_id`
- **IPv4 and IPv6**: IPv4 and IPv6 routes are created separately (one route resource per destination type)
- **Legacy Outputs**: Legacy outputs (`subnet_ids`, `route_table_ids`, etc.) only return values from the first VPC. For multiple VPCs, use the nested outputs (`subnet_ids_nested`, etc.)
- **Backward Compatibility**: Existing code using `module.vpc.vpc_id` and `module.vpc.subnet_ids` will continue to work for single VPC configurations
