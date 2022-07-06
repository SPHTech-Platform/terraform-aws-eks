locals {

  cluster_autoscaler_label_tags = merge([
    for name, group in data.aws_eks_node_group.this : {
      for label_name, label_value in coalesce(group.labels, {}) : "${name}|label|${label_name}" => {
        autoscaling_group = group.resources[0].autoscaling_groups[0],
        key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
        value             = label_value,
      }
    }
  ]...)

  # cluster_autoscaler_label_tags = merge([
  #   for asg in module.eks_managed_node_group.node_group_autoscaling_group_names : {
  #     for label_name, label_value in module.eks_managed_node_group.node_group_labels : "${asg}|label|${label_name}" => {
  #       autoscaling_group = asg,
  #       key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
  #       value             = label_value,
  #     }
  #   }
  # ]...)

  cluster_autoscaler_taint_tags = merge([
    for name, group in data.aws_eks_node_group.this : {
      for taint in coalesce(group.taints, []) : "${name}|taint|${taint.key}" => {
        autoscaling_group = group.node_group_autoscaling_group_names[0],
        key               = "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}"
        value             = "${taint.value}:${taint.effect}"
      }
    }
  ]...)

  cluster_autoscaler_asg_tags = merge(
    local.cluster_autoscaler_label_tags,
    local.cluster_autoscaler_taint_tags,
    # {
    #   "k8s.io/cluster-autoscaler/enabled"             = "true"
    #   "k8s.io/cluster-autoscaler/${var.cluster_name}" = "true"
    # }
  )

  eks_managed_node_group_defaults = merge(
    {
      create_iam_role = false
      iam_role_arn    = var.worker_iam_role_arn
    },
    var.eks_managed_node_group_defaults
  )

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = var.force_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = var.force_imdsv2 && var.force_irsa ? 1 : 2
  }

  # Cartesian product of node groups and individual subnets
  # Multiple copies of each node group will be created with each subnet
  # defined in the original variable, this will not be needed when using Karpenter instead of CA.
  eks_managed_node_groups = merge([for name, group in var.eks_managed_node_groups : {
    for subnet in try(group.subnet_ids, local.eks_managed_node_group_defaults.subnet_ids, data.aws_eks_cluster.this.vpc_config[0].subnet_ids) : "${name}-${subnet}" => merge(
      group,
      {
        # nodeGroupName can't be longer than 63 characters!
        name       = "${try(group.name, name, "unnamed")}-${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}"
        subnet_ids = [subnet]
        labels = {
          "topology.kubernetes.io/zone" = data.aws_subnet.subnets[subnet].availability_zone
        }
      },
    )
  }]...)
}

################################################################################
# EKS Managed Node Group
################################################################################
module "eks_managed_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 18.26.0"

  for_each = local.eks_managed_node_groups

  cluster_name              = var.cluster_name
  cluster_version           = try(each.value.cluster_version, local.eks_managed_node_group_defaults.cluster_version, data.aws_eks_cluster.this.version)
  cluster_security_group_id = var.cluster_security_group_id
  cluster_ip_family         = "ipv4"

  # EKS Managed Node Group
  name            = try(each.value.name, each.key)
  use_name_prefix = try(each.value.use_name_prefix, local.eks_managed_node_group_defaults.use_name_prefix, true)

  subnet_ids = each.value.subnet_ids

  min_size     = try(each.value.min_size, local.eks_managed_node_group_defaults.min_size, 1)
  max_size     = try(each.value.max_size, local.eks_managed_node_group_defaults.max_size, 3)
  desired_size = try(each.value.desired_size, local.eks_managed_node_group_defaults.desired_size, 1)

  ami_id              = try(each.value.ami_id, local.eks_managed_node_group_defaults.ami_id, "")
  ami_type            = try(each.value.ami_type, local.eks_managed_node_group_defaults.ami_type, null)
  ami_release_version = try(each.value.ami_release_version, local.eks_managed_node_group_defaults.ami_release_version, null)

  capacity_type        = try(each.value.capacity_type, local.eks_managed_node_group_defaults.capacity_type, null)
  disk_size            = try(each.value.disk_size, local.eks_managed_node_group_defaults.disk_size, null)
  force_update_version = try(each.value.force_update_version, local.eks_managed_node_group_defaults.force_update_version, null)
  instance_types       = try(each.value.instance_types, local.eks_managed_node_group_defaults.instance_types, null)
  labels               = try(each.value.labels, local.eks_managed_node_group_defaults.labels, null)

  remote_access = try(each.value.remote_access, local.eks_managed_node_group_defaults.remote_access, {})
  taints        = try(each.value.taints, local.eks_managed_node_group_defaults.taints, {})
  update_config = try(each.value.update_config, local.eks_managed_node_group_defaults.update_config, {})
  timeouts      = try(each.value.timeouts, local.eks_managed_node_group_defaults.timeouts, {})

  # User data
  platform                   = try(each.value.platform, local.eks_managed_node_group_defaults.platform, "linux")
  cluster_endpoint           = try(data.aws_eks_cluster.this.endpoint, "")
  cluster_auth_base64        = try(data.aws_eks_cluster.this.certificate_authority[0].data, "")
  cluster_service_ipv4_cidr  = var.cluster_service_ipv4_cidr
  enable_bootstrap_user_data = try(each.value.enable_bootstrap_user_data, local.eks_managed_node_group_defaults.enable_bootstrap_user_data, false)
  pre_bootstrap_user_data    = try(each.value.pre_bootstrap_user_data, local.eks_managed_node_group_defaults.pre_bootstrap_user_data, "")
  post_bootstrap_user_data   = try(each.value.post_bootstrap_user_data, local.eks_managed_node_group_defaults.post_bootstrap_user_data, "")
  bootstrap_extra_args       = try(each.value.bootstrap_extra_args, local.eks_managed_node_group_defaults.bootstrap_extra_args, "")
  user_data_template_path    = try(each.value.user_data_template_path, local.eks_managed_node_group_defaults.user_data_template_path, "")

  # Launch Template
  create_launch_template          = try(each.value.create_launch_template, local.eks_managed_node_group_defaults.create_launch_template, true)
  launch_template_name            = try(each.value.launch_template_name, local.eks_managed_node_group_defaults.launch_template_name, each.key)
  launch_template_use_name_prefix = try(each.value.launch_template_use_name_prefix, local.eks_managed_node_group_defaults.launch_template_use_name_prefix, true)
  launch_template_version         = try(each.value.launch_template_version, local.eks_managed_node_group_defaults.launch_template_version, null)
  launch_template_description     = try(each.value.launch_template_description, local.eks_managed_node_group_defaults.launch_template_description, "Custom launch template for ${try(each.value.name, each.key)} EKS managed node group")
  launch_template_tags            = try(each.value.launch_template_tags, local.eks_managed_node_group_defaults.launch_template_tags, {})

  ebs_optimized                          = try(each.value.ebs_optimized, local.eks_managed_node_group_defaults.ebs_optimized, null)
  key_name                               = try(each.value.key_name, local.eks_managed_node_group_defaults.key_name, null)
  launch_template_default_version        = try(each.value.launch_template_default_version, local.eks_managed_node_group_defaults.launch_template_default_version, null)
  update_launch_template_default_version = try(each.value.update_launch_template_default_version, local.eks_managed_node_group_defaults.update_launch_template_default_version, true)
  disable_api_termination                = try(each.value.disable_api_termination, local.eks_managed_node_group_defaults.disable_api_termination, null)
  kernel_id                              = try(each.value.kernel_id, local.eks_managed_node_group_defaults.kernel_id, null)
  ram_disk_id                            = try(each.value.ram_disk_id, local.eks_managed_node_group_defaults.ram_disk_id, null)

  block_device_mappings              = try(each.value.block_device_mappings, local.eks_managed_node_group_defaults.block_device_mappings, {})
  capacity_reservation_specification = try(each.value.capacity_reservation_specification, local.eks_managed_node_group_defaults.capacity_reservation_specification, {})
  cpu_options                        = try(each.value.cpu_options, local.eks_managed_node_group_defaults.cpu_options, {})
  credit_specification               = try(each.value.credit_specification, local.eks_managed_node_group_defaults.credit_specification, {})
  elastic_gpu_specifications         = try(each.value.elastic_gpu_specifications, local.eks_managed_node_group_defaults.elastic_gpu_specifications, {})
  elastic_inference_accelerator      = try(each.value.elastic_inference_accelerator, local.eks_managed_node_group_defaults.elastic_inference_accelerator, {})
  enclave_options                    = try(each.value.enclave_options, local.eks_managed_node_group_defaults.enclave_options, {})
  instance_market_options            = try(each.value.instance_market_options, local.eks_managed_node_group_defaults.instance_market_options, {})
  license_specifications             = try(each.value.license_specifications, local.eks_managed_node_group_defaults.license_specifications, {})
  metadata_options                   = try(each.value.metadata_options, local.eks_managed_node_group_defaults.metadata_options, local.metadata_options)
  enable_monitoring                  = try(each.value.enable_monitoring, local.eks_managed_node_group_defaults.enable_monitoring, true)
  network_interfaces                 = try(each.value.network_interfaces, local.eks_managed_node_group_defaults.network_interfaces, [])
  placement                          = try(each.value.placement, local.eks_managed_node_group_defaults.placement, {})

  # IAM role
  create_iam_role               = try(each.value.create_iam_role, local.eks_managed_node_group_defaults.create_iam_role, true)
  iam_role_arn                  = try(each.value.iam_role_arn, local.eks_managed_node_group_defaults.iam_role_arn, null)
  iam_role_name                 = try(each.value.iam_role_name, local.eks_managed_node_group_defaults.iam_role_name, null)
  iam_role_use_name_prefix      = try(each.value.iam_role_use_name_prefix, local.eks_managed_node_group_defaults.iam_role_use_name_prefix, true)
  iam_role_path                 = try(each.value.iam_role_path, local.eks_managed_node_group_defaults.iam_role_path, null)
  iam_role_description          = try(each.value.iam_role_description, local.eks_managed_node_group_defaults.iam_role_description, "EKS managed node group IAM role")
  iam_role_permissions_boundary = try(each.value.iam_role_permissions_boundary, local.eks_managed_node_group_defaults.iam_role_permissions_boundary, null)
  iam_role_tags                 = try(each.value.iam_role_tags, local.eks_managed_node_group_defaults.iam_role_tags, {})
  iam_role_attach_cni_policy    = try(each.value.iam_role_attach_cni_policy, local.eks_managed_node_group_defaults.iam_role_attach_cni_policy, true)
  iam_role_additional_policies  = try(each.value.iam_role_additional_policies, local.eks_managed_node_group_defaults.iam_role_additional_policies, [])

  # Security group
  vpc_security_group_ids            = compact(concat([var.worker_security_group_id], try(each.value.vpc_security_group_ids, local.eks_managed_node_group_defaults.vpc_security_group_ids, [])))
  cluster_primary_security_group_id = try(each.value.attach_cluster_primary_security_group, local.eks_managed_node_group_defaults.attach_cluster_primary_security_group, false) ? data.aws_eks_cluster.this.vpc_config[0].cluster_security_group_id : null
  create_security_group             = try(each.value.create_security_group, local.eks_managed_node_group_defaults.create_security_group, true)
  security_group_name               = try(each.value.security_group_name, local.eks_managed_node_group_defaults.security_group_name, null)
  security_group_use_name_prefix    = try(each.value.security_group_use_name_prefix, local.eks_managed_node_group_defaults.security_group_use_name_prefix, true)
  security_group_description        = try(each.value.security_group_description, local.eks_managed_node_group_defaults.security_group_description, "EKS managed node group security group")
  vpc_id                            = try(each.value.vpc_id, local.eks_managed_node_group_defaults.vpc_id, data.aws_eks_cluster.this.vpc_config[0].vpc_id)
  security_group_rules              = try(each.value.security_group_rules, local.eks_managed_node_group_defaults.security_group_rules, {})
  security_group_tags               = try(each.value.security_group_tags, local.eks_managed_node_group_defaults.security_group_tags, {})

  tags = merge(var.tags, try(each.value.tags, local.eks_managed_node_group_defaults.tags, {}))
}

#########################
# Tag Autoscaling Group
#########################
#https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1558#issuecomment-1030640207

resource "aws_autoscaling_group_tag" "cluster_autoscaler_label_tags" {
  for_each = local.cluster_autoscaler_asg_tags

  autoscaling_group_name = each.value.autoscaling_group

  tag {
    key   = each.value.key
    value = each.value.value

    propagate_at_launch = false
  }

  depends_on = [
    module.eks_managed_node_group
  ]
}
