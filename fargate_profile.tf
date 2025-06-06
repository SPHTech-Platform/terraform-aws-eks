locals {
  essentials_namespaces  = ["opentelemetry-operator-system", "cert-manager"] # to add more if the essentials module deploys in any new namespaces
  kube_system_namespaces = ["kube-system"]

  fargate_namespaces = concat(local.essentials_namespaces, local.kube_system_namespaces)

  subnets_by_az = {
    for subnet_id in var.subnet_ids :
    data.aws_subnet.subnets[subnet_id].availability_zone => subnet_id...
  }

  default_fargate_profiles = merge(
    {
      essentials = {
        iam_role_name = "fargate_profile_essentials"
        subnet_ids    = var.subnet_ids
        selectors = [
          for ns_value in local.essentials_namespaces : {
            namespace = ns_value
          }
        ]
      }
    },
    { for az, az_subnets in local.subnets_by_az :
      "kube-system-${substr(az, -2, 2)}" => {
        iam_role_name = "fargate_profile_${substr(az, -2, 2)}"
        selectors = [
          { namespace = "kube-system" }
        ]
        # Create one profile per AZ for even spread
        subnet_ids = az_subnets
      }
    },
  )

  fargate_profiles = merge(
    local.default_fargate_profiles,
    var.fargate_profiles,
  )
}

module "fargate_profiles" {
  source = "./modules/fargate_profile"

  count = var.fargate_cluster ? 1 : 0

  cluster_name                    = split("/", data.aws_arn.cluster.resource)[1]
  fargate_profiles                = local.fargate_profiles
  fargate_profile_defaults        = var.fargate_profile_defaults
  create_aws_observability_ns     = var.create_aws_observability_ns
  create_fargate_logger_configmap = var.create_fargate_logger_configmap

  tags = var.tags
}

resource "kubernetes_manifest" "fargate_node_security_group_policy" {
  for_each = var.fargate_cluster && var.create_node_security_group ? toset(local.fargate_namespaces) : []

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-${each.value}-namespace-sg"
      namespace = each.value
    }
    spec = {
      podSelector = {
        matchLabels = {}
      }
      securityGroups = {
        groupIds = [module.eks.node_security_group_id]
      }
    }
  }
}
