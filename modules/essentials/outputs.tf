output "node_termination_handler_sqs_arn" {
  description = "ARN of the SQS queue used to handle node termination events"
  value       = try(module.node_termination_handler_sqs[0].sqs_queue_arn, "")
}
