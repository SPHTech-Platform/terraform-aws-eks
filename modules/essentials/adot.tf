resource "aws_eks_addon" "adot_operator" {
  cluster_name = var.cluster_name
  addon_name   = "adot"

  depends_on = [
    helm_release.cert_manager,
  ]
}
