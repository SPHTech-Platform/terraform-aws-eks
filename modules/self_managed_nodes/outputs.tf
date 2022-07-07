output "autoscaling_group_name" {
  description = "The autoscaling group name"
  value       = values(module.self_managed_group)[*].autoscaling_group_name
}
