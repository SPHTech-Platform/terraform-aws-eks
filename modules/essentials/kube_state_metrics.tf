locals {
  kube_state_metrics_helm_config = merge(
    var.kube_state_metrics_helm_config_defaults,
    var.kube_state_metrics_helm_config,
  )
}

module "helm_kube_state_metrics" {
  count = var.kube_state_metrics_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.1.4"

  helm_config = local.kube_state_metrics_helm_config
}
