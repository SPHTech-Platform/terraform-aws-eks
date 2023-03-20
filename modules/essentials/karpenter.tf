module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.10.0"

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  cluster_name = var.cluster_name

  irsa_oidc_provider_arn          = var.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = var.worker_iam_role_arn

}

resource "helm_release" "karpenter" {
  namespace        = "karpenter"
  create_namespace = true

  name       = var.karpenter_release_name
  repository = var.karpenter_chart_repository
  chart      = var.karpenter_chart_name
  version    = var.karpenter_chart_version

  set {
    name  = "settings.aws.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.aws.clusterEndpoint"
    value = var.cluster_arn
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.karpenter.irsa_arn, "")
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = try(module.karpenter.instance_profile_name, "")
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = try(module.karpenter.queue_name, "")
  }
}

module "karpenter_irsa_role" {
  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.14.0"

  role_name                          = "karpenter_controller"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_id         = var.cluster_name
  karpenter_controller_node_iam_role_arns = [var.worker_iam_role_arn]

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["${var.karpenter_namespace}:${var.karpenter_service_account_name}"]
    }
  }
}
