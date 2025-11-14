locals {
  node_termination_handler_values = {
    image = var.node_termination_handler_image
    tag   = var.node_termination_handler_tag

    fullname_override = var.node_termination_handler_release_name

    priority_class = var.node_termination_handler_priority_class
    resources      = jsonencode(var.node_termination_handler_resources)

    region                     = data.aws_region.current.region
    spot_interruption_draining = var.node_termination_handler_spot_interruption_draining_enabled
    scheduled_event_draining   = var.node_termination_handler_scheduled_event_draining_enabled
    metadata_tries             = var.node_termination_handler_metadata_tries
    cordon_only                = var.node_termination_handler_cordon_only
    taint_node                 = var.node_termination_handler_taint_node
    json_logging               = var.node_termination_handler_json_logging
    dry_run                    = var.node_termination_handler_dry_run

    service_account = var.node_termination_service_account
    iam_role_arn    = var.node_termination_handler_enable ? module.node_termination_handler_irsa[0].iam_role_arn : ""

    sqs_queue_url = var.node_termination_handler_enable ? data.aws_sqs_queue.node_termination_handler[0].url : ""

    replicas          = var.node_termination_handler_replicas
    pdb_min_available = var.node_termination_handler_pdb_min_available
  }
}

resource "helm_release" "node_termination_handler" {
  count = var.node_termination_handler_enable ? 1 : 0

  name       = var.node_termination_handler_release_name
  chart      = var.node_termination_handler_chart_name
  repository = var.node_termination_handler_chart_repository_url
  version    = var.node_termination_handler_chart_version
  namespace  = var.node_termination_namespace

  max_history = var.helm_release_max_history

  values = [
    templatefile("${path.module}/templates/nth.yaml", local.node_termination_handler_values),
  ]
}

module "node_termination_handler_irsa" {
  count = var.node_termination_handler_enable ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "~> 6.0"

  name                 = coalesce(var.node_termination_handler_iam_role, "${var.cluster_name}-nth")
  description          = "EKS Cluster ${var.cluster_name} Node Termination Handler"
  permissions_boundary = var.node_termination_handler_permissions_boundary

  attach_node_termination_handler_policy  = true
  node_termination_handler_sqs_queue_arns = [var.node_termination_handler_sqs_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.node_termination_namespace}:${var.node_termination_service_account}"]
    }
  }
}

#########################################################################################################################
# Instance Refresh supporting resources
# See example at https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v18.7.2/examples/irsa_autoscale_refresh
#########################################################################################################################
locals {
  nth_sqs_name = coalesce(var.node_termination_handler_sqs_name, "${var.cluster_name}-nth")
}

module "node_termination_handler_sqs" {
  count = var.create_node_termination_handler_sqs ? 1 : 0

  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 5.0"

  name   = local.nth_sqs_name
  region = var.region

  message_retention_seconds     = 300
  source_queue_policy_documents = data.aws_iam_policy_document.node_termination_handler_sqs.json
}

data "aws_iam_policy_document" "node_termination_handler_sqs" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${local.nth_sqs_name}"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
  }
}

# Handler Spot Instances termination
resource "aws_cloudwatch_event_rule" "node_termination_handler_spot" {
  count = var.node_termination_handler_enable ? 1 : 0

  name        = coalesce(var.node_termination_handler_spot_event_name, "${var.cluster_name}-spot-termination")
  description = "Node termination event rule for EKS Cluster ${var.cluster_name}"
  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "node_termination_handler_spot" {
  count = var.node_termination_handler_enable ? 1 : 0

  target_id = coalesce(var.node_termination_handler_spot_event_name, "${var.cluster_name}-spot-termination")
  rule      = aws_cloudwatch_event_rule.node_termination_handler_spot[0].name
  arn       = module.node_termination_handler_sqs[0].queue_arn
}
