output "fargate_profile_pod_execution_role_arn" {
  description = "Fargate Profile pod execution role ARN"
  value       = module.karpenter_fargate_profile.fargate_profile_pod_execution_role_arn
}
