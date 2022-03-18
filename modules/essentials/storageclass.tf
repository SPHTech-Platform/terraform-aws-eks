resource "kubernetes_storage_class" "default" {
  metadata {
    name = var.csi_storage_class

    annotations = merge({
      "storageclass.kubernetes.io/is-default-class" = "true"
      },
      var.kubernetes_annotations,
    )
    labels = var.kubernetes_labels
  }

  storage_provisioner    = "ebs.csi.aws.com"
  reclaim_policy         = var.csi_reclaim_policy
  volume_binding_mode    = var.csi_volume_binding_mode
  allow_volume_expansion = var.csi_allow_volume_expansion

  parameters = merge({
    "csi.storage.k8s.io/fstype" = "ext4"
    type                        = "gp3"
    encrypted                   = var.csi_encryption_key_id != "" && var.csi_encryption_key_id != null ? "true" : "false"
    kmsKeyId                    = var.csi_encryption_key_id
  }, var.csi_parameters_override)
}

# Unmark the other StorageClass as default
locals {
  kubeconfig = yamlencode({
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    clusters = [{
      name = var.cluster_name
      cluster = {
        certificate-authority-data = data.aws_eks_cluster.this.certificate_authority[0].data
        server                     = data.aws_eks_cluster.this.endpoint
      }
    }]
    contexts = [{
      name = "terraform"
      context = {
        cluster = var.cluster_name
        user    = "terraform"
      }
    }]
    users = [{
      name = "terraform"
      user = {
        token = data.aws_eks_cluster_auth.this.token
      }
    }]
  })
}

resource "null_resource" "patch_storageclass" {
  triggers = {
    cmd_patch = <<-EOT
      kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' --kubeconfig <(echo $KUBECONFIG | base64 --decode)
    EOT
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = base64encode(local.kubeconfig)
    }
    command = self.triggers.cmd_patch
  }
}
