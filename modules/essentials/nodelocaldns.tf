data "kubernetes_service" "kube_dns" {
  metadata {
    name      = "kube-dns"
    namespace = "kube-system"
  }
}

# Not compatible with `IPVS`/`NFTables` mode of kube-proxy, code is only for `IPTABLES` mode
resource "kubectl_manifest" "nodelocaldns" {
  count = var.node_local_dns_cache_enabled ? 1 : 0

  yaml_body = templatefile("${path.module}/templates/nodelocaldns.yaml", {
    PILLAR__DNS__DOMAIN = var.cluster_domain_name
    PILLAR__LOCAL__DNS  = var.node_local_dns_address
    PILLAR__DNS__SERVER = try(data.kubernetes_service.kube_dns.spec[0].cluster_ip, "172.20.0.10")
    tag                 = var.nodelocal_dns_cache_image_tag
  })
}
