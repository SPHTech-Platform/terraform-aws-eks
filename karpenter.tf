locals {
  # Karpenter Provisioners Config
  # Use default var
  karpenter_nodepools = var.karpenter_nodepools

  # Karpenter Nodetemplate Config
  karpenter_nodeclasses = coalescelist(var.karpenter_nodeclasses, [
    {
      nodeclass_name = "default"
      karpenter_subnet_selector_maps = [{
        tags = var.karpenter_default_subnet_selector_tags,
        }
      ]
      karpenter_node_role                    = aws_iam_role.workers.name
      karpenter_security_group_selector_maps = lookup(local.karpenter_security_group_maps, var.karpenter_security_group_selector_terms_type, {})
      karpenter_node_metadata_options = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = var.cluster_ip_family != "ipv6" ? "disabled" : "enabled"
        httpPutResponseHopLimit = 1
        httpTokens              = "required"
      }
      karpenter_ami_selector_maps = [{
        "alias" = "bottlerocket@latest"
      }]
      karpenter_node_user_data = ""
      karpenter_node_tags_map = {
        "karpenter.sh/discovery" = module.eks.cluster_name,
        "eks:cluster-name"       = module.eks.cluster_name,
      }
      karpenter_block_device_mapping = [
        {
          #karpenter_root_volume_size
          "deviceName" = "/dev/xvda"
          "ebs" = {
            "encrypted"           = true
            "volumeSize"          = "5Gi"
            "volumeType"          = "gp3"
            "deleteOnTermination" = true
          }
          }, {
          #karpenter_ephemeral_volume_size
          "deviceName" = "/dev/xvdb",
          "ebs" = {
            "encrypted"           = true
            "volumeSize"          = var.karpenter_ephemeral_volume_size
            "volumeType"          = "gp3"
            "deleteOnTermination" = true
          }
        }
      ]
    },
  ])

  # Kaprenter Upgrade
  karpenter_upgrade_nodeclasses = concat([
    for nodeclass in local.karpenter_nodeclasses : merge(nodeclass, {
      nodeclass_name = "${nodeclass.nodeclass_name}-upgrade"
    })
  ], local.karpenter_nodeclasses)

  karpenter_upgrade_nodepools = concat(flatten([
    for nodeclass in local.karpenter_nodeclasses : [
      for nodepool in local.karpenter_nodepools : merge(nodepool, {
        nodepool_name  = "${nodepool.nodepool_name}-upgrade"
        nodeclass_name = "${nodeclass.nodeclass_name}-upgrade"
    })]
  ]), local.karpenter_nodepools)

  # Kaprenter Security Groups Selector
  additional_karpenter_security_group_id_maps = [
    for val in var.additional_karpenter_security_group_selector_ids : {
      "id" = val
    }
  ]

  karpenter_security_group_maps = {
    tags = [{
      tags = merge({
        "karpenter.sh/discovery" = module.eks.cluster_name
      }, var.additional_karpenter_security_group_selector_tags)
    }]
    ids = flatten(concat([{
      "id" = module.eks.cluster_primary_security_group_id
      }, local.additional_karpenter_security_group_id_maps
    ]))
  }
}

module "karpenter" {
  source = "./modules/karpenter"

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  karpenter_chart_version     = var.karpenter_chart_version
  karpenter_crd_chart_version = var.karpenter_crd_chart_version

  cluster_name        = var.cluster_name
  cluster_endpoint    = module.eks.cluster_endpoint
  cluster_ip_family   = var.cluster_ip_family
  oidc_provider_arn   = module.eks.oidc_provider_arn
  worker_iam_role_arn = aws_iam_role.workers.arn

  karpenter_nodepools     = var.karpenter_upgrade ? local.karpenter_upgrade_nodepools : local.karpenter_nodepools
  karpenter_nodeclasses   = var.karpenter_upgrade ? local.karpenter_upgrade_nodeclasses : local.karpenter_nodeclasses
  karpenter_pod_resources = var.karpenter_pod_resources

  create_karpenter_fargate_profile = var.create_fargate_profile_for_karpenter
  create_fargate_logger_configmap  = var.create_fargate_logger_configmap_for_karpenter
  create_aws_observability_ns      = var.create_aws_observability_ns_for_karpenter
  create_fargate_log_group         = var.create_fargate_log_group_for_karpenter
  create_fargate_logging_policy    = var.create_fargate_logging_policy_for_karpenter

  # Required for Fargate profile
  subnet_ids = var.subnet_ids

  # Enable for v1 Upgrade
  enable_v1_permissions = var.enable_v1_permissions_for_karpenter

  # Enable Pod Identity
  ## AWS Fargate aren’t supported EKS Pod Identities ##
  enable_pod_identity             = !var.fargate_cluster ? var.enable_pod_identity_for_karpenter : false
  create_pod_identity_association = !var.fargate_cluster && var.enable_pod_identity_for_karpenter ? true : false

  # Metrics scraping
  enable_service_monitoring = var.enable_karpenter_service_monitoring
}

resource "kubernetes_manifest" "fargate_node_security_group_policy_for_karpenter" {
  count = var.fargate_cluster && var.create_node_security_group && var.autoscaling_mode == "karpenter" ? 1 : 0

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-karpenter-namespace-sg"
      namespace = "kube-system"
    }
    spec = {
      podSelector = {
        matchLabels = {}
      }
      securityGroups = {
        groupIds = [module.eks.node_security_group_id]
      }
    }
  }

  depends_on = [module.karpenter]
}
