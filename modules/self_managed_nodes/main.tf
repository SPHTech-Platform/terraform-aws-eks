locals {
  self_managed_node_group_defaults = merge({
    create_iam_instance_profile = false
    iam_instance_profile_arn    = var.worker_iam_instance_profile_arn

    tags = merge({
      "k8s.io/cluster-autoscaler/enabled"             = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "true"

      "aws-node-termination-handler/managed" = "true"
      },
      lookup(var.self_managed_node_group_defaults, "tags", {}),
    )
  }, var.self_managed_node_group_defaults)

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = var.force_imdsv2 ? "required" : "optional"
    http_put_response_hop_limit = var.force_imdsv2 && var.force_irsa ? 1 : 2
    instance_metadata_tags      = "disabled"
    http_protocol_ipv6          = var.cluster_ip_family == "ipv6" ? "enabled" : "disabled"
  }

  # Cartesian product of node groups and individual subnets
  # Multiple copies of each node group will be created with each subnet
  # defined in the original variable
  self_managed_node_groups = merge([for name, group in var.self_managed_node_groups : {
    for subnet in try(group.subnet_ids, local.self_managed_node_group_defaults.subnet_ids, data.aws_eks_cluster.this.vpc_config[0].subnet_ids) : "${name}-${subnet}" => merge(
      group,
      {
        name       = "${try(group.name, name, "unnamed")}-${data.aws_subnet.subnets[subnet].availability_zone}"
        subnet_ids = [subnet]

        # Tags for AutoScaler to scale from zero for CSI: See https://github.com/kubernetes/autoscaler/issues/3845
        tags = merge(
          local.self_managed_node_group_defaults.tags,
          try(group.tags, {}),
          {
            "k8s.io/cluster-autoscaler/node-template/label/topology.kubernetes.io/zone" = data.aws_subnet.subnets[subnet].availability_zone
          },
          {
            "k8s.io/cluster-autoscaler/node-template/label/bottlerocket.aws/updater-interface-version" = "2.2.0"
          },
          # Handle Spot
          try(group.instance_market_options.market_type, false) == "spot" ? {
            "k8s.io/cluster-autoscaler/node-template/label/lifecycle"           = "spot"
            "k8s.io/cluster-autoscaler/node-template/label/aws.amazon.com/spot" = "true"
          } : {},
          # Allow only critical addons for default node group
          try(group.only_critical_addons_enabled, false) ? {
            "k8s.io/cluster-autoscaler/node-template/taint/CriticalAddonsOnly" = "true:NoSchedule"
          } : {},
        )
      },
    )
  }]...)
}

module "self_managed_group" {
  source  = "terraform-aws-modules/eks/aws//modules/self-managed-node-group"
  version = "~> 19.21.0"

  for_each = local.self_managed_node_groups

  cluster_name      = var.cluster_name
  cluster_ip_family = var.cluster_ip_family

  # Autoscaling Group
  name            = try(each.value.name, each.key)
  use_name_prefix = try(each.value.use_name_prefix, local.self_managed_node_group_defaults.use_name_prefix, true)

  availability_zones = try(each.value.availability_zones, local.self_managed_node_group_defaults.availability_zones, null)
  subnet_ids         = each.value.subnet_ids

  min_size                  = try(each.value.min_size, local.self_managed_node_group_defaults.min_size, 0)
  max_size                  = try(each.value.max_size, local.self_managed_node_group_defaults.max_size, 3)
  desired_size              = try(each.value.desired_size, local.self_managed_node_group_defaults.desired_size, 1)
  capacity_rebalance        = try(each.value.capacity_rebalance, local.self_managed_node_group_defaults.capacity_rebalance, null)
  min_elb_capacity          = try(each.value.min_elb_capacity, local.self_managed_node_group_defaults.min_elb_capacity, null)
  wait_for_elb_capacity     = try(each.value.wait_for_elb_capacity, local.self_managed_node_group_defaults.wait_for_elb_capacity, null)
  wait_for_capacity_timeout = try(each.value.wait_for_capacity_timeout, local.self_managed_node_group_defaults.wait_for_capacity_timeout, null)
  default_cooldown          = try(each.value.default_cooldown, local.self_managed_node_group_defaults.default_cooldown, null)
  protect_from_scale_in     = try(each.value.protect_from_scale_in, local.self_managed_node_group_defaults.protect_from_scale_in, null)

  target_group_arns         = try(each.value.target_group_arns, local.self_managed_node_group_defaults.target_group_arns, null)
  placement_group           = try(each.value.placement_group, local.self_managed_node_group_defaults.placement_group, null)
  health_check_type         = try(each.value.health_check_type, local.self_managed_node_group_defaults.health_check_type, null)
  health_check_grace_period = try(each.value.health_check_grace_period, local.self_managed_node_group_defaults.health_check_grace_period, null)

  force_delete          = try(each.value.force_delete, local.self_managed_node_group_defaults.force_delete, null)
  termination_policies  = try(each.value.termination_policies, local.self_managed_node_group_defaults.termination_policies, [])
  suspended_processes   = try(each.value.suspended_processes, local.self_managed_node_group_defaults.suspended_processes, [])
  max_instance_lifetime = try(each.value.max_instance_lifetime, local.self_managed_node_group_defaults.max_instance_lifetime, null)

  enabled_metrics         = try(each.value.enabled_metrics, local.self_managed_node_group_defaults.enabled_metrics, [])
  metrics_granularity     = try(each.value.metrics_granularity, local.self_managed_node_group_defaults.metrics_granularity, null)
  service_linked_role_arn = try(each.value.service_linked_role_arn, local.self_managed_node_group_defaults.service_linked_role_arn, null)

  initial_lifecycle_hooks    = try(each.value.initial_lifecycle_hooks, local.self_managed_node_group_defaults.initial_lifecycle_hooks, [])
  instance_refresh           = try(each.value.instance_refresh, local.self_managed_node_group_defaults.instance_refresh, {})
  use_mixed_instances_policy = try(each.value.use_mixed_instances_policy, local.self_managed_node_group_defaults.use_mixed_instances_policy, false)
  mixed_instances_policy     = try(each.value.mixed_instances_policy, local.self_managed_node_group_defaults.mixed_instances_policy, null)
  warm_pool                  = try(each.value.warm_pool, local.self_managed_node_group_defaults.warm_pool, {})

  create_schedule = try(each.value.create_schedule, local.self_managed_node_group_defaults.create_schedule, false)
  schedules       = try(each.value.schedules, local.self_managed_node_group_defaults.schedules, null)

  delete_timeout = try(each.value.delete_timeout, local.self_managed_node_group_defaults.delete_timeout, null)

  # User data
  platform                 = try(each.value.platform, local.self_managed_node_group_defaults.platform, "linux")
  cluster_endpoint         = try(data.aws_eks_cluster.this.endpoint, "")
  cluster_auth_base64      = try(data.aws_eks_cluster.this.certificate_authority[0].data, "")
  pre_bootstrap_user_data  = try(each.value.pre_bootstrap_user_data, local.self_managed_node_group_defaults.pre_bootstrap_user_data, "")
  post_bootstrap_user_data = try(each.value.post_bootstrap_user_data, local.self_managed_node_group_defaults.post_bootstrap_user_data, "")
  bootstrap_extra_args     = try(each.value.bootstrap_extra_args, local.self_managed_node_group_defaults.bootstrap_extra_args, "")
  user_data_template_path  = try(each.value.user_data_template_path, local.self_managed_node_group_defaults.user_data_template_path, "")

  # Launch Template
  create_launch_template          = try(each.value.create_launch_template, local.self_managed_node_group_defaults.create_launch_template, true)
  launch_template_name            = try(each.value.launch_template_name, each.key)
  launch_template_use_name_prefix = try(each.value.launch_template_use_name_prefix, local.self_managed_node_group_defaults.launch_template_use_name_prefix, true)
  launch_template_version         = try(each.value.launch_template_version, local.self_managed_node_group_defaults.launch_template_version, null)
  launch_template_description     = try(each.value.launch_template_description, local.self_managed_node_group_defaults.launch_template_description, "Custom launch template for ${try(each.value.name, each.key)} self managed node group")
  launch_template_tags            = try(each.value.launch_template_tags, local.self_managed_node_group_defaults.launch_template_tags, {})

  autoscaling_group_tags = try(each.value.autoscaling_group_tags, local.self_managed_node_group_defaults.autoscaling_group_tags, {})

  ebs_optimized   = try(each.value.ebs_optimized, local.self_managed_node_group_defaults.ebs_optimized, null)
  ami_id          = try(each.value.ami_id, local.self_managed_node_group_defaults.ami_id, "")
  cluster_version = try(each.value.cluster_version, local.self_managed_node_group_defaults.cluster_version, data.aws_eks_cluster.this.version)
  instance_type   = try(each.value.instance_type, local.self_managed_node_group_defaults.instance_type, "m6i.large")
  key_name        = try(each.value.key_name, local.self_managed_node_group_defaults.key_name, null)

  vpc_security_group_ids                 = compact(concat([var.worker_security_group_id], try(each.value.vpc_security_group_ids, local.self_managed_node_group_defaults.vpc_security_group_ids, [])))
  launch_template_default_version        = try(each.value.launch_template_default_version, local.self_managed_node_group_defaults.launch_template_default_version, null)
  update_launch_template_default_version = try(each.value.update_launch_template_default_version, local.self_managed_node_group_defaults.update_launch_template_default_version, true)
  disable_api_termination                = try(each.value.disable_api_termination, local.self_managed_node_group_defaults.disable_api_termination, null)
  instance_initiated_shutdown_behavior   = try(each.value.instance_initiated_shutdown_behavior, local.self_managed_node_group_defaults.instance_initiated_shutdown_behavior, null)
  kernel_id                              = try(each.value.kernel_id, local.self_managed_node_group_defaults.kernel_id, null)
  ram_disk_id                            = try(each.value.ram_disk_id, local.self_managed_node_group_defaults.ram_disk_id, null)

  block_device_mappings              = try(each.value.block_device_mappings, local.self_managed_node_group_defaults.block_device_mappings, [])
  capacity_reservation_specification = try(each.value.capacity_reservation_specification, local.self_managed_node_group_defaults.capacity_reservation_specification, {})
  cpu_options                        = try(each.value.cpu_options, local.self_managed_node_group_defaults.cpu_options, {})
  credit_specification               = try(each.value.credit_specification, local.self_managed_node_group_defaults.credit_specification, {})
  elastic_gpu_specifications         = try(each.value.elastic_gpu_specifications, local.self_managed_node_group_defaults.elastic_gpu_specifications, {})
  elastic_inference_accelerator      = try(each.value.elastic_inference_accelerator, local.self_managed_node_group_defaults.elastic_inference_accelerator, {})
  enclave_options                    = try(each.value.enclave_options, local.self_managed_node_group_defaults.enclave_options, {})
  hibernation_options                = try(each.value.hibernation_options, local.self_managed_node_group_defaults.hibernation_options, {})
  instance_market_options            = try(each.value.instance_market_options, local.self_managed_node_group_defaults.instance_market_options, {})
  license_specifications             = try(each.value.license_specifications, local.self_managed_node_group_defaults.license_specifications, {})
  metadata_options                   = try(each.value.metadata_options, local.self_managed_node_group_defaults.metadata_options, local.metadata_options)
  enable_monitoring                  = try(each.value.enable_monitoring, local.self_managed_node_group_defaults.enable_monitoring, true)
  network_interfaces                 = try(each.value.network_interfaces, local.self_managed_node_group_defaults.network_interfaces, [])
  placement                          = try(each.value.placement, local.self_managed_node_group_defaults.placement, {})

  # IAM role
  create_iam_instance_profile   = try(each.value.create_iam_instance_profile, local.self_managed_node_group_defaults.create_iam_instance_profile, true)
  iam_instance_profile_arn      = try(each.value.iam_instance_profile_arn, local.self_managed_node_group_defaults.iam_instance_profile_arn, null)
  iam_role_name                 = try(each.value.iam_role_name, local.self_managed_node_group_defaults.iam_role_name, null)
  iam_role_use_name_prefix      = try(each.value.iam_role_use_name_prefix, local.self_managed_node_group_defaults.iam_role_use_name_prefix, true)
  iam_role_path                 = try(each.value.iam_role_path, local.self_managed_node_group_defaults.iam_role_path, null)
  iam_role_description          = try(each.value.iam_role_description, local.self_managed_node_group_defaults.iam_role_description, "Self managed node group IAM role")
  iam_role_permissions_boundary = try(each.value.iam_role_permissions_boundary, local.self_managed_node_group_defaults.iam_role_permissions_boundary, null)
  iam_role_tags                 = try(each.value.iam_role_tags, local.self_managed_node_group_defaults.iam_role_tags, {})
  iam_role_attach_cni_policy    = try(each.value.iam_role_attach_cni_policy, local.self_managed_node_group_defaults.iam_role_attach_cni_policy, true)
  iam_role_additional_policies  = try(each.value.iam_role_additional_policies, local.self_managed_node_group_defaults.iam_role_additional_policies, {})

  tags = merge(var.tags, try(each.value.tags, local.self_managed_node_group_defaults.tags, {}))
}
