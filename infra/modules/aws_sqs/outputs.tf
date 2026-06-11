output "queue_urls" {
  description = "Map of SQS queue URLs, keyed by queue key"
  value       = { for k, v in aws_sqs_queue.this : k => v.url }
}

output "queue_arns" {
  description = "Map of SQS queue ARNs, keyed by queue key"
  value       = { for k, v in aws_sqs_queue.this : k => v.arn }
}

output "queue_names" {
  description = "Map of SQS queue names, keyed by queue key"
  value       = { for k, v in aws_sqs_queue.this : k => v.name }
}
