module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.24.3"

  cluster_name = var.cluster_name

  enable_irsa                     = true
  irsa_oidc_provider_arn          = var.oidc_provider_arn
  irsa_namespace_service_accounts = ["${var.karpenter_namespace}:karpenter"]

  create_access_entry   = false # Remove this entry when EKS module updated to 20.x.x
  create_node_iam_role  = false
  node_iam_role_arn     = var.worker_iam_role_arn
  cluster_ip_family     = var.cluster_ip_family
  enable_v1_permissions = var.enable_v1_permissions

  enable_pod_identity             = var.enable_pod_identity
  create_pod_identity_association = var.create_pod_identity_association
}

###############################
## Karpenter CRDs Helm Chart ##
###############################
resource "helm_release" "karpenter-crd" {
  namespace        = var.karpenter_crd_namespace
  create_namespace = true

  name       = var.karpenter_crd_release_name
  repository = var.karpenter_crd_chart_repository
  chart      = var.karpenter_crd_chart_name
  version    = var.karpenter_crd_chart_version
  skip_crds  = true
}

##########################
## Karpenter Helm Chart ##
##########################
resource "helm_release" "karpenter" {
  namespace        = var.karpenter_namespace
  create_namespace = true

  name       = var.karpenter_release_name
  repository = var.karpenter_chart_repository
  chart      = var.karpenter_chart_name
  version    = var.karpenter_chart_version

  skip_crds = true # CRDs are managed by the karpenter-crd HelmRelease
  values = [
    <<-EOT
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}
    controller:
      resources:
        requests:
          cpu: ${var.karpenter_pod_resources.requests.cpu}
          memory: ${var.karpenter_pod_resources.requests.memory}
        limits:
          cpu: ${var.karpenter_pod_resources.limits.cpu}
          memory: ${var.karpenter_pod_resources.limits.memory}
    EOT
  ]

  depends_on = [
    module.karpenter[0].iam_role_arn,
    helm_release.karpenter-crd,
  ]
}

#######################
## KUBECTL NODECLASS ##
#######################
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
    karpenter_node_metadata_options_yaml       = length(keys(each.value.karpenter_node_metadata_options)) == 0 ? "" : replace(yamlencode(each.value.karpenter_node_metadata_options), "/\"([0-9]+)\"/", "$1")
    karpenter_block_device_mapping_yaml        = length(each.value.karpenter_block_device_mapping) == 0 ? "" : yamlencode(each.value.karpenter_block_device_mapping)

  })

  depends_on = [
    helm_release.karpenter
  ]
}

######################
## KUBECTL NODEPOOL ##
######################
resource "kubectl_manifest" "karpenter_nodepool" {

  for_each = { for nodepool in var.karpenter_nodepools : nodepool.nodepool_name => nodepool }

  yaml_body = templatefile("${path.module}/templates/nodepool.tftpl", {
    nodepool_name                              = each.value.nodepool_name
    karpenter_nodepool_node_labels_yaml        = length(keys(each.value.karpenter_nodepool_node_labels)) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_node_labels), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodepool_annotations_yaml        = length(keys(each.value.karpenter_nodepool_annotations)) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_annotations), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    nodeclass_name                             = each.value.nodeclass_name
    karpenter_nodepool_node_taints_yaml        = length(each.value.karpenter_nodepool_node_taints) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_node_taints), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodepool_startup_taints_yaml     = length(each.value.karpenter_nodepool_startup_taints) == 0 ? "" : replace(yamlencode(each.value.karpenter_nodepool_startup_taints), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_requirements_yaml                = replace(yamlencode(each.value.karpenter_requirements), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
    karpenter_nodepool_disruption              = each.value.karpenter_nodepool_disruption
    karpenter_nodepool_weight                  = each.value.karpenter_nodepool_weight
    karpenter_nodepool_disruption_budgets_yaml = replace(yamlencode(each.value.karpenter_nodepool_disruption_budgets), "/((?:^|\n)[\\s-]*)\"([\\w-]+)\":/", "$1$2:")
  })

  depends_on = [
    kubectl_manifest.karpenter_nodeclass
  ]
}
