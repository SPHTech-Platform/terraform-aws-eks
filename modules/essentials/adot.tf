data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_addon_version" "latest_adot" {
  addon_name         = "adot"
  kubernetes_version = data.aws_eks_cluster.cluster.version
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
