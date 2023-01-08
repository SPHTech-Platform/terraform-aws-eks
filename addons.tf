# Need IRSA
# See https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/examples/iam-role-for-service-accounts-eks/main.tf
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_name
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"

  preserve = true

  tags = var.tags
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on = [
    aws_eks_addon.kube_proxy
  ]

  cluster_name      = module.eks.cluster_name
  addon_name        = "vpc-cni"
  resolve_conflicts = "NONE"

  preserve = true

  service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  cluster_name      = module.eks.cluster_name
  addon_name        = "coredns"
  resolve_conflicts = "NONE"

  preserve = true

  tags = var.tags
}

resource "aws_eks_addon" "ebs_csi" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  cluster_name      = module.eks.cluster_name
  addon_name        = "aws-ebs-csi-driver"
  resolve_conflicts = "NONE"

  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn

  preserve = true

  tags = var.tags
}
