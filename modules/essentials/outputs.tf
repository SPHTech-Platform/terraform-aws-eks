output "node_termination_handler_sqs_arn" {
  description = "ARN of the SQS queue used to handle node termination events"
  value       = try(module.node_termination_handler_sqs[0].queue_arn, "")
}

output "fluent_bit_irsa_id" {
  description = "ID of the IAM Policy used by the Fluent Bit IAM Role for Service Account"
  value       = try(aws_iam_policy.fluent_bit_irsa[0].policy_id, "")
}

output "fluent_bit_s3_bucket_id" {
  description = "Name of S3 bucket used to store Fluentbit logs"
  value       = try(module.fluentbit_s3_bucket.s3_bucket_id, "")
}

output "fluent_bit_s3_bucket_arn" {
  description = "ARN of S3 bucket used to store Fluentbit logs"
  value       = try(module.fluentbit_s3_bucket.s3_bucket_arn, "")
}
