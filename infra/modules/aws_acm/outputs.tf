output "certificate_arns" {
  description = "Map of ACM certificate ARNs, keyed by certificate key"
  value = {
    for cert_key, cert in aws_acm_certificate.this : cert_key => cert.arn
  }
}

output "certificate_arns_by_domain" {
  description = "Map of ACM certificate ARNs, keyed by primary domain name"
  value = {
    for cert_key, cert in aws_acm_certificate.this : cert.domain_name => cert.arn
  }
}

output "certificate_ids" {
  description = "Map of ACM certificate IDs, keyed by certificate key"
  value = {
    for cert_key, cert in aws_acm_certificate.this : cert_key => cert.id
  }
}

output "validated_certificate_arns" {
  description = "Map of validated ACM certificate ARNs (only for certificates with automatic DNS validation), keyed by certificate key"
  value = {
    for cert_key, cert in aws_acm_certificate_validation.this : cert_key => cert.certificate_arn
  }
}

output "domain_validation_options" {
  description = "Map of domain validation options for each certificate, keyed by certificate key"
  value = {
    for cert_key, cert in aws_acm_certificate.this : cert_key => cert.domain_validation_options
  }
}

