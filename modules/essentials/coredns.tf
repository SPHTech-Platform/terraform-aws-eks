# CoreDNS does not come with a PDB defined. We need to define this to prevent downtimes
resource "kubernetes_pod_disruption_budget_v1" "coredns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"

    annotations = var.kubernetes_annotations
    labels      = var.kubernetes_labels
  }
  spec {
    max_unavailable = var.coredns_pdb_max_unavailable
    selector {
      match_labels = {
        "eks.amazonaws.com/component" = "coredns"
        "k8s-app"                     = "kube-dns"
      }
    }
  }
}
