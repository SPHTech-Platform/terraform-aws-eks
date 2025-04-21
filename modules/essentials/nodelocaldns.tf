data "kubernetes_service" "kube_dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
}

resource "helm_release" "nodelocaldns" {
  count = var.nodelocaldns_enabled ? 1 : 0

  name       = var.nodelocaldns_release_name
  chart      = var.nodelocaldns_chart_name
  repository = var.nodelocaldns_chart_repository
  version    = var.nodelocaldns_chart_version

  create_namespace = true
  namespace        = var.nodelocaldns_namespace

  max_history = 10

  values = [
    templatefile("${path.module}/templates/nodelocaldns.yaml", local.nodelocaldns_values),
  ]
}
