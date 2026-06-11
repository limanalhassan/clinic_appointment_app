# ACM Module

Manages ACM certificates with DNS and email validation. Supports automatic DNS validation using Route53 hosted zones via key-based resolution.

## Features

- **Multiple Certificates**: Create multiple ACM certificates using `for_each`
- **DNS Validation**: Automatic DNS validation using Route53 hosted zones (key-based resolution)
- **Email Validation**: Support for email-based validation
- **Subject Alternative Names (SANs)**: Support for multiple domain names per certificate
- **Custom Validation Domains**: Support for custom validation domains
- **Automatic Validation**: Automatic certificate validation when Route53 hosted zone is provided
- **Tags**: Support for common and certificate-specific tags

## Important Notes

1. **Region Requirements**:
   - **CloudFront**: ACM certificates for CloudFront **must** be in `us-east-1` region
   - **Load Balancers**: ACM certificates for ALB/NLB can be in any region (must match the load balancer region)

2. **Validation Methods**:
   - **DNS Validation** (Recommended): Automatic validation using Route53 DNS records
   - **Email Validation**: Manual validation via email sent to domain registrant

3. **DNS Validation**:
   - Requires a Route53 hosted zone for the domain
   - Automatic DNS record creation when `route53_hosted_zone_key` is provided
   - Certificate validation happens automatically after DNS records are created

4. **Email Validation**:
   - AWS sends validation email to domain registrant (WHOIS contacts)
   - Manual approval required - cannot be automated
   - Not recommended for production automation

## Usage

### Basic Example - DNS Validation with Route53

```hcl
module "acm" {
  source = "../../../modules/aws_acm"

  vpc_route53_hosted_zone_ids = module.route53.hosted_zone_ids

  certificates = {
    webapp = {
      domain_name               = "example.com"
      subject_alternative_names = ["www.example.com", "api.example.com"]
      validation_method         = "DNS"
      route53_hosted_zone_key   = "example-com" # Key from Route53 module
    }
  }

  tags = {
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

### Example - Email Validation

```hcl
module "acm" {
  source = "../../../modules/aws_acm"

  certificates = {
    webapp = {
      domain_name       = "example.com"
      validation_method = "EMAIL"
      # AWS will send validation email to domain registrant
    }
  }

  tags = {
    Environment = "prod"
  }
}
```

### Example - CloudFront Certificate (us-east-1)

```hcl
# Note: This module must be in us-east-1 region for CloudFront
module "acm_cloudfront" {
  source = "../../../modules/aws_acm"
  providers = {
    aws = aws.us-east-1 # Use us-east-1 provider
  }

  vpc_route53_hosted_zone_ids = module.route53.hosted_zone_ids

  certificates = {
    webapp = {
      domain_name               = "example.com"
      subject_alternative_names = ["www.example.com"]
      validation_method         = "DNS"
      route53_hosted_zone_key   = "example-com"
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
  "certificates": {
    "webapp": {
      "domain_name": "example.com",
      "subject_alternative_names": ["www.example.com", "api.example.com"],
      "validation_method": "DNS",
      "route53_hosted_zone_key": "example-com"
    },
    "api": {
      "domain_name": "api.example.com",
      "validation_method": "DNS",
      "route53_hosted_zone_key": "api-example-com"
    }
  },
  "certificate_tags": {
    "webapp": {
      "Name": "Production Web App Certificate",
      "Purpose": "CloudFront"
    },
    "api": {
      "Name": "Production API Certificate",
      "Purpose": "ALB"
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `certificates` | Map of ACM certificates to create | `map(object)` | `{}` | No |
| `vpc_route53_hosted_zone_ids` | Map of Route53 hosted zone IDs, keyed by hosted zone key (for DNS validation) | `map(string)` | `{}` | No |
| `tags` | Common tags to apply to all certificates | `map(string)` | `{}` | No |
| `certificate_tags` | Map of certificate-specific tags, keyed by certificate key | `map(map(string))` | `{}` | No |
| `client` | Client name for naming conventions | `string` | `""` | No |
| `env` | Environment name for naming conventions | `string` | `""` | No |

### Certificate Configuration Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `domain_name` | Primary domain name (e.g., example.com) | `string` | - | Yes |
| `subject_alternative_names` | Additional domain names (SANs) | `list(string)` | `[]` | No |
| `validation_method` | Validation method: `DNS` or `EMAIL` | `string` | - | Yes |
| `validation_option` | Custom validation domains | `list(object)` | `[]` | No |
| `route53_hosted_zone_key` | Route53 hosted zone key for automatic DNS validation | `string` | `null` | No |
| `tags` | Certificate-specific tags | `map(string)` | `{}` | No |

### Validation Option Object

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `domain_name` | Domain name to validate (must be in domain_name or subject_alternative_names) | `string` | - | Yes |
| `validation_domain` | Domain to use for validation (e.g., _example.com) | `string` | - | Yes |

## Outputs

| Name | Description |
|------|-------------|
| `certificate_arns` | Map of ACM certificate ARNs, keyed by certificate key |
| `certificate_arns_by_domain` | Map of ACM certificate ARNs, keyed by primary domain name |
| `certificate_ids` | Map of ACM certificate IDs, keyed by certificate key |
| `validated_certificate_arns` | Map of validated ACM certificate ARNs (only for certificates with automatic DNS validation), keyed by certificate key |
| `domain_validation_options` | Map of domain validation options for each certificate, keyed by certificate key |

## Key-Based Resolution

This module supports key-based resolution for Route53 hosted zones, following the same pattern as other modules (EC2, S3, CloudFront, RDS, etc.).

### How It Works

1. **Route53 Hosted Zone Key**: In your certificate configuration, specify `route53_hosted_zone_key` (e.g., `"example-com"`)
2. **Module Input**: Pass `vpc_route53_hosted_zone_ids` from your Route53 module:
   ```hcl
   vpc_route53_hosted_zone_ids = module.route53.hosted_zone_ids
   ```
3. **Automatic Resolution**: The module resolves the key to the actual hosted zone ID
4. **Automatic DNS Validation**: When a hosted zone key is provided, the module automatically:
   - Creates DNS validation records in Route53
   - Waits for validation to complete
   - Returns validated certificate ARN

### Example

```hcl
# Route53 Module
module "route53" {
  source = "../../../modules/route53"
  # ... creates hosted zones with keys: "example-com", "api-example-com"
}

# ACM Module
module "acm" {
  source = "../../../modules/aws_acm"

  vpc_route53_hosted_zone_ids = module.route53.hosted_zone_ids

  certificates = {
    webapp = {
      domain_name             = "example.com"
      validation_method       = "DNS"
      route53_hosted_zone_key = "example-com" # Key-based resolution!
    }
  }
}
```

## Integration Examples

### With CloudFront

```hcl
# ACM Certificate (must be in us-east-1)
module "acm_cloudfront" {
  source = "../../../modules/aws_acm"
  providers = {
    aws = aws.us-east-1
  }

  vpc_route53_hosted_zone_ids = module.route53.hosted_zone_ids

  certificates = {
    webapp = {
      domain_name             = "example.com"
      validation_method       = "DNS"
      route53_hosted_zone_key = "example-com"
    }
  }
}

# CloudFront Distribution
module "cloudfront" {
  source = "../../../modules/aws_cloudfront"

  cloudfront_distributions = {
    webapp = {
      # ... other config ...
      viewer_certificate = {
        acm_certificate_arn = module.acm_cloudfront.certificate_arns["webapp"]
      }
    }
  }
}
```

### With Load Balancers

```hcl
# ACM Certificate (in same region as load balancer)
module "acm" {
  source = "../../../modules/aws_acm"

  vpc_route53_hosted_zone_ids = module.route53.hosted_zone_ids

  certificates = {
    webapp = {
      domain_name             = "example.com"
      validation_method       = "DNS"
      route53_hosted_zone_key = "example-com"
    }
  }
}

# Load Balancer
module "load_balancers" {
  source = "../../../modules/aws_lb"

  load_balancers = {
    web_alb = {
      # ... other config ...
      listeners = [{
        port          = 443
        protocol      = "HTTPS"
        certificate_arn = module.acm.certificate_arns["webapp"]
        default_action = {
          type             = "forward"
          target_group_key = "web-tg"
        }
      }]
    }
  }
}
```

## Best Practices

1. **Use DNS Validation**: DNS validation is recommended for automation and reliability
2. **Region Selection**: 
   - Use `us-east-1` for CloudFront certificates
   - Use the same region as your load balancer for ALB/NLB certificates
3. **Subject Alternative Names**: Include all domain variations (www, api, etc.) in a single certificate to reduce costs
4. **Certificate Renewal**: ACM automatically renews certificates before expiration (no action needed)
5. **Validation Time**: DNS validation typically completes in 5-30 minutes
6. **Email Validation**: Only use for testing or when Route53 is not available
7. **Tags**: Use tags to identify certificate purpose (CloudFront, ALB, etc.)

## Common Issues

1. **Certificate Not Validating**: 
   - Check DNS records are created correctly
   - Verify Route53 hosted zone exists
   - Ensure domain name matches hosted zone domain

2. **CloudFront Certificate Error**: 
   - Ensure certificate is in `us-east-1` region
   - Use provider alias: `providers = { aws = aws.us-east-1 }`

3. **Validation Timeout**: 
   - DNS validation can take up to 30 minutes
   - Check Route53 records are correct
   - Verify hosted zone key is correct

4. **Email Validation**: 
   - Cannot be automated
   - Requires manual approval
   - Not recommended for production

## Consumers (key-based certs)

When used with the **golden_module**, ACM certificate ARNs are passed to these modules so you can reference certs by key from `config_acm.json`:

| Consumer       | Passed as                 | Config field               |
|----------------|---------------------------|----------------------------|
| Load balancers | `vpc_acm_certificate_arns`| Listener: `certificate_key`|
| CloudFront     | `vpc_acm_certificate_arns` | Viewer cert: `acm_certificate_key` |
| API Gateway    | `vpc_acm_certificate_arns` | Custom domain: `certificate_key`   |

Use the same cert key (e.g. `app-cert`) in any of these; omit the key when you don’t need a custom cert.

## Related Modules

- **Route53**: Creates hosted zones for DNS validation
- **CloudFront**: Uses ACM certificates for custom domains (key or ARN)
- **Load Balancers**: Uses ACM certificates for HTTPS/TLS listeners (key or ARN)
- **API Gateway**: Uses ACM certificates for custom domain names (key or ARN)

