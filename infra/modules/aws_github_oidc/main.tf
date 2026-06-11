locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })

  provider_hosts = {
    for k, v in var.oidc_providers : k => trimprefix(v.url, "https://")
  }
}

resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(local.common_tags, lookup(var.provider_tags, each.key, {}))
}

resource "aws_iam_role" "this" {
  for_each = var.roles

  name = each.value.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.this[each.value.provider_key].arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${local.provider_hosts[each.value.provider_key]}:sub" = each.value.subject
        }
        StringEquals = {
          "${local.provider_hosts[each.value.provider_key]}:aud" = each.value.audience
        }
      }
    }]
  })

  tags = merge(local.common_tags, lookup(var.role_tags, each.key, {}))
}

resource "aws_iam_role_policy" "inline" {
  for_each = {
    for k, v in var.roles : k => v
    if v.inline_policy != null
  }

  name   = "${each.value.role_name}-policy"
  role   = aws_iam_role.this[each.key].id
  policy = each.value.inline_policy
}
