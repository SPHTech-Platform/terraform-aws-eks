###########
# IAM Role
###########
output "iam_role_name" {
  description = "Map of the name of the IAM role"
  value = {
    for k, v in module.fargate_profile : k => v.iam_role_name
  }
}

output "iam_role_arn" {
  description = "Map of The Amazon Resource Name (ARN) specifying the IAM role"
  value = {
    for k, v in module.fargate_profile : k => v.iam_role_arn
  }
}

output "iam_role_unique_id" {
  description = "Map of Stable and unique string identifying the IAM role"
  value = {
    for k, v in module.fargate_profile : k => v.iam_role_unique_id
  }
}

##################
# Fargate Profile
##################

output "fargate_profile_arn" {
  description = "Map of Amazon Resource Name (ARN) of the EKS Fargate Profile"
  value = {
    for k, v in module.fargate_profile : k => v.fargate_profile_arn
  }
}

output "fargate_profile_id" {
  description = "Map of EKS Cluster name and EKS Fargate Profile name separated by a colon (`:`)"
  value = {
    for k, v in module.fargate_profile : k => v.fargate_profile_id
  }
}

output "fargate_profile_status" {
  description = "Map of Status of the EKS Fargate Profile"
  value = {
    for k, v in module.fargate_profile : k => v.fargate_profile_status
  }
}

output "fargate_profile_pod_execution_role_arn" {
  description = "Map of Amazon Resource Name (ARN) of the EKS Fargate Profile Pod execution role ARN"
  value = {
    for k, v in module.fargate_profile : k => v.fargate_profile_pod_execution_role_arn
  }
}
