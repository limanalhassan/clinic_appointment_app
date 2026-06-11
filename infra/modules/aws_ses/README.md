# AWS SES Module

Creates SES email identities, domain identities, and configuration sets from keyed maps. Follows the same pattern as other aws_* modules: config-driven, `for_each` over a map.

## Usage

```hcl
module "ses" {
  source = "../../modules/aws_ses"

  email_identities = {
    noreply = { name = "noreply@example.com" }
  }
  domain_identities = {
    main = { name = "example.com" }
  }
  configuration_sets = {
    default = { name = "default", sending_enabled = true }
  }
  tags = local.config.tags
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `email_identities` | Map of email addresses to verify | `map(object)` | `{}` |
| `domain_identities` | Map of domains to verify | `map(object)` | `{}` |
| `configuration_sets` | Map of configuration sets to create | `map(object)` | `{}` |
| `tags` | Common tags | `map(string)` | `{}` |
| `client` | Client name | `string` | `""` |
| `env` | Environment name | `string` | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `domain_identity_arns` | Map of domain identity ARNs, keyed by key |
| `domain_identities` | Map of domain names, keyed by key |
| `email_identities` | Map of email addresses, keyed by key |
| `configuration_set_names` | Map of configuration set names, keyed by key |
