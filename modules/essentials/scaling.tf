locals {
  # Scaling is only enabled if KEDA is enabled, the cluster is NOT production, and scaling is enabled
  is_scaling_enabled = var.keda_enabled && !var.is_production && var.keda_scaling_enabled

  # Well-known system components to scale
  system_scaling_targets = [
    {
      name      = "metrics-server"
      namespace = "kube-system"
      kind      = "Deployment"
      replicas  = 1
      enabled   = var.metrics_server_enabled
    },
    {
      name      = "cert-manager"
      namespace = var.certmanager_namespace
      kind      = "Deployment"
      replicas  = 1
      enabled   = true
    },
    {
      name      = "cert-manager-cainjector"
      namespace = var.certmanager_namespace
      kind      = "Deployment"
      replicas  = 1
      enabled   = var.ca_injector_enabled
    },
    {
      name      = "cert-manager-webhook"
      namespace = var.certmanager_namespace
      kind      = "Deployment"
      replicas  = 1
      enabled   = true
    },
    {
      name      = "karpenter"
      namespace = "kube-system"
      kind      = "Deployment"
      replicas  = 2
      enabled   = var.autoscaling_mode == "karpenter"
    },
    {
      name      = "coredns"
      namespace = "kube-system"
      kind      = "Deployment"
      replicas  = 2
      enabled   = true
    },
    {
      name      = "ebs-csi-controller"
      namespace = "kube-system"
      kind      = "Deployment"
      replicas  = 2
      enabled   = true
    },
    {
      name      = "aws-load-balancer-controller"
      namespace = "kube-system"
      kind      = "Deployment"
      replicas  = 2
      enabled   = true
    }
  ]

  # Combine system targets with additional targets
  all_scaling_targets = concat(
    [for t in local.system_scaling_targets : t if t.enabled],
    [for t in var.keda_additional_scaling_targets : merge(t, { enabled = true })]
  )
}

# 1. ScaledObjects for all targets
resource "kubernetes_manifest" "system_scaled_objects" {
  for_each = local.is_scaling_enabled ? { for t in local.all_scaling_targets : "${t.namespace}/${t.name}" => t } : {}

  manifest = {
    apiVersion = "keda.sh/v1alpha1"
    kind       = "ScaledObject"
    metadata = {
      name      = "${each.value.name}-office-hours"
      namespace = each.value.namespace
      labels    = var.kubernetes_labels
    }
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1"
        kind       = each.value.kind
        name       = each.value.name
      }
      minReplicaCount = 0
      maxReplicaCount = each.value.replicas
      triggers = [
        {
          type = "cron"
          metadata = {
            timezone        = var.keda_scaling_timezone
            start           = var.keda_scaling_start_schedule
            end             = var.keda_scaling_end_schedule
            desiredReplicas = tostring(each.value.replicas)
          }
        }
      ]
    }
  }

  depends_on = [helm_release.keda]
}

# 2. ServiceAccount for KEDA self-scaling
resource "kubernetes_service_account_v1" "keda_scaler" {
  count = local.is_scaling_enabled ? 1 : 0

  metadata {
    name      = "keda-scaler-sa"
    namespace = var.keda_namespace
    labels    = var.kubernetes_labels
  }
}

resource "kubernetes_role_v1" "keda_scaler" {
  count = local.is_scaling_enabled ? 1 : 0

  metadata {
    name      = "keda-scaler-role"
    namespace = var.keda_namespace
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get", "patch", "update"]
  }
}

resource "kubernetes_role_binding_v1" "keda_scaler" {
  count = local.is_scaling_enabled ? 1 : 0

  metadata {
    name      = "keda-scaler-rolebinding"
    namespace = var.keda_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.keda_scaler[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.keda_scaler[0].metadata[0].name
    namespace = var.keda_namespace
  }
}

# 3. CronJobs to scale KEDA itself
resource "kubernetes_cron_job_v1" "scale_down_keda" {
  count = local.is_scaling_enabled ? 1 : 0

  metadata {
    name      = "scale-down-keda"
    namespace = var.keda_namespace
    labels    = var.kubernetes_labels
  }

  spec {
    schedule  = var.keda_self_scale_down_schedule
    time_zone = var.keda_scaling_timezone
    job_template {
      spec {
        template {
          spec {
            service_account_name = kubernetes_service_account_v1.keda_scaler[0].metadata[0].name
            container {
              name    = "scaler"
              image   = "registry.k8s.io/kubectl:v1.31.0"
              command = ["kubectl"]
              args = [
                "scale",
                "deployment",
                "keda-operator",
                "keda-admission-webhooks",
                "keda-operator-metrics-apiserver",
                "--replicas=0",
                "-n",
                var.keda_namespace
              ]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}

resource "kubernetes_cron_job_v1" "scale_up_keda" {
  count = local.is_scaling_enabled ? 1 : 0

  metadata {
    name      = "scale-up-keda"
    namespace = var.keda_namespace
    labels    = var.kubernetes_labels
  }

  spec {
    schedule  = var.keda_self_scale_up_schedule
    time_zone = var.keda_scaling_timezone
    job_template {
      spec {
        template {
          spec {
            service_account_name = kubernetes_service_account_v1.keda_scaler[0].metadata[0].name
            container {
              name    = "scaler"
              image   = "registry.k8s.io/kubectl:v1.31.0"
              command = ["kubectl"]
              args = [
                "scale",
                "deployment",
                "keda-operator",
                "keda-admission-webhooks",
                "keda-operator-metrics-apiserver",
                "--replicas=1",
                "-n",
                var.keda_namespace
              ]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
