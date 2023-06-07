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

  namespace        = var.karpenter_namespace
  create_namespace = true

  name       = var.karpenter_release_name
  repository = var.karpenter_chart_repository
  chart      = var.karpenter_chart_name
  version    = var.karpenter_chart_version

  skip_crds = true # CRDs are managed by module.karpenter-crds

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
    module.karpenter[0].irsa_arn,
    module.karpenter-crds,
  ]
}

###################
## UPDATING CRDS ##
###################

module "karpenter-crds" {
  source  = "rpadovani/helm-crds/kubectl"
  version = "0.3.0"

  crds_urls = [
    "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.sh_provisioners.yaml",
    "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.k8s.aws_awsnodetemplates.yaml",
    # "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.sh_machines.yaml", #not part of release yet
  ]
}

################
##### CRD ######
################

resource "kubernetes_manifest" "karpenter_provisioner" {

  for_each = { for provisioner in var.karpenter_provisioners : provisioner.name => provisioner if var.autoscaling_mode == "karpenter" }

  manifest = {
    apiVersion = "karpenter.sh/v1alpha5"
    kind       = "Provisioner"
    metadata = {
      name = each.value.name
    }
    spec = {
      labels = each.value.karpenter_provisioner_node_labels
      taints = each.value.karpenter_provisioner_node_taints

      requirements = [
        {
          key      = "node.kubernetes.io/instance-type"
          operator = "In"
          values   = each.value.karpenter_instance_types_list
        },
        {
          key      = "karpenter.sh/capacity-type"
          operator = "In"
          values   = each.value.karpenter_capacity_type_list
        },
        {
          key      = "kubernetes.io/arch"
          operator = "In"
          values   = each.value.karpenter_arch_list
        },
        {
          key      = "kubernetes.io/os"
          operator = "In"
          values   = ["linux"]
        },
      ]
      limits = {
        resources = {
          cpu = "1k"
        }
      }
      providerRef = {
        name = each.value.provider_ref_nodetemplate_name
      }
      ttlSecondsAfterEmpty = 30
    }
  }

  computed_fields = ["spec.taints", "spec.requirements"]

  depends_on = [
    helm_release.karpenter
  ]
}

resource "kubernetes_manifest" "karpenter_node_template" {

  for_each = { for nodetemplate in var.karpenter_nodetemplates : nodetemplate.name => nodetemplate if var.autoscaling_mode == "karpenter" }

  manifest = {
    apiVersion = "karpenter.k8s.aws/v1alpha1"
    kind       = "AWSNodeTemplate"
    metadata = {
      name = each.value.name
    }
    spec = {
      subnetSelector        = each.value.karpenter_subnet_selector_map
      securityGroupSelector = each.value.karpenter_security_group_selector_map
      amiFamily             = each.value.karpenter_ami_family

      tags = each.value.karpenter_nodetemplate_tag_map
    }
  }

  depends_on = [
    helm_release.karpenter
  ]
}
