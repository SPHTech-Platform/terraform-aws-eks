locals {
  # Karpenter Provisioners Config
  # Use default var
  karpenter_provisioners = var.karpenter_provisioners

  # Karpenter Nodetemplate Config
  karpenter_nodetemplates = coalescelist(var.karpenter_nodetemplates, [
    {
      name = "default"
      karpenter_subnet_selector_map = {
        "Name" = "aft-app-ap-southeast*"
      }
      karpenter_security_group_selector_map = {
        "aws-ids" = module.eks.cluster_primary_security_group_id
      }
      karpenter_node_metadata_options = {
        httpEndpoint            = "enabled"
        httpProtocolIPv6        = var.cluster_ip_family != "ipv6" ? "disabled" : "enabled"
        httpPutResponseHopLimit = 1
        httpTokens              = "required"
      }
      karpenter_nodetemplate_tag_map = {
        "karpenter.sh/discovery" = module.eks.cluster_name,
        "eks:cluster-name"       = module.eks.cluster_name,
      }
      karpenter_ami_family = "Bottlerocket"
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
            "volumeSize"          = "50Gi"
            "volumeType"          = "gp3"
            "deleteOnTermination" = true
          }
        }
      ]
    }
  ])

}

module "karpenter" {
  source = "./modules/karpenter"

  providers = {
    kubectl = kubectl
    helm    = helm
  }

  count = var.autoscaling_mode == "karpenter" ? 1 : 0

  karpenter_chart_version = var.karpenter_chart_version

  cluster_name        = var.cluster_name
  cluster_endpoint    = module.eks.cluster_endpoint
  oidc_provider_arn   = module.eks.oidc_provider_arn
  worker_iam_role_arn = aws_iam_role.workers.arn

  # Add the provisioners and nodetemplates after CRDs are installed
  karpenter_provisioners  = local.karpenter_provisioners
  karpenter_nodetemplates = local.karpenter_nodetemplates
  enable_drift_detection  = var.karpenter_enable_drift_detection

  create_fargate_logger_configmap = var.create_fargate_logger_configmap_for_karpenter
  create_aws_observability_ns     = var.create_aws_observability_ns_for_karpenter
  create_fargate_log_group        = var.create_fargate_log_group_for_karpenter
  create_fargate_logging_policy   = var.create_fargate_logging_policy_for_karpenter

  # Required for Fargate profile
  subnet_ids = var.subnet_ids
}


resource "kubernetes_manifest" "fargate_node_security_group_policy_for_karpenter" {
  count = var.fargate_cluster && var.create_node_security_group && var.autoscaling_mode == "karpenter" ? 1 : 0

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-karpenter-namespace-sg"
      namespace = "karpenter"
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
