locals {
  node_exporter_helm_config = merge(
    var.node_exporter_helm_config_defaults,
    var.node_exporter_helm_config,
    {
      values = [
        yamlencode(local.node_affinity),
      ]
    },
  )
  node_affinity = {
    affinity = {
      nodeAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = {
          nodeSelectorTerms = [
            {
              matchExpressions = [
                {
                  key      = "eks.amazonaws.com/compute-type"
                  operator = "NotIn"
                  values   = ["fargate"]
                },
              ]
            },
          ]
        }
      }
    }
  }
}

module "helm_node_exporter" {
  count = var.node_exporter_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.1.4"

  helm_config = local.node_exporter_helm_config

  set_values = [
    {
      name  = "service.ipDualStack.enabled"
      value = var.ip_dual_stack_enabled ? true : false
    },
  ]
}
