locals {
  common_tags = merge(var.tags, { ManagedBy = "Terraform" })
}

resource "aws_sqs_queue" "this" {
  for_each = var.queues

  name = each.value.name

  delay_seconds              = each.value.delay_seconds
  max_message_size           = each.value.max_message_size
  message_retention_seconds  = each.value.message_retention_seconds
  receive_wait_time_seconds  = each.value.receive_wait_time_seconds
  visibility_timeout_seconds = each.value.visibility_timeout_seconds

  fifo_queue = each.value.fifo_queue

  policy = each.value.policy
  redrive_policy = each.value.redrive_policy
  redrive_allow_policy = each.value.redrive_allow_policy

  kms_master_key_id                 = each.value.kms_master_key_id
  kms_data_key_reuse_period_seconds = each.value.kms_data_key_reuse_period_seconds
  sqs_managed_sse_enabled          = each.value.sqs_managed_sse_enabled

  tags = merge(local.common_tags, lookup(var.queue_tags, each.key, {}))
}
