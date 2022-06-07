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

output "worker_iam_instance_profile_arn" {
  description = "IAM Instance Profile ARN to use for worker nodes"
  value       = aws_iam_instance_profile.workers.arn
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
  value       = module.eks.cluster_id
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

output "node_termination_handler_sqs_arn" {
  description = "ARN of the SQS queue used to handle node termination events"
  value       = module.node_termination_handler_sqs.sqs_queue_arn
}
