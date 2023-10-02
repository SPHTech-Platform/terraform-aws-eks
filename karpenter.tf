locals {
  # Karpenter Provisioners Config
  # Use default var
  karpenter_provisioners = var.karpenter_provisioners

  # Karpenter Nodetemplate Config
  karpenter_nodetemplates = length(var.karpenter_nodetemplates) == 0 ? [
    {
      name = "default"
      karpenter_subnet_selector_map = {
        "Name" = "aft-app-ap-southeast*"
      }
      karpenter_security_group_selector_map = {
        "aws-ids" = module.eks.cluster_security_group_id
      }
      karpenter_nodetemplate_tag_map = {
        "karpenter.sh/discovery" = module.eks.cluster_name
      }
      karpenter_ami_family            = "Bottlerocket"
      karpenter_root_volume_size      = "5Gi"
      karpenter_ephemeral_volume_size = "50Gi"
    },
  ] : var.karpenter_nodetemplates
}

module "karpenter" {
  source = "./modules/karpenter"

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  karpenter_chart_version = var.karpenter_chart_version

  install_crds_first = var.install_crds_first

  cluster_name        = var.cluster_name
  cluster_endpoint    = module.eks.cluster_endpoint
  oidc_provider_arn   = module.eks.oidc_provider_arn
  worker_iam_role_arn = aws_iam_role.workers.arn

  # Add the provisioners and nodetemplates after CRDs are installed
  karpenter_provisioners  = local.karpenter_provisioners
  karpenter_nodetemplates = local.karpenter_nodetemplates

  create_fargate_logger_configmap = var.create_fargate_logger_configmap_for_karpenter
  create_aws_observability_ns     = var.create_aws_observability_ns_for_karpenter
  create_fargate_log_group        = var.create_fargate_log_group_for_karpenter
  create_fargate_logging_policy   = var.create_fargate_logging_policy_for_karpenter

  # Required for Fargate profile
  subnet_ids = var.subnet_ids
}
