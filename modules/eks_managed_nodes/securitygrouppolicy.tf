resource "kubernetes_manifest" "sg" {

  for_each = var.fargate_namespaces_for_security_group

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-node-${each.value}-sg"
      namespace = each.value
    }
    spec = {
      podSelector = {
        matchLabels = {}
      }
      securityGroups = {
        groupIds = [var.worker_security_group_id]
      }
    }
  }

}
