locals {
  # Karpenter Provisioners Config
  karpenter_provisioners = [
    {
      name                           = "default"
      provider_ref_nodetemplate_name = "default"

      karpenter_instance_types_list     = ["m6a.xlarge", "m6i.xlarge"]
      karpenter_capacity_type_list      = ["on-demand"]
      karpenter_provisioner_node_labels = {}
      karpenter_provisioner_node_taints = []
      karpenter_arch_list               = ["amd64"]
    },
    {
      name                           = "default-2xlarge"
      provider_ref_nodetemplate_name = "default"

      karpenter_instance_types_list     = ["m5a.2xlarge", "m6i.2xlarge"]
      karpenter_capacity_type_list      = ["on-demand"]
      karpenter_provisioner_node_labels = {}
      karpenter_provisioner_node_taints = []
      karpenter_arch_list               = ["amd64"]
    },
    {
      name                           = "default-4xlarge-c6a"
      provider_ref_nodetemplate_name = "default"

      karpenter_instance_types_list     = ["c6a.4xlarge", "c6i.4xlarge"]
      karpenter_capacity_type_list      = ["on-demand"]
      karpenter_provisioner_node_labels = {}
      karpenter_provisioner_node_taints = []
      karpenter_arch_list               = ["amd64"]
    },
  ]
  # Karpenter Nodetemplate Config
  karpenter_nodetemplates = [
    {
      name = "default"
      karpenter_subnet_selector_map = {
        "Name" = "aft-app-ap-southeast*"
      }
      karpenter_security_group_selector_map = {
        "aws-ids" = module.eks.node_security_group_id
      }
      karpenter_nodetemplate_tag_map = {
        "karpenter.sh/discovery" = module.eks.cluster_name
      }
      karpenter_ami_family            = "Bottlerocket"
      karpenter_root_volume_size      = "5Gi"
      karpenter_ephemeral_volume_size = "50Gi"
    },
  ]
}

module "karpenter" {
  source = "./modules/karpenter"

  karpenter_chart_version = "v0.30.0"

  cluster_name        = var.cluster_name
  cluster_endpoint    = module.eks.cluster_endpoint
  oidc_provider_arn   = module.eks.oidc_provider_arn
  worker_iam_role_arn = aws_iam_role.workers.arn

  autoscaling_mode = var.autoscaling_mode
  # Add the provisioners and nodetemplates after CRDs are installed
  karpenter_provisioners  = local.karpenter_provisioners
  karpenter_nodetemplates = local.karpenter_nodetemplates

  # Required for Fargate profile
  subnet_ids = var.subnet_ids
}
