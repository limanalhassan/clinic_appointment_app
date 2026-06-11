locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

data "aws_iam_policy_document" "trust" {
  for_each = var.associations

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  for_each = var.associations

  name               = each.value.role_name
  assume_role_policy = data.aws_iam_policy_document.trust[each.key].json

  tags = merge(local.common_tags, lookup(var.association_tags, each.key, {}))
}

resource "aws_iam_role_policy" "inline" {
  for_each = {
    for k, v in var.associations : k => v
    if v.inline_policy != null
  }

  name   = "${each.value.role_name}-policy"
  role   = aws_iam_role.this[each.key].id
  policy = each.value.inline_policy
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for pair in flatten([
      for k, v in var.associations : [
        for arn in coalesce(v.policy_arns, []) : {
          key        = "${k}__${replace(arn, ":", "_")}"
          role_key   = k
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_eks_pod_identity_association" "this" {
  for_each = var.associations

  cluster_name    = var.cluster_name
  namespace       = each.value.namespace
  service_account = each.value.service_account
  role_arn        = aws_iam_role.this[each.key].arn

  tags = merge(local.common_tags, lookup(var.association_tags, each.key, {}))
}
