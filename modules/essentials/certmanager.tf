#Cert Manager Namespace
resource "kubernetes_namespace" "cert_manager_namespace" {

  count = var.create_cert_manager_namespace ? 1 : 0
  metadata {
    name = "cert-manager"
  }
}


#Cert Manager
module "cert_manager" {

  source  = "basisai/cert-manager/helm"
  version = "~> 0.1.3"

  chart_name                 = "cert-manager"
  chart_namespace            = "cert-manager"
  cluster_resource_namespace = "cert-manager"
}
