resource "kubernetes_cluster_role" "ams_cluster" {
  metadata {
    name = "ams-cluster-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "persistentvolumeclaims", "secrets", "serviceaccounts", "services"]
    verbs      = ["patch", "create", "update"]
  }

  rule {
    api_groups = ["admissionregistration.k8s.io"]
    resources  = ["mutatingwebhookconfigurations", "validatingwebhookconfigurations"]
    verbs      = ["patch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["daemonsets", "deployments"]
    verbs      = ["patch"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["patch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["clusterrolebindings", "clusterroles", "rolebindings", "roles"]
    verbs      = ["patch"]
  }

  rule {
    api_groups = ["storage.k8s.io"]
    resources  = ["csidrivers"]
    verbs      = ["patch", "create", "delete"]
  }

  rule {
    non_resource_urls = ["/metrics"]
    verbs             = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "ams_cluster" {
  metadata {
    name = "ams-cluster-role-binding"
  }

  role_ref {
    api_group = ""
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ams_cluster.metadata.name
  }

  subject {
    kind      = "User"
    name      = "ams-ood-user"
    api_group = ""
  }
}

resource "kubernetes_cluster_role_binding" "ams_lambda_connector" {
  metadata {
    name = "ams-lambda-connector-role-binding"
  }

  role_ref {
    api_group = ""
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.ams_cluster.metadata.name
  }

  subject {
    kind      = "User"
    name      = "lambda-connector"
    api_group = ""
  }
}
