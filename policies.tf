locals {
  source_policy_documents = length(var.workers_additional_assume_policy) > 0 ? [
    data.aws_iam_policy_document.ec2_assume_role_policy.json,
    data.aws_iam_policy_document.workers_additional_assume_policy.json
  ] : [data.aws_iam_policy_document.ec2_assume_role_policy.json]
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    sid     = "EKSClusterAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    sid     = "EKSNodeAssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.${data.aws_partition.current.dns_suffix}"]
    }
  }
}

data "aws_iam_policy_document" "workers_additional_assume_policy" {
  # Decode the JSON policy
  source_policy_documents = [var.workers_additional_assume_policy]
}

data "aws_iam_policy_document" "combined_assume_policy" {
  source_policy_documents = local.source_policy_documents
}

# This policy is required for the KMS key used for EKS root volumes, so the cluster is allowed to enc/dec/attach encrypted EBS volumes
data "aws_iam_policy_document" "kms_ebs" {
  # Required for EKS
  #checkov:skip=CKV_AWS_109:The is a resource policy
  #checkov:skip=CKV_AWS_111:The is a resource policy
  #checkov:skip=CKV_AWS_356:Ensure IAM policies limit resource access
  statement {
    sid = "Allow service-linked role use of the CMK"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        local.asg_role,           # required for the ASG to manage encrypted volumes for nodes
        aws_iam_role.cluster.arn, # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }
  }

  statement {
    sid       = "Allow attachment of persistent resources"
    actions   = ["kms:CreateGrant"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        local.asg_role,           # required for the ASG to manage encrypted volumes for nodes
        aws_iam_role.cluster.arn, # required for the cluster / persistentvolume-controller to create encrypted PVCs
      ]
    }

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
  }
}

# Allow EBS CSI to use EBS key
data "aws_iam_policy_document" "kms_csi_ebs" {
  statement {
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
    ]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = ["true"]
    }
    resources = [module.kms_ebs.key_arn]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [module.kms_ebs.key_arn]
  }
}
