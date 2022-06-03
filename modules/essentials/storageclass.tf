resource "kubernetes_storage_class" "default" {
  count = var.csi_default_storage_class ? 1 : 0

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

# Unmark the gp2 StorageClass as default
resource "kubectl_manifest" "gp2_storage_class" {
  count = var.csi_default_storage_class ? 1 : 0
  depends_on = [
    kubernetes_storage_class.default,
  ]

  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      annotations = {
        "storageclass.kubernetes.io/is-default-class" = "false"
      }
      name = "gp2"
    }
    parameters = {
      fsType = "ext4"
      type   = "gp2"
    }
    provisioner       = "kubernetes.io/aws-ebs"
    reclaimPolicy     = "Delete"
    volumeBindingMode = "WaitForFirstConsumer"
  })

  server_side_apply = true
  force_conflicts   = true
  apply_only        = true
}
