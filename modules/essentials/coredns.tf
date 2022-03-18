# CoreDNS does not come with a PDB defined. We need to define this to prevent downtimes
resource "kubernetes_pod_disruption_budget" "coredns" {
  metadata {
    name      = "coredns"
    namespace = "kube-system"

    annotations = var.kubernetes_annotations
    labels      = var.kubernetes_labels
  }
  spec {
    min_available = var.coredns_pdb_min_available
    selector {
      match_labels = {
        "eks.amazonaws.com/component" = "coredns"
        "k8s-app"                     = "kube-dns"
      }
    }
  }
}
