locals {
  aws_auth_fargate_profile_pod_execution_role_arns = var.fargate_cluster ? distinct(
    compact(
      concat(
        values(module.fargate_profiles[0].fargate_profile_pod_execution_role_arn),
        var.aws_auth_fargate_profile_pod_execution_role_arns,
      )
    )
  ) : var.aws_auth_fargate_profile_pod_execution_role_arns

  additional_aws_auth_fargate_profile_pod_execution_role_arns = var.autoscaling_mode == "karpenter" && var.create_fargate_profile_for_karpenter ? concat(values(module.karpenter[0].fargate_profile_pod_execution_role_arn)) : []

  additional_role_mapping = var.autoscaling_mode == "karpenter" ? [
    {
      rolearn = aws_iam_role.workers.arn
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
      username = "system:node:{{EC2PrivateDNSName}}"
    }
  ] : []

}
#tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
#tfsec:ignore:aws-eks-no-public-cluster-access
#tfsec:ignore:aws-ec2-no-public-egress-sgr
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.21.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_enabled_log_types = var.cluster_enabled_log_types

  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  vpc_id                                = var.vpc_id
  subnet_ids                            = var.subnet_ids
  cluster_additional_security_group_ids = var.cluster_additional_security_group_ids
  cluster_ip_family                     = var.cluster_ip_family
  cluster_service_ipv4_cidr             = var.cluster_service_ipv4_cidr
  cluster_service_ipv6_cidr             = var.cluster_service_ipv6_cidr
  create_cni_ipv6_iam_policy            = var.create_cni_ipv6_iam_policy

  create_cluster_security_group      = var.create_cluster_security_group
  cluster_security_group_name        = coalesce(var.cluster_security_group_name, var.cluster_name)
  cluster_security_group_description = "EKS Cluster ${var.cluster_name} Master"
  cluster_security_group_additional_rules = merge(
    var.create_cluster_security_group && var.create_node_security_group ?
    {
      egress_nodes_ephemeral_ports_tcp = {
        description                = "To node 1025-65535"
        protocol                   = "tcp"
        from_port                  = 1025
        to_port                    = 65535
        type                       = "egress"
        source_node_security_group = var.create_node_security_group
      }
    } : {}
  , var.cluster_security_group_additional_rules)

  node_security_group_name        = coalesce(var.worker_security_group_name, join("_", [var.cluster_name, "worker"]))
  node_security_group_description = "EKS Cluster ${var.cluster_name} Nodes"
  node_security_group_additional_rules = merge({
    # cert-manager
    ingress_cluster_10260_webhook = {
      description                   = "Cluster API to node 10260/tcp webhook"
      protocol                      = "tcp"
      from_port                     = 10260
      to_port                       = 10260
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }, var.node_security_group_additional_rules)
  node_security_group_enable_recommended_rules = var.node_security_group_enable_recommended_rules

  create_kms_key = false # Created in kms.tf
  cluster_encryption_config = {
    provider_key_arn = module.kms_secret.key_arn
    resources        = ["secrets"]
  }

  cluster_addons = merge({
    kube-proxy = {
      most_recent = true
      reserve     = true
    }
    vpc-cni = var.fargate_cluster ? {
      most_recent              = true
      reserve                  = true
      service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
      configuration_values = jsonencode({
        env = {
          # Reference doc: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html#security-groups-pods-deployment
          ENABLE_POD_ENI                    = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
        init = {
          env = {
            DISABLE_TCP_EARLY_DEMUX = "true"
          }
        }
      })
      } : {
      most_recent              = true
      reserve                  = true
      service_account_role_arn = module.vpc_cni_irsa_role.iam_role_arn
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      reserve                  = true
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
    coredns = var.fargate_cluster ? {
      most_recent       = true
      reserve           = true
      resolve_conflicts = "OVERWRITE"
      configuration_values = jsonencode({
        computeType = "Fargate"
        # https://github.com/aws-ia/terraform-aws-eks-blueprints/pull/1329
        resources = {
          limits = {
            cpu = "0.25"
            # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
          requests = {
            cpu = "0.25"
            # We are targetting the smallest Task size of 512Mb, so we subtract 256Mb from the
            # request/limit to ensure we can fit within that task
            memory = "256M"
          }
        }
      })
      } : {
      most_recent = true
      reserve     = true
    }
    },
    var.cluster_addons,
  )

  cluster_addons_timeouts = var.cluster_addons_timeouts

  # We decouple the creation so that we don't create a circular dependency
  create_iam_role = false
  iam_role_arn    = aws_iam_role.cluster.arn

  enable_irsa = true

  create_node_security_group = var.create_node_security_group

  # aws-auth configmap
  create_aws_auth_configmap                        = var.create_aws_auth_configmap
  manage_aws_auth_configmap                        = var.manage_aws_auth_configmap
  aws_auth_node_iam_role_arns_non_windows          = [aws_iam_role.workers.arn]
  aws_auth_node_iam_role_arns_windows              = var.enable_cluster_windows_support ? [aws_iam_role.workers.arn] : []
  aws_auth_roles                                   = concat(var.role_mapping, local.additional_role_mapping)
  aws_auth_users                                   = var.user_mapping
  aws_auth_accounts                                = []
  aws_auth_fargate_profile_pod_execution_role_arns = concat(local.aws_auth_fargate_profile_pod_execution_role_arns, local.additional_aws_auth_fargate_profile_pod_execution_role_arns)

  tags                      = var.tags
  cloudwatch_log_group_tags = var.cloudwatch_log_group_tags
}
