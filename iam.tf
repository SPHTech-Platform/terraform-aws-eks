locals {
  account_id        = data.aws_caller_identity.current.account_id
  policy_arn_prefix = "arn:${data.aws_partition.current.partition}:iam::aws:policy"

  # Force depdendence on aws_iam_service_linked_role resources
  asg_role = var.skip_asg_role ? (
    "arn:aws:iam::${local.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
    ) : (
    "arn:aws:iam::${local.account_id}:role/aws-service-role/${aws_iam_service_linked_role.autoscaling[0].aws_service_name}/AWSServiceRoleForAutoScaling"
  )
}

# Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name        = coalesce(var.cluster_iam_role, var.cluster_name)
  description = "IAM Role for the EKS Cluster named ${var.cluster_name}"

  assume_role_policy    = data.aws_iam_policy_document.eks_assume_role_policy.json
  permissions_boundary  = var.cluster_iam_boundary
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  for_each = toset([
    "${local.policy_arn_prefix}/AmazonEKSClusterPolicy",
    "${local.policy_arn_prefix}/AmazonEKSVPCResourceController",
  ])

  policy_arn = each.key
  role       = aws_iam_role.cluster.name
}

# Workers IAM Role
resource "aws_iam_role" "workers" {
  name        = coalesce(var.workers_iam_role, "${var.cluster_name}-workers")
  description = "IAM Role for the workers in EKS Cluster named ${var.cluster_name}"

  assume_role_policy    = data.aws_iam_policy_document.ec2_assume_role_policy.json
  permissions_boundary  = var.workers_iam_boundary
  force_detach_policies = true

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "workers" {
  for_each = setunion(toset([
    "${local.policy_arn_prefix}/AmazonEKSWorkerNodePolicy",
    "${local.policy_arn_prefix}/AmazonEC2ContainerRegistryReadOnly",
    "${local.policy_arn_prefix}/AmazonSSMManagedInstanceCore",
    "${local.policy_arn_prefix}/AmazonEKS_CNI_Policy",
  ]), var.iam_role_additional_policies)

  policy_arn = each.value
  role       = aws_iam_role.workers.name
}

# Activate role for ASG
resource "aws_iam_service_linked_role" "autoscaling" {
  count = !var.skip_asg_role ? 1 : 0

  aws_service_name = "autoscaling.amazonaws.com"
}

############################
# IRSA for addon components
############################
module "vpc_cni_irsa_role" {
  count = !var.enable_pod_identity ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.11.2"

  role_name_prefix = "${var.cluster_name}-cni-"
  role_description = "EKS Cluster ${var.cluster_name} VPC CNI Addon"

  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = var.cluster_ip_family == "ipv4" ? "true" : "false"
  vpc_cni_enable_ipv6   = var.cluster_ip_family == "ipv6" ? "true" : "false"

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.tags
}

module "ebs_csi_irsa_role" {
  count = !var.enable_pod_identity ? 1 : 0

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.11.2"

  role_name_prefix = "${var.cluster_name}-ebs-csi-"
  role_description = "EKS Cluster ${var.cluster_name} EBS CSI Addon"

  attach_ebs_csi_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

resource "aws_iam_role_policy" "ebs_csi_kms" {
  count = !var.enable_pod_identity ? 1 : 0

  name_prefix = "kms"
  role        = module.ebs_csi_irsa_role[0].iam_role_name

  policy = data.aws_iam_policy_document.kms_csi_ebs.json
}

####################################
## Pod Identity Roles for Add-ons ##
####################################
module "aws_vpc_cni_pod_identity" {
  count = var.enable_pod_identity ? 1 : 0

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.5.0"

  name = "aws-vpc-cni-${var.cluster_ip_family}"

  attach_aws_vpc_cni_policy = true
  aws_vpc_cni_enable_ipv4   = var.cluster_ip_family == "ipv4" ? "true" : "false"
  aws_vpc_cni_enable_ipv6   = var.cluster_ip_family == "ipv6" ? "true" : "false"

  # Pod Identity Associations
  association_defaults = {
    namespace       = "kube-system"
    service_account = "aws-node"
  }

  tags = var.tags
}

module "aws_ebs_csi_pod_identity" {
  count = var.enable_pod_identity ? 1 : 0

  source  = "terraform-aws-modules/eks-pod-identity/aws"
  version = "~> 1.5.0"

  name = "aws-ebs-csi"

  attach_aws_ebs_csi_policy = true
  aws_ebs_csi_kms_arns = [
    module.kms_ebs.key_arn,
  ]
  # Pod Identity Associations
  association_defaults = {
    namespace       = "kube-system"
    service_account = "ebs-csi-controller-sa"
  }

  tags = var.tags
}
