# Need IRSA
# See https://github.com/terraform-aws-modules/terraform-aws-iam/blob/master/examples/iam-role-for-service-accounts-eks/main.tf
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = module.eks.cluster_id
  addon_name        = "kube-proxy"
  resolve_conflicts = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni" {
  depends_on = [
    aws_eks_addon.kube_proxy
  ]

  cluster_name      = module.eks.cluster_id
  addon_name        = "vpc-cni"
  resolve_conflicts = "NONE"

  service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
}

resource "aws_eks_addon" "coredns" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  cluster_name      = module.eks.cluster_id
  addon_name        = "coredns"
  resolve_conflicts = "NONE"
}

resource "aws_eks_addon" "ebs_csi" {
  depends_on = [
    aws_eks_addon.vpc_cni
  ]

  cluster_name      = module.eks.cluster_id
  addon_name        = "aws-ebs-csi-driver"
  resolve_conflicts = "NONE"

  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
}
