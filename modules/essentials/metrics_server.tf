locals {
  helm_config = merge(
    var.metrics_server_helm_config_defaults,
    var.metrics_server_helm_config
  )
}

module "helm_metrics_server" {
  count  = var.metrics_server_enabled ? 1 : 0
  source = "github.com/SPHTech-Platform/terraform-helm-release?ref=init"

  helm_config = local.helm_config
}
