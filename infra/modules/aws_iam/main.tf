locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
    }
  )

  # Process roles to read files from assume-role and policies folders
  # Supports both file references (*_file) and direct JSON strings
  processed_roles = {
    for role_key, role in var.roles : role_key => {
      name        = role.name
      description = role.description
      assume_role_policy = try(
        file("${path.module}/assume-role/${role.assume_role_policy_file}"),
        try(role.assume_role_policy, null)
      )
      id                      = role.id
      create_instance_profile = role.create_instance_profile
      inline_policies = {
        for policy_key, policy in coalesce(role.inline_policies, {}) : policy_key => {
          name = policy.name
          policy = try(
            var.env != "" ? templatefile("${path.module}/policies/${policy.policy_file}", { env = var.env }) : file("${path.module}/policies/${policy.policy_file}"),
            try(policy.policy, null)
          )
        }
      }
      managed_policy_arns = role.managed_policy_arns
      tags                = role.tags
    }
  }
}

# Data source for existing roles (when id is provided)
data "aws_iam_role" "existing" {
  for_each = {
    for key, role in local.processed_roles : key => role
    if role.id != null
  }

  name = each.value.id
}

# Create new IAM roles (when id is not provided)
resource "aws_iam_role" "this" {
  for_each = {
    for key, role in local.processed_roles : key => role
    if role.id == null
  }

  name                 = each.value.name
  description          = each.value.description
  assume_role_policy   = each.value.assume_role_policy
  path                 = "/"
  max_session_duration = 3600

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name = each.value.name
    }
  )
}

# Local to combine created and imported roles
locals {
  roles_combined = {
    for key, role in local.processed_roles : key => {
      id   = role.id != null ? data.aws_iam_role.existing[key].id : aws_iam_role.this[key].id
      name = role.name
      arn  = role.id != null ? data.aws_iam_role.existing[key].arn : aws_iam_role.this[key].arn
    }
  }
}

# Create inline policies for roles
resource "aws_iam_role_policy" "inline" {
  for_each = {
    for policy_key, policy in flatten([
      for role_key, role in local.processed_roles : [
        for inline_key, inline_policy in coalesce(role.inline_policies, {}) : {
          key         = "${role_key}-${inline_key}"
          role_key    = role_key
          policy_name = inline_policy.name
          policy      = inline_policy.policy
        }
      ]
    ]) : policy_key => policy
  }

  name   = each.value.policy_name
  role   = local.roles_combined[each.value.role_key].id
  policy = each.value.policy
}

# Attach managed policies to roles
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for attachment_key, attachment in flatten([
      for role_key, role in local.processed_roles : [
        for policy_index, policy_arn in coalesce(role.managed_policy_arns, []) : {
          key        = "${role_key}-${policy_index}"
          role_key   = role_key
          policy_arn = policy_arn
        }
      ]
    ]) : attachment_key => attachment
  }

  role       = local.roles_combined[each.value.role_key].id
  policy_arn = each.value.policy_arn
}

# Create instance profiles (when create_instance_profile = true)
resource "aws_iam_instance_profile" "this" {
  for_each = {
    for key, role in local.processed_roles : key => role
    if role.create_instance_profile == true && role.id == null
  }

  name = each.value.name
  role = local.roles_combined[each.key].name

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name = "${each.value.name}-InstanceProfile"
    }
  )
}

# Data source for existing instance profiles (when role is imported and create_instance_profile = true)
# Note: This assumes the instance profile exists. If it doesn't, you'll need to create it separately.
data "aws_iam_instance_profile" "existing" {
  for_each = {
    for key, role in local.processed_roles : key => role
    if role.create_instance_profile == true && role.id != null
  }

  name = each.value.name
}

