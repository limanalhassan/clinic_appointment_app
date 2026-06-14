locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

# SES Domain Identity
resource "aws_ses_domain_identity" "this" {
  for_each = var.domain_identities

  domain = each.value.name
}

# SES Email Identity
resource "aws_ses_email_identity" "this" {
  for_each = var.email_identities

  email = each.value.name
}

# Configuration sets
resource "aws_ses_configuration_set" "this" {
  for_each = var.configuration_sets

  name                       = each.value.name
  reputation_metrics_enabled = each.value.reputation_metrics_enabled
  sending_enabled            = each.value.sending_enabled
}
