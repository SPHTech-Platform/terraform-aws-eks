data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_arn" "node_termination_handler_sqs" {
  count = var.node_termination_handler_enable ? 1 : 0

  arn = try(module.node_termination_handler_sqs[0].sqs_queue_arn, var.node_termination_handler_sqs_arn)
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
    sid       = "AssumeFirehoseRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [var.firehose_role_arn]
  }

  statement {
    sid       = "CreateCWLogs"
    effect    = "Allow"
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"]

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
  }
}
