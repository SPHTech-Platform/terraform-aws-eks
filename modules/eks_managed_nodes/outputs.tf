output "node_group_resources" {
  description = "Map of objects containing information about underlying resources"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_resources
  }
}

output "node_group_autoscaling_group_names" {
  description = "Map of the autoscaling group names"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_autoscaling_group_names
  }
}

output "node_group_status" {
  description = "Map of EKS Node Group status"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_status
  }
}

output "node_group_labels" {
  description = "Map of labels applied to each node group"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_labels
  }
}

output "node_group_taints" {
  description = "Map objects containing information about taints applied to each node group"
  value = {
    for k, v in module.eks_managed_node_group : k => v.node_group_taints
  }
}

output "autoscaling_group_tags" {
  description = "Tags applied to autoscaling groups"
  value       = local.cluster_autoscaler_asg_tags
}

output "eks_managed_node_groups" {
  description = "EKS managed node groups"
  value       = local.eks_managed_node_groups
}
