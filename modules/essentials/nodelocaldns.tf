locals {
  nodelocaldns_values = {
    image_repository         = var.nodelocaldns_image_repository
    tag                      = var.nodelocaldns_image_tag
    internel_domain_name     = var.nodelocaldns_internal_domain_name
    kube_dns_svc_ip          = var.nodelocaldns_kube_dns_svc_ip
    local_dns_ip             = var.nodelocaldns_localdns_ip
    custom_upstream_svc_name = var.nodelocaldns_custom_upstream_svc_name
    enable_logging           = var.nodelocaldns_enable_logging
    no_ipv6_lookups          = var.ip_dual_stack_enabled ? var.nodelocaldns_no_ipv6_lookups : false
    prefetch_enabled         = var.nodelocaldns_cache_prefetch_enabled
    setup_interface          = var.nodelocaldns_setup_interface
    setup_iptables           = var.nodelocaldns_setup_iptables
    skip_teardown            = var.nodelocaldns_skip_teardown
    pod_resources            = jsonencode(var.nodelocaldns_pod_resources)
    affinity                 = jsonencode(var.nodelocaldns_affinity)
    image_pull_secrets       = jsonencode(var.nodelocaldns_image_pull_secrets)
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
