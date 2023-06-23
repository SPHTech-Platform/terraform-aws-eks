locals {

  essentials_namespaces  = ["opentelemetry-operator-system", "cert-manager", "brupop-bottlerocket-aws"] # to add more if the essentials module deploys in any new namespaces
  kube_system_namespaces = ["kube-system"]

  fargate_namespaces = concat(local.essentials_namespaces, local.kube_system_namespaces)

  default_fargate_profiles = merge(
    {
      essentials = {
        subnet_ids = var.subnet_ids
        selectors = [
          for ns_value in local.essentials_namespaces : {
            namespace = ns_value
          }
        ]
      }
    },
    { for subnet in var.subnet_ids :
      "kube-system-${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}" => {
        selectors = [
          { namespace = "kube-system" }
        ]
        # Create one profile per AZ for even spread
        subnet_ids = [subnet]
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

  eks_worker_security_group_id          = module.eks.node_security_group_id
  fargate_namespaces_for_security_group = local.fargate_namespaces

  tags = var.tags
}
