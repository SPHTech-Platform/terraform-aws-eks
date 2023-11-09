module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.18.0"

  cluster_name = var.cluster_name

  irsa_oidc_provider_arn          = var.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = var.worker_iam_role_arn

  enable_karpenter_instance_profile_creation = true # Might be removed in later versions https://github.com/terraform-aws-modules/terraform-aws-eks/pull/2800/files

}

resource "helm_release" "karpenter" {

  namespace        = var.karpenter_namespace
  create_namespace = true

  name       = var.karpenter_release_name
  repository = var.karpenter_chart_repository
  chart      = var.karpenter_chart_name
  version    = var.karpenter_chart_version

  skip_crds = true # CRDs are managed by module.karpenter-crds
  values = [
    <<-EOT
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueueName: ${module.karpenter.queue_name}
      aws:
        defaultInstanceProfile: ${module.karpenter.instance_profile_name}
        enablePodENI: ${var.enable_pod_eni}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.irsa_arn}
    EOT
  ]

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
    "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml",
    "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.sh_nodeclaims.yaml",
    "https://raw.githubusercontent.com/aws/karpenter/${var.karpenter_chart_version}/pkg/apis/crds/karpenter.sh_nodepools.yaml",
  ]

}

#########################
## KUBECTL NODEPOOL ##
#########################

resource "kubectl_manifest" "karpenter_nodepool" {

  for_each = { for nodepool in var.karpenter_nodepools : nodepool.nodepool_name => nodepool }

  yaml_body = templatefile("${path.module}/templates/nodepool.tftpl", {
    nodepool_name                          = each.value.nodepool_name
    karpenter_nodepool_node_labels_yaml    = length(keys(each.value.karpenter_nodepool_node_labels)) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_node_labels), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodepool_annotations_yaml    = length(keys(each.value.karpenter_nodepool_annotations)) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_annotations), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    nodeclass_name                         = each.value.nodeclass_name
    karpenter_nodepool_node_taints_yaml    = length(each.value.karpenter_nodepool_node_taints) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_node_taints), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodepool_startup_taints_yaml = length(each.value.karpenter_nodepool_startup_taints) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_startup_taints), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_requirements_yaml            = replace(yamlencode(each.value.karpenter_requirements), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodepool_disruption          = each.value.karpenter_nodepool_disruption
    karpenter_nodepool_weight              = each.value.karpenter_nodepool_weight
  })

  depends_on = [module.karpenter-crds]
}

##########################
## KUBECTL NODECLASS ##
##########################
resource "kubectl_manifest" "karpenter_nodeclass" {
  for_each = { for nodeclass in var.karpenter_nodeclasses : nodeclass.nodeclass_name => nodeclass }

  yaml_body = templatefile("${path.module}/templates/nodeclass.tftpl", {
    nodeclass_name                             = each.value.nodeclass_name
    CLUSTER_NAME                               = var.cluster_name
    karpenter_subnet_selector_map_yaml         = length(each.value.karpenter_subnet_selector_maps) == 0 ? "" : yamlencode(each.value.karpenter_subnet_selector_maps)
    karpenter_security_group_selector_map_yaml = length(each.value.karpenter_security_group_selector_maps) == 0 ? "" : yamlencode(each.value.karpenter_security_group_selector_maps)
    karpenter_ami_selector_map_yaml            = length(each.value.karpenter_ami_selector_maps) == 0 ? "" : yamlencode(each.value.karpenter_ami_selector_maps)
    karpenter_node_role                        = each.value.karpenter_node_role
    karpenter_node_user_data                   = each.value.karpenter_node_user_data
    karpenter_node_tags_map_yaml               = length(keys(each.value.karpenter_node_tags_map)) == 0 ? "" : yamlencode(each.value.karpenter_node_tags_map)
    karpenter_node_metadata_options_yaml       = length(keys(each.value.karpenter_node_metadata_options)) == 0 ? "" : yamlencode(each.value.karpenter_node_metadata_options)
    karpenter_ami_family                       = each.value.karpenter_ami_family
    karpenter_block_device_mapping_yaml        = length(each.value.karpenter_block_device_mapping) == 0 ? "" : yamlencode(each.value.karpenter_block_device_mapping)

  })

  depends_on = [module.karpenter-crds]
}
