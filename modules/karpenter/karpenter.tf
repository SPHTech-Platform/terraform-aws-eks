module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.16.0"

  cluster_name = var.cluster_name

  irsa_oidc_provider_arn          = var.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = var.worker_iam_role_arn

}

resource "helm_release" "karpenter" {

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

  set {
    name  = "settings.aws.enablePodENI"
    value = var.enable_pod_eni
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
    "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.sh_machines.yaml",
  ]

}

#########################
## KUBECTL PROVISIONER ##
#########################

resource "kubectl_manifest" "karpenter_provisioner" {

  for_each = { for provisioner in var.karpenter_provisioners : provisioner.name => provisioner }

  yaml_body = templatefile("${path.module}/templates/provisioner.tftpl", {
    provisioner_name                       = each.value.name
    karpenter_provisioner_node_taints_yaml = length(keys(each.value.karpenter_provisioner_node_labels)) == 0 ? "" : replace(yamlencode(each.value.karpenter_provisioner_node_taints), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_provisioner_node_labels_yaml = length(each.value.karpenter_provisioner_node_taints) == 0 ? "" : replace(yamlencode(each.value.karpenter_provisioner_node_labels), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_requirements_yaml            = replace(yamlencode(each.value.karpenter_requirements), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
  })

  depends_on = [module.karpenter-crds]
}

##########################
## KUBECTL NODETEMPLATE ##
##########################
resource "kubectl_manifest" "karpenter_node_template" {
  for_each = { for nodetemplate in var.karpenter_nodetemplates : nodetemplate.name => nodetemplate }

  yaml_body = templatefile("${path.module}/templates/nodetemplate.tftpl", {
    node_template_name                         = each.value.name
    karpenter_subnet_selector_map_yaml         = replace(yamlencode(each.value.karpenter_subnet_selector_map), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_security_group_selector_map_yaml = replace(yamlencode(each.value.karpenter_security_group_selector_map), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodetemplate_tag_map_yaml        = replace(yamlencode(each.value.karpenter_nodetemplate_tag_map), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_ami_family                       = each.value.karpenter_ami_family
    karpenter_block_device_mapping_yaml        = replace(yamlencode(each.value.karpenter_block_device_mapping), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")

  })

  depends_on = [module.karpenter-crds]
}
