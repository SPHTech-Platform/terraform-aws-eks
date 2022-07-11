locals {
  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  cluster_autoscaler_label_tags = {
    for name, group in local.eks_managed_node_groups : name => {
      for label_name, label_value in try(group.labels, {}) : "k8s.io/cluster-autoscaler/node-template/label/${label_name}" => label_value
    }
  }

  cluster_autoscaler_taint_tags = {
    for name, group in local.eks_managed_node_groups : name => {
      for taint in try(group.taints, {}) : "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}" => "${taint.value}:${local.taint_effects[taint.effect]}"
    }
  }

  cluster_autoscaler_implicit_tags = {
    for name, group in local.eks_managed_node_groups : name => merge(
      length(try(group.instance_types, local.eks_managed_node_group_defaults.instance_types)) == 1 ? {
        "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type" = one(try(group.instance_types, local.eks_managed_node_group_defaults.instance_types))
      } : {},
      length(data.aws_autoscaling_group.node_groups[name].availability_zones) == 1 ? {
        "k8s.io/cluster-autoscaler/node-template/label/topology.ebs.csi.aws.com/zone" = one(data.aws_autoscaling_group.node_groups[name].availability_zones)
      } : {},
      length(data.aws_autoscaling_group.node_groups[name].availability_zones) == 1 ? {
        "k8s.io/cluster-autoscaler/node-template/label/topology.kubernetes.io/zone" = one(data.aws_autoscaling_group.node_groups[name].availability_zones)
      } : {},
    )
  }

  cluster_autoscaler_asg_tags = {
    for name, group in local.eks_managed_node_groups : name => merge(
      local.cluster_autoscaler_label_tags[name],
      local.cluster_autoscaler_taint_tags[name],
      local.cluster_autoscaler_implicit_tags[name],
    )
  }
}

#########################
# Tag Autoscaling Group
#########################
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/1558#issuecomment-1030640207
resource "aws_autoscaling_group_tag" "cluster_autoscaler" {
  # Create a tuple in a map for each ASG tags
  for_each = merge([
    for name, tags in local.cluster_autoscaler_asg_tags : {
      for tag_key, tag_value in tags : "${name}-${substr(tag_key, 26, -1)}" => {
        group = name,
        key   = tag_key,
        value = tag_value,
      }
    }
  ]...)

  # Lookup the ASG name for the managed node groups, erroring if there is more than one
  autoscaling_group_name = one(module.eks_managed_node_group[each.value.group].node_group_autoscaling_group_names)

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = false
  }
}
