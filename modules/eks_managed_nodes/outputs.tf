# output "node_group_resources" {
#   description = "List of objects containing information about underlying resources"
#   value       = module.eks_managed_node_group.node_group_resources
# }

# output "node_group_autoscaling_group_names" {
#   description = "List of the autoscaling group names"
#   value       = module.eks_managed_node_group.node_group_autoscaling_group_names
# }

# output "node_group_status" {
#   description = "Status of the EKS Node Group"
#   value       = module.eks_managed_node_group.node_group_status
# }

output "node_group_labels" {
  description = "Map of labels applied to the node group"
  value       = module.eks_managed_node_group.node_group_labels
}

# output "node_group_taints" {
#   description = "List of objects containing information about taints applied to the node group"
#   value       = module.eks_managed_node_group.node_group_taints
# }
