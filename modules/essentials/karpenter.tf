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
    module.karpenter.irsa_arn
  ]
}

################
##### CRD ######
################

resource "kubectl_manifest" "karpenter_provisioner" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1alpha5
    kind: Provisioner
    metadata:
      name: default
    spec:
      requirements:
        - key: node.kubernetes.io/instance-type
          operator: In
          values:
          - m5a.xlarge
          - m6.xlarge
        - key: karpenter.sh/capacity-type
          operator: In
          values:
          - on-demand
        - key: kubernetes.io/arch
          operator: In
          values:
          - amd64
      limits:
        resources:
          cpu: 1000
      providerRef:
        name: default
      ttlSecondsAfterEmpty: 30
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubectl_manifest" "karpenter_node_template" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1alpha1
    kind: AWSNodeTemplate
    metadata:
      name: default
    spec:
      subnetSelector:
        karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelector:
        karpenter.sh/discovery: ${var.cluster_name}
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter
  ]
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
