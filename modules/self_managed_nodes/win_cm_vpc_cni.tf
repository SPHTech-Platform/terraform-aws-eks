locals {
  aws_vpc_cni_configmap_data = {
    enable-windows-ipam = "true"
  }
}

resource "kubernetes_config_map" "amazon_vpc_cni" {
  count = var.enable_cluster_windows_support ? 1 : 0

  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = local.aws_vpc_cni_configmap_data
}
