locals {
  aws_auth_configmap_data = {
    enable-windows-ipam = "true"
  }
}

resource "kubernetes_config_map" "amazon-vpc-cni" {
  count = var.create_aws_auth_configmap ? 1 : 0

  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data

  lifecycle {
    # We are ignoring the data here since we will manage it with the resource below
    # This is only intended to be used in scenarios where the configmap does not exist
    ignore_changes = [data]
  }
}
