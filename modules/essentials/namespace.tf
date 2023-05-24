resource "kubernetes_namespace_v1" "namespaces" {
  for_each = { for ns in var.namespaces : ns.name => ns }

  metadata {
    name        = each.key
    annotations = merge(each.value.description != null ? { description = each.value.description } : {}, var.kubernetes_annotations)
    labels      = var.kubernetes_labels
  }
}
