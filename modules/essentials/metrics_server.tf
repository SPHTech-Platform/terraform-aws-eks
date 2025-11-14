locals {
  metric_server_helm_config = merge(
    var.metrics_server_helm_config_defaults,
    var.metrics_server_helm_config,
    local.namespace
  )

  namespace = var.fargate_mix_node_groups || var.fargate_cluster ? {
    create_namespace = true
    namespace        = "metrics-server"
  } : { namespace = "kube-system" }
}

module "helm_metrics_server" {
  count = var.metrics_server_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.3.0"

  helm_config = local.metric_server_helm_config
}
