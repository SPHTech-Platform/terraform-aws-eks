locals {
  name = "metrics-server"

  default_helm_config = {
    name        = local.name
    chart       = local.name
    repository  = "https://kubernetes-sigs.github.io/metrics-server/"
    version     = "3.8.2"
    namespace   = "kube-system"
    description = "Metric server helm Chart deployment configuration"
  }

  helm_config = merge(
    local.default_helm_config,
    var.metrics_server_helm_config
  )
}

module "helm_metrics_server" {
  count  = var.metrics_server_enabled ? 1 : 0
  source = "github.com/SPHTech-Platform/terraform-helm-release?ref=init"

  helm_config = local.helm_config
}
