resource "helm_release" "cluster_autoscaler" {
  count = var.autoscaling_mode == "cluster_autoscaler" || var.migrate_from_cluster_autoscaler ? 1 : 0

  name       = var.cluster_autoscaler_release_name
  chart      = var.cluster_autoscaler_chart_name
  repository = var.cluster_autoscaler_chart_repository
  version    = var.cluster_autoscaler_chart_version
  namespace  = var.cluster_autoscaler_namespace

  max_history = var.helm_release_max_history

  values = [
    templatefile("${path.module}/templates/autoscaler.yaml", local.cluster_autoscaler_values),
  ]
}

locals {
  cluster_autoscaler_values = {
    fullname_override = var.cluster_autoscaler_release_name

    cluster_name = var.cluster_name
    aws_region   = data.aws_region.current.name

    service_account_name = var.cluster_autoscaler_service_account_name
    role_arn             = try(module.cluster_autoscaler_irsa_role[0].iam_role_arn, "")

    image          = var.cluster_autoscaler_image
    tag            = var.cluster_autoscaler_tag
    replica        = var.cluster_autoscaler_replica
    priority_class = var.cluster_autoscaler_priority_class
    resources      = jsonencode(var.cluster_autoscaler_resources)

    tolerations = jsonencode(var.cluster_autoscaler_tolerations)
    affinity    = jsonencode(var.cluster_autoscaler_affinity)
    pdb         = jsonencode(var.cluster_autoscaler_pdb)

    extra_env = jsonencode({
      "AWS_STS_REGIONAL_ENDPOINTS" = "regional"
      }
    )

    expander = var.cluster_autoscaler_expander

    pod_annotations             = jsonencode(var.cluster_autoscaler_pod_annotations)
    pod_labels                  = jsonencode(var.cluster_autoscaler_pod_labels)
    service_annotations         = jsonencode(var.cluster_autoscaler_service_annotations)
    topology_spread_constraints = jsonencode(var.cluster_autoscaler_topology_spread_constraints)

    vpa                          = jsonencode(var.cluster_autoscaler_vpa)
    secret_key_ref_name_override = var.cluster_autoscaler_secret_key_ref_name_override
  }
}

module "cluster_autoscaler_irsa_role" {
  count = var.autoscaling_mode == "cluster_autoscaler" || var.migrate_from_cluster_autoscaler ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.11.2"

  role_name_prefix              = coalesce(var.cluster_autoscaler_iam_role, "${var.cluster_name}-autoscaler-")
  role_description              = "EKS Cluster ${var.cluster_name} Autoscaler"
  role_permissions_boundary_arn = var.cluster_autoscaler_permissions_boundary

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [var.cluster_name]

  oidc_providers = {
    ex = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.cluster_autoscaler_namespace}:${var.cluster_autoscaler_service_account_name}"]
    }
  }

  tags = var.tags
}
