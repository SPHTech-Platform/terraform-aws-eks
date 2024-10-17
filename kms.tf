module "kms_secret" {
  source  = "SPHTech-Platform/kms/aws"
  version = "~> 0.2.0"

  key_description = "Encrypt Kubernetes secret for EKS Cluster ${var.cluster_name}"
  alias           = "alias/${join("-", [var.cluster_name, "secrets"])}"

  tags = var.tags
}

module "kms_ebs" {
  source  = "SPHTech-Platform/kms/aws"
  version = "~> 0.2.0"

  key_description = "EBS Key for EKS Cluster ${var.cluster_name}"
  alias           = "alias/${join("-", [var.cluster_name, "ebs"])}"
  key_policy_statements = [
    data.aws_iam_policy_document.kms_ebs.json,
  ]

  tags = var.tags
}
