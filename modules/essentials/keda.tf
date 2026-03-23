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

module "keda_fargate_profile" {
  count = var.keda_enabled && var.fargate_cluster ? 1 : 0

  source = "../fargate_profile"

  create_aws_observability_ns     = var.create_aws_observability_ns_for_keda
  create_fargate_logger_configmap = var.create_fargate_logger_configmap_for_keda
  create_fargate_log_group        = var.create_fargate_log_group_for_keda
  create_fargate_logging_policy   = var.create_fargate_logging_policy_for_keda
  cluster_name                    = var.cluster_name
  fargate_profiles = {
    keda = {
      iam_role_name = "${var.cluster_name}-fargate-profile-keda"
      subnet_ids    = length(var.subnet_ids) > 0 ? var.subnet_ids : data.aws_subnets.this.ids
      selectors = [
        {
          namespace = var.keda_namespace
        }
      ]
    }
  }

  fargate_namespaces_for_security_group = [var.keda_namespace]
  eks_worker_security_group_id          = var.node_security_group_id
}
