locals {
  addon_vpc_cni = {
    fargate_pod_identity = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
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
      pod_identity_association = [{
        role_arn        = try(module.aws_vpc_cni_pod_identity[0].iam_role_arn, null)
        service_account = "aws-node"
      }]
    }
    fargate_irsa = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
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
      service_account_role_arn = try(module.vpc_cni_irsa_role[0].iam_role_arn, null)
    }
    nodegroup_irsa = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = try(module.vpc_cni_irsa_role[0].iam_role_arn, null)
    }
    nodegroup_pod_identity = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      pod_identity_association = [{
        role_arn        = try(module.aws_vpc_cni_pod_identity[0].iam_role_arn, null)
        service_account = "aws-node"
      }]
    }
  }

  addon_vpc_cni_lookup = var.fargate_cluster && var.enable_pod_identity_for_eks_addons ? "fargate_pod_identity" : (
    var.fargate_cluster ? "fargate_irsa" : (
      var.enable_pod_identity_for_eks_addons ? "nodegroup_pod_identity" : "nodegroup_irsa"
  ))

  addon_aws_ebs_csi_driver = {
    pod_identity = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      pod_identity_association = [{
        role_arn        = try(module.aws_ebs_csi_pod_identity[0].iam_role_arn, null)
        service_account = "ebs-csi-controller-sa"
      }]
    }
    irsa = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      service_account_role_arn    = try(module.ebs_csi_irsa_role[0].iam_role_arn, null)
    }
  }
  addon_aws_ebs_csi_driver_lookup = var.enable_pod_identity_for_eks_addons ? "pod_identity" : "irsa"

  node_security_group_tags = merge({
    "karpenter.sh/discovery" = var.cluster_name
  }, var.node_security_group_tags)
}
#tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
#tfsec:ignore:aws-eks-no-public-cluster-access
#tfsec:ignore:aws-ec2-no-public-egress-sgr
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.33.1"

  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  authentication_mode       = var.authentication_mode
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
  cluster_compute_config = var.cluster_compute_config

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
  node_security_group_tags                     = local.node_security_group_tags

  create_kms_key = false # Created in kms.tf
  cluster_encryption_config = {
    provider_key_arn = module.kms_secret.key_arn
    resources        = ["secrets"]
  }

  cluster_addons = merge({
    kube-proxy = {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni            = lookup(local.addon_vpc_cni, local.addon_vpc_cni_lookup, {})
    aws-ebs-csi-driver = lookup(local.addon_aws_ebs_csi_driver, local.addon_aws_ebs_csi_driver_lookup, {})
    coredns = var.fargate_cluster ? {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
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
        autoScaling = {
          enabled = true
        }
      })
      } : {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        autoScaling = {
          enabled = true
        }
      })
    }
    eks-pod-identity-agent = var.cluster_ip_family == "ipv4" ? {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
      configuration_values = jsonencode({
        agent = {
          additionalArgs = {
            "-b" = "169.254.170.23"
          }
        }
      })
      } : {
      most_recent                 = true
      resolve_conflicts_on_update = "OVERWRITE"
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

  tags                      = var.tags
  cloudwatch_log_group_tags = var.cloudwatch_log_group_tags

  access_entries                           = var.access_entries
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
}
