locals {
  node_group_autoscaling_group_names = {
    for k, v in module.eks_managed_node_group : k => v.node_group_autoscaling_group_names
  }

  node_group_labels = {
    for k, v in module.eks_managed_node_group : k => v.node_group_labels
  }

  node_group_taints = {
    for k, v in module.eks_managed_node_group : k => v.node_group_taints
  }

  cluster_autoscaler_label_tags = merge([

    for group, asg in local.node_group_autoscaling_group_names : {
      for label_name, label_value in local.node_group_labels[group] : "${group}|label|${label_name}" => {
        autoscaling_group = asg[0],
        key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
        value             = label_value,
      }
    }
  ]...)

  cluster_autoscaler_taint_tags = merge([
    for group, asg in local.node_group_autoscaling_group_names : {
      for taint in local.node_group_taints[group] : "${group}|taint|${taint.key}" => {
        autoscaling_group = asg[0],
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
}
