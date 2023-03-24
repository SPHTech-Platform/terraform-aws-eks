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

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

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
    value = var.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = try(module.karpenter[0].irsa_arn, "")
  }

  set {
    name  = "settings.aws.defaultInstanceProfile"
    value = try(module.karpenter[0].instance_profile_name, "")
  }

  set {
    name  = "settings.aws.interruptionQueueName"
    value = try(module.karpenter[0].queue_name, "")
  }

  depends_on = [
    module.karpenter[0].irsa_arn
  ]
}

################
##### CRD ######
################

resource "kubernetes_manifest" "karpenter_provisioner" {

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  manifest = {
    apiVersion = "karpenter.sh/v1alpha5"
    kind       = "Provisioner"
    metadata = {
      name = "default"
    }
    spec = {
      labels = var.karpenter_provisioner_node_labels
      taints = var.karpenter_provisioner_node_taints
      requirements = [
        {
          key      = "node.kubernetes.io/instance-type"
          operator = "In"
          values   = var.karpenter_instance_types_list
        },
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = var.karpenter_capacity_type_list
        },
        {
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = var.karpenter_arch_list
        },
      ]
      limits = {
        resources = {
          cpu = 1000
        }
      }
      providerRef = {
        name = "default"
      }
      ttlSecondsAfterEmpty = 30
    }
  }

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubernetes_manifest" "karpenter_node_template" {

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1alpha1"
    kind       = "AWSNodeTemplate"
    metadata = {
      name = "default"
    }
    spec = {
      subnetSelector        = var.karpenter_subnet_selector_map
      securityGroupSelector = var.karpenter_security_group_selector_map
      tags                  = var.karpenter_nodetemplate_tag_map
    }
  }
}

################
##### ROLE #####
################
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