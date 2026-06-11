locals {
  common_tags = var.tags

  # Resolve Route53 hosted zone IDs for DNS validation
  resolved_hosted_zone_ids = {
    for cert_key, cert in var.certificates : cert_key => (
      cert.route53_hosted_zone_key != null && contains(keys(var.vpc_route53_hosted_zone_ids), cert.route53_hosted_zone_key) ?
        var.vpc_route53_hosted_zone_ids[cert.route53_hosted_zone_key] : null
    )
  }
}

# ACM Certificate
resource "aws_acm_certificate" "this" {
  for_each = var.certificates

  domain_name               = each.value.domain_name
  subject_alternative_names = length(each.value.subject_alternative_names) > 0 ? each.value.subject_alternative_names : []
  validation_method         = each.value.validation_method

  # Validation options (for custom validation domains)
  dynamic "validation_option" {
    for_each = each.value.validation_option
    content {
      domain_name       = validation_option.value.domain_name
      validation_domain  = validation_option.value.validation_domain
    }
  }

  # Lifecycle: Prevent recreation on validation changes
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    lookup(var.certificate_tags, each.key, {})
  )
}

# DNS Validation Records (automatic if Route53 hosted zone is provided)
resource "aws_acm_certificate_validation" "this" {
  for_each = {
    for cert_key, cert in var.certificates : cert_key => cert
    if cert.validation_method == "DNS" && local.resolved_hosted_zone_ids[cert_key] != null
  }

  certificate_arn = aws_acm_certificate.this[each.key].arn

  # Wait for DNS validation records to be created
  depends_on = [aws_route53_record.certificate_validation]
}

# Route53 DNS Validation Records (automatic DNS validation)
# Create records for all domains (primary + SANs)
resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for pair in flatten([
      for cert_key, cert in var.certificates : [
        for dvo in aws_acm_certificate.this[cert_key].domain_validation_options : {
          key           = "${cert_key}-${dvo.domain_name}"
          cert_key      = cert_key
          domain_name   = dvo.domain_name
          record_name   = dvo.resource_record_name
          record_type   = dvo.resource_record_type
          record_value  = dvo.resource_record_value
          hosted_zone_id = local.resolved_hosted_zone_ids[cert_key]
        }
      ] if cert.validation_method == "DNS" && local.resolved_hosted_zone_ids[cert_key] != null
    ]) : pair.key => pair
  }

  zone_id = each.value.hosted_zone_id
  name    = each.value.record_name
  type    = each.value.record_type
  records = [each.value.record_value]
  ttl     = 60

  allow_overwrite = true
}

