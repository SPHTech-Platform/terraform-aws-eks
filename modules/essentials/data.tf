data "aws_caller_identity" "current" {
}

data "aws_region" "current" {
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_subnets" "this" {
  filter {
    name   = "vpc-id"
    values = [data.aws_eks_cluster.this.vpc_config[0].vpc_id]
  }
  filter {
    name   = "tag:type"
    values = ["private"]
  }
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
  dynamic "statement" {
    for_each = var.fluent_bit_enable_s3_output ? [1] : []
    content {
      sid       = "S3"
      effect    = "Allow"
      resources = ["${module.fluentbit_s3_bucket[0].s3_bucket_arn}/*"]
      actions   = ["s3:PutObject"]
    }
  }
  dynamic "statement" {
    for_each = var.fluent_bit_enable_cw_output ? [1] : []
    content {
      sid       = "PutLogEvents"
      effect    = "Allow"
      resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"]
      actions   = ["logs:PutLogEvents"]
    }
  }
  dynamic "statement" {
    for_each = var.fluent_bit_enable_cw_output ? [1] : []
    content {
      sid       = "CreateCWLogs"
      effect    = "Allow"
      resources = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"]
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutRetentionPolicy",
      ]
    }
  }
}
