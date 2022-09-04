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
  count = var.node_termination_handler_sqs_arn != null ? 1 : 0

  arn = var.node_termination_handler_sqs_arn
}

data "aws_sqs_queue" "node_termination_handler" {
  count = var.node_termination_handler_sqs_arn != null ? 1 : 0

  name = data.aws_arn.node_termination_handler_sqs[0].resource
}
