locals {
  effective_username = {
    for k, v in var.databases : k => coalesce(lookup(v, "master_username", null), v.db_name)
  }
}

resource "random_password" "this" {
  for_each = var.databases

  length           = 24
  special          = true
  override_special = "!#$%&*-_=+?"
}

resource "aws_secretsmanager_secret" "credentials" {
  for_each = var.databases

  name                    = each.value.credentials_secret_name
  recovery_window_in_days = 0

  tags = merge(var.tags, lookup(var.database_tags, each.key, {}))
}

resource "aws_db_subnet_group" "this" {
  for_each = { for k, v in var.databases : k => v if v.create_db_subnet_group }

  name        = each.value.identifier
  description = each.value.db_subnet_group_description
  subnet_ids  = [for key in each.value.subnet_keys : var.vpc_subnet_ids[key]]

  tags = merge(var.tags, lookup(var.database_tags, each.key, {}))
}

resource "aws_db_parameter_group" "this" {
  for_each = { for k, v in var.databases : k => v if v.create_parameter_group }

  name        = each.value.identifier
  family      = each.value.parameter_group_family
  description = each.value.parameter_group_description != "" ? each.value.parameter_group_description : "Parameter group for ${each.value.identifier}"

  tags = merge(var.tags, lookup(var.database_tags, each.key, {}))
}

resource "aws_db_instance" "this" {
  for_each = var.databases

  identifier            = each.value.identifier
  engine                = each.value.engine
  engine_version        = each.value.engine_version
  instance_class        = each.value.instance_class
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = each.value.max_allocated_storage
  storage_type          = each.value.storage_type

  db_name  = each.value.db_name
  username = local.effective_username[each.key]
  password = random_password.this[each.key].result
  port     = each.value.port

  db_subnet_group_name   = each.value.create_db_subnet_group ? aws_db_subnet_group.this[each.key].name : null
  vpc_security_group_ids = [for key in each.value.vpc_security_group_keys : var.vpc_security_group_ids[key]]

  backup_retention_period         = each.value.backup_retention_period
  multi_az                        = each.value.multi_az
  publicly_accessible             = each.value.publicly_accessible
  deletion_protection             = each.value.deletion_protection
  skip_final_snapshot             = each.value.skip_final_snapshot
  copy_tags_to_snapshot           = each.value.copy_tags_to_snapshot
  performance_insights_enabled    = each.value.enable_performance_insights
  enabled_cloudwatch_logs_exports = each.value.enable_cloudwatch_logs_exports
  parameter_group_name            = each.value.create_parameter_group ? aws_db_parameter_group.this[each.key].name : null

  tags = merge(var.tags, lookup(var.database_tags, each.key, {}))
}

resource "aws_secretsmanager_secret_version" "credentials" {
  for_each = var.databases

  secret_id = aws_secretsmanager_secret.credentials[each.key].id
  secret_string = jsonencode({
    username = local.effective_username[each.key]
    password = random_password.this[each.key].result
    host     = aws_db_instance.this[each.key].address
    port     = each.value.port
    dbname   = each.value.db_name
  })
}
