data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_arn" "node_termination_handler_sqs" {
  count = var.node_termination_handler_enable ? 1 : 0

  arn = try(module.node_termination_handler_sqs[0].queue_arn, var.node_termination_handler_sqs_arn)
}

data "aws_sqs_queue" "node_termination_handler" {
  count = var.node_termination_handler_enable ? 1 : 0

  name = data.aws_arn.node_termination_handler_sqs[0].resource
}

data "aws_iam_policy_document" "fluent_bit" {
  statement {
    sid       = "PutLogEvents"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"]
    actions   = ["logs:PutLogEvents"]
  }

  statement {
    sid       = "CreateCWLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy",
    ]
  }
}

data "aws_iam_policy_document" "fluent_bit_cw_and_s3" {

  for_each = var.fluent_bit_enable_s3_output ? { "enabled" = 1 } : {}

  statement {
    sid       = "PutLogEvents"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"]
    actions   = ["logs:PutLogEvents"]
  }

  statement {
    sid       = "CreateCWLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutRetentionPolicy",
    ]
  }
  statement {
    sid       = "S3"
    effect    = "Allow"
    resources = ["${module.fluentbit_s3_bucket[0].s3_bucket_arn}/*"]
    actions   = ["s3:PutObject"]
  }
}
