# AWS SQS Module

Creates SQS queues from a keyed map. Follows the same pattern as other aws_* modules: config-driven, `for_each` over a map.

## Usage

```hcl
module "sqs" {
  source = "../../modules/aws_sqs"

  queues = {
    default = {
      name                       = "my-queue"
      visibility_timeout_seconds = 60
      message_retention_seconds = 1209600 # 14 days
    }
    fifo = {
      name      = "my-queue.fifo"
      fifo_queue = true
    }
  }
  tags = local.config.tags
}
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `queues` | Map of queues to create | `map(object)` | `{}` |
| `tags` | Common tags | `map(string)` | `{}` |
| `queue_tags` | Queue-specific tags, keyed by queue key | `map(map(string))` | `{}` |
| `client` | Client name | `string` | `""` |
| `env` | Environment name | `string` | `""` |

## Outputs

| Name | Description |
|------|-------------|
| `queue_urls` | Map of queue URLs, keyed by queue key |
| `queue_arns` | Map of queue ARNs, keyed by queue key |
| `queue_names` | Map of queue names, keyed by queue key |
