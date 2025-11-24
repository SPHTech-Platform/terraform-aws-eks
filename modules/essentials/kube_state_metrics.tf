locals {
  kube_state_metrics_helm_config = merge(
    var.kube_state_metrics_helm_config_defaults,
    var.kube_state_metrics_helm_config,
  )
}

module "helm_kube_state_metrics" {
  count = var.kube_state_metrics_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.3.0"

  helm_config = local.kube_state_metrics_helm_config

  set_values = [
    {
      name  = "selfMonitor.enabled"
      value = true
    },
    {
      name  = "service.ipDualStack.enabled"
      value = var.ip_dual_stack_enabled ? true : false
    },
  ]
}
