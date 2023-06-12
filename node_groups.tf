locals {
  default_group = {
    use_name_prefix = true
    name            = var.default_group_name

    launch_template_use_name_prefix = true
    launch_template_name            = var.default_group_launch_template_name

    platform       = "bottlerocket"
    ami_id         = coalesce(var.default_group_ami_id, data.aws_ami.eks_default_bottlerocket.id)
    instance_types = var.default_group_instance_types

    min_size = var.default_group_min_size
    max_size = var.default_group_max_size

    subnet_ids = length(var.subnet_ids) == 0 && length(var.default_group_subnet_ids) == 0 ? [] : coalescelist(var.default_group_subnet_ids, var.subnet_ids)

    enable_bootstrap_user_data = true
    # See https://github.com/bottlerocket-os/bottlerocket#settings
    bootstrap_extra_args = <<-EOT
      # The admin host container provides SSH access and runs with "superpowers".
      # It is disabled by default, but can be disabled explicitly.
      [settings.host-containers.admin]
      enabled = false
      # The control host container provides out-of-band access via SSM.
      # It is enabled by default, and can be disabled if you do not expect to use SSM.
      # This could leave you with no way to access the API and change settings on an existing node!
      [settings.host-containers.control]
      enabled = true
      [settings.kubernetes.node-labels]
      "lifecycle" = "OnDemand"
      "bottlerocket.aws/updater-interface-version" = "2.0.0"
      %{if var.only_critical_addons_enabled}
      [settings.kubernetes.node-taints]
      "CriticalAddonsOnly" = "true:NoSchedule"
      %{endif}
      EOT

    labels = merge({
      "lifecycle"                                  = "OnDemand"
      "bottlerocket.aws/updater-interface-version" = "2.0.0"
    }, var.default_group_node_labels)

    taints = var.only_critical_addons_enabled ? [
      {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ] : []

    # See https://github.com/bottlerocket-os/bottlerocket#default-volumes
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 5
          volume_type           = "gp3"
          encrypted             = true
          kms_key_id            = module.kms_ebs.key_arn
          delete_on_termination = true
        }
      }
      xvdb = {
        device_name = "/dev/xvdb"
        ebs = {
          volume_size           = var.default_group_volume_size
          volume_type           = "gp3"
          encrypted             = true
          kms_key_id            = module.kms_ebs.key_arn
          delete_on_termination = true
        }
      }
    }
  }

  eks_managed_node_groups = merge(
    { default = local.default_group },
    var.eks_managed_node_groups,
  )

  default_fargate_profiles = merge(
    {
      default = {
        name = "default"
        selectors = [
          {
            namespace = "default"
          }
        ]
        subnet_ids = var.subnet_ids
      }
    },
    { for subnet in var.subnet_ids :
      "kube-system-${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}" => {
        selectors = [
          { namespace = "kube-system" }
        ]
        # Create one profile per AZ for even spread
        subnet_ids = [subnet]
      }
    }
  )

  fargate_profiles = merge(
    local.default_fargate_profiles,
    var.fargate_profiles,
  )
}

data "aws_arn" "cluster" {
  arn = module.eks.cluster_arn
}

module "node_groups" {
  source = "./modules/eks_managed_nodes"

  count = !var.fargate_cluster ? 1 : 0

  cluster_name    = split("/", data.aws_arn.cluster.resource)[1]
  cluster_version = module.eks.cluster_version

  worker_iam_role_arn = aws_iam_role.workers.arn

  worker_security_group_id = module.eks.node_security_group_id

  eks_managed_node_groups         = local.eks_managed_node_groups
  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  force_imdsv2 = var.force_imdsv2
  force_irsa   = var.force_irsa

  tags = var.tags
}

module "fargate_profiles" {
  source = "./modules/fargate_profile"

  count = var.fargate_cluster ? 1 : 0

  cluster_name             = split("/", data.aws_arn.cluster.resource)[1]
  fargate_profiles         = local.fargate_profiles
  fargate_profile_defaults = var.fargate_profile_defaults
  create_aws_observability_ns = var.create_aws_observability_ns
  create_fargate_logger_configmap = var.create_fargate_logger_configmap

  tags = var.tags
}

################################################
# Resources below are to enable Windows Support for Cluster.
################################################

locals {
  aws_vpc_cni_configmap_data = {
    enable-windows-ipam = "true"
  }
}

resource "kubernetes_config_map_v1" "amazon_vpc_cni" {
  count = var.enable_cluster_windows_support ? 1 : 0

  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = local.aws_vpc_cni_configmap_data
}
