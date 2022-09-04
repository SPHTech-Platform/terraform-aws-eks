locals {
  node_termination_handler_values = {
    image = var.node_termination_handler_image
    tag   = var.node_termination_handler_tag

    fullname_override = var.node_termination_handler_release_name

    priority_class = var.node_termination_handler_priority_class
    resources      = jsonencode(var.node_termination_handler_resources)

    region                     = data.aws_region.current.name
    spot_interruption_draining = var.node_termination_handler_spot_interruption_draining_enabled
    scheduled_event_draining   = var.node_termination_handler_scheduled_event_draining_enabled
    metadata_tries             = var.node_termination_handler_metadata_tries
    cordon_only                = var.node_termination_handler_cordon_only
    taint_node                 = var.node_termination_handler_taint_node
    json_logging               = var.node_termination_handler_json_logging
    dry_run                    = var.node_termination_handler_dry_run

    service_account = var.node_termination_service_account
    iam_role_arn    = var.node_termination_handler_enable ? module.node_termination_handler_irsa[0].iam_role_arn : ""

    sqs_queue_url = data.aws_sqs_queue.node_termination_handler[0].url

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

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.21.1"

  role_name_prefix              = coalesce(var.node_termination_handler_iam_role, "${var.cluster_name}-nth-")
  role_description              = "EKS Cluster ${var.cluster_name} Node Termination Handler"
  role_permissions_boundary_arn = var.node_termination_handler_permissions_boundary

  attach_node_termination_handler_policy  = true
  node_termination_handler_sqs_queue_arns = [var.node_termination_handler_sqs_arn]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.node_termination_namespace}:${var.node_termination_service_account}"]
    }
  }
}
