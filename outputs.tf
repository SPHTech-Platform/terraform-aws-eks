output "cluster_iam_role_arn" {
  description = "IAM Role ARN used by cluster"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "IAM Role Name used by Cluster"
  value       = aws_iam_role.cluster.name
}

output "worker_iam_role_arn" {
  description = "IAM Role ARN used by worker nodes"
  value       = aws_iam_role.workers.arn
}

output "worker_iam_role_name" {
  description = "IAM Role Name used by worker nodes"
  value       = aws_iam_role.workers.name
}

output "cluster_security_group_id" {
  description = "Security Group ID of the master nodes"
  value       = module.eks.cluster_security_group_id
}

output "worker_security_group_id" {
  description = "Security Group ID of the worker nodes"
  value       = module.eks.node_security_group_id
}

output "oidc_provider_arn" {
  description = "OIDC Provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_name" {
  description = "EKS Cluster name created"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "The ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS Cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 Encoded Cluster CA Data"
  value       = module.eks.cluster_certificate_authority_data
}

output "ebs_kms_key_id" {
  description = "KMS Key ID used for EBS encryption"
  value       = module.kms_ebs.key_id
}

output "ebs_kms_key_arn" {
  description = "KMS Key ARN used for EBS encryption"
  value       = module.kms_ebs.key_arn
}

output "cluster_platform_version" {
  description = "Platform version of the EKS Cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_version" {
  description = "Version of the EKS Cluster"
  value       = module.eks.cluster_version
}

output "fargate_namespaces_for_security_group" {
  description = "value for fargate_namespaces_for_security_group"
  value       = local.fargate_namespaces
}
