locals {
  metric_server_helm_config = merge(
    var.metrics_server_helm_config_defaults,
    var.metrics_server_helm_config
  )
}

module "helm_metrics_server" {
  count = var.metrics_server_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.1.4"

  helm_config = local.metric_server_helm_config
}
