module "karpenter_fargate_profile" {
  source = "../fargate_profile"

  create_aws_observability_ns     = var.create_aws_observability_ns
  create_fargate_logger_configmap = var.create_fargate_logger_configmap
  create_fargate_log_group        = var.create_fargate_log_group
  create_fargate_logging_policy   = var.create_fargate_logging_policy
  cluster_name                    = var.cluster_name
  fargate_profiles = {
    karpenter = {
      iam_role_name = "fargate_profile_karpenter"
      subnet_ids    = var.subnet_ids
      selectors = [
        {
          namespace = var.karpenter_namespace
        }
      ]
    }
  }
}
