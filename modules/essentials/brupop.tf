resource "helm_release" "brupop" {
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
}

locals {
  cluster_brupop_values = {
    cluster_name = var.cluster_name
    aws_region   = data.aws_region.current.name

    brupop_namespace = var.brupop_namespace
    brupop_image     = var.brupop_image
    brupop_tag       = var.brupop_tag
  }
}
