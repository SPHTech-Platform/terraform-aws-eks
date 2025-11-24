locals {
  cluster_brupop_values = {
    cluster_name = var.cluster_name
    aws_region   = data.aws_region.current.region

    brupop_namespace = var.brupop_namespace
    brupop_image     = var.brupop_image
    brupop_tag       = var.brupop_tag
  }

  brupop_crd_values = yamlencode({ namespace = var.brupop_namespace, apiserver_service_port = var.brupop_crd_apiserver_service_port })
}

resource "helm_release" "brupop_crd" {
  count = var.brupop_enabled ? 1 : 0

  name       = var.brupop_crd_release_name
  chart      = var.brupop_crd_chart_name
  repository = var.brupop_crd_chart_repository
  version    = var.brupop_crd_chart_version

  create_namespace = true
  namespace        = var.brupop_namespace

  max_history = 10

  values = [
    local.brupop_crd_values
  ]

  depends_on = [
    resource.helm_release.cert_manager
  ]
}

resource "helm_release" "brupop" {
  count = var.brupop_enabled ? 1 : 0

  name       = var.brupop_release_name
  chart      = var.brupop_chart_name
  repository = var.brupop_chart_repository
  version    = var.brupop_chart_version

  create_namespace = true
  namespace        = var.brupop_namespace

  max_history = 10

  values = [
    templatefile("${path.module}/templates/brupop.yaml", local.cluster_brupop_values),
  ]

  depends_on = [
    resource.helm_release.cert_manager,
    resource.helm_release.brupop_crd
  ]
}

# Added option to disable bottlerocket update operator
moved {
  from = helm_release.brupop
  to   = helm_release.brupop[0]
}
