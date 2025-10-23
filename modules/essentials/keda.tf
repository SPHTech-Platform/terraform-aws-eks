resource "helm_release" "keda" {
  count = var.keda_enabled ? 1 : 0

  name       = var.keda_release_name
  chart      = var.keda_chart_name
  repository = var.keda_chart_repository
  version    = var.keda_chart_version

  create_namespace = true
  namespace        = var.keda_namespace

  max_history = 10

  set = [
    {
      name  = "resources.operator.requests.cpu"
      value = var.keda_operator_requests_cpu
    },
    {
      name  = "resources.operator.requests.memory"
      value = var.keda_operator_requests_memory
    },
    {
      name  = "resources.operator.limits.cpu"
      value = var.keda_operator_limits_cpu
    },
    {
      name  = "resources.operator.limits.memory"
      value = var.keda_operator_limits_memory
    },
    {
      name  = "resources.metricServer.requests.cpu"
      value = var.keda_metric_server_requests_cpu
    },
    {
      name  = "resources.metricServer.requests.memory"
      value = var.keda_metric_server_requests_memory
    },
    {
      name  = "resources.metricServer.limits.cpu"
      value = var.keda_metric_server_limits_cpu
    },
    {
      name  = "resources.metricServer.limits.memory"
      value = var.keda_metric_server_limits_memory
    },
    {
      name  = "resources.webhooks.requests.cpu"
      value = var.keda_webhooks_requests_cpu
    },
    {
      name  = "resources.webhooks.requests.memory"
      value = var.keda_webhooks_requests_memory
    },
    {
      name  = "resources.webhooks.limits.cpu"
      value = var.keda_webhooks_limits_cpu
    },
    {
      name  = "resources.webhooks.limits.memory"
      value = var.keda_webhooks_limits_memory
    },
  ]
}
