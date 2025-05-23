locals {
  cluster_version_parts = split(".", data.aws_eks_cluster.cluster.version)

  # Calculate the previous minor version string (e.g., "1.29" -> "1.28")
  target_eks_version = "${local.cluster_version_parts[0]}.${tostring(tonumber(local.cluster_version_parts[1]) - 1)}"
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_addon_version" "latest_adot" {
  addon_name         = "adot"
  kubernetes_version = local.target_eks_version
  most_recent        = true
}

resource "aws_eks_addon" "adot_operator" {
  cluster_name = var.cluster_name
  addon_name   = "adot"

  addon_version        = coalesce(try(var.adot_addon.addon_version, null), data.aws_eks_addon_version.latest_adot.version)
  configuration_values = try(var.adot_addon.configuration_values, null)

  dynamic "pod_identity_association" {
    for_each = try(var.adot_addon.pod_identity_association, [])

    content {
      role_arn        = pod_identity_association.value.role_arn
      service_account = pod_identity_association.value.service_account
    }
  }

  preserve = try(var.adot_addon.preserve, true)

  resolve_conflicts_on_create = try(var.adot_addon.resolve_conflicts_on_create, var.resolve_conflicts_on_create)
  resolve_conflicts_on_update = try(var.adot_addon.resolve_conflicts_on_update, var.resolve_conflicts_on_update)

  service_account_role_arn = try(var.adot_addon.service_account_role_arn, null)

  timeouts {
    create = try(var.adot_addon.timeouts.create, null)
    update = try(var.adot_addon.timeouts.update, null)
    delete = try(var.adot_addon.timeouts.delete, null)
  }

  depends_on = [
    helm_release.cert_manager,
  ]
}
