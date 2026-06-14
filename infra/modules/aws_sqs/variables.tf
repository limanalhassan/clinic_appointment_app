variable "queues" {
  description = "Map of SQS queues to create. Each key is a unique identifier, value contains queue configuration."
  type = map(object({
    name = string

    delay_seconds              = optional(number, 0)
    max_message_size           = optional(number, 262144) # 256 KiB
    message_retention_seconds  = optional(number, 345600) # 4 days
    receive_wait_time_seconds  = optional(number, 0)      # Short polling; 1-20 for long polling
    visibility_timeout_seconds = optional(number, 30)

    # FIFO
    fifo_queue = optional(bool, false) # If true, name must end with .fifo

    # Policy (optional JSON string or map)
    policy = optional(string)

    # Redrive
    redrive_policy       = optional(string) # JSON: {"deadLetterTargetArn":"...", "maxReceiveCount":"5"}
    redrive_allow_policy = optional(string)

    # KMS
    kms_master_key_id                 = optional(string)
    kms_data_key_reuse_period_seconds = optional(number)

    # Server-side encryption
    sqs_managed_sse_enabled = optional(bool, true)
  }))
  default = {}
}

variable "tags" {
  description = "Common tags to apply to all queues"
  type        = map(string)
  default     = {}
}

variable "queue_tags" {
  description = "Map of queue-specific tags, keyed by queue key"
  type        = map(map(string))
  default     = {}
}

variable "client" {
  description = "Client name for naming conventions"
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name for naming conventions"
  type        = string
  default     = ""
}
