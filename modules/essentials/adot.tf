resource "aws_eks_addon" "adot_operator" {
  cluster_name                = var.cluster_name
  addon_name                  = "adot"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    helm_release.cert_manager,
  ]
}
