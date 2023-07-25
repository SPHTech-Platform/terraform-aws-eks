data "aws_eks_addon_version" "latest_adot" {
  addon_name         = "adot"
  kubernetes_version = var.k8s_version_to_set_for_adot
  most_recent        = true
}

resource "aws_eks_addon" "adot_operator" {
  cluster_name  = var.cluster_name
  addon_name    = "adot"
  addon_version = try(var.adot_addon_version, data.aws_eks_addon_version.latest_adot.version)

  depends_on = [
    helm_release.cert_manager,
  ]
}
