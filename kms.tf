module "kms_secret" {
  source  = "SPHTech-Platform/kms/aws"
  version = "~> 1.0"

  region = var.region

  key_description = "Encrypt Kubernetes secret for EKS Cluster ${var.name}"
  alias           = "alias/${join("-", [var.name, "secrets"])}"

  tags = var.tags
}

module "kms_ebs" {
  source  = "SPHTech-Platform/kms/aws"
  version = "~> 1.0"

  region = var.region

  key_description = "EBS Key for EKS Cluster ${var.name}"
  alias           = "alias/${join("-", [var.name, "ebs"])}"
  key_policy_statements = [
    data.aws_iam_policy_document.kms_ebs.json,
  ]

  tags = var.tags
}
