locals {
  nodelocaldns_values = {
    image_repository     = var.nodelocaldns_image_repository
    tag                  = var.nodelocaldns_image_tag
    internel_domain_name = var.nodelocaldns_internal_domain_name
    kube_dns_svc_ip      = var.nodelocaldns_kube_dns_svc_ip
    local_dns_ip         = var.nodelocaldns_localdns_ip
  }
}

resource "kubectl_manifest" "nodelocaldns" {
  count = var.nodelocaldns_enabled ? 1 : 0

  yaml_body = templatefile("${path.module}/templates/nodelocaldns.yaml", local.nodelocaldns_values)
}
