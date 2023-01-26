module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.5.1"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_enabled_log_types = var.cluster_enabled_log_types

  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  vpc_id                                = var.vpc_id
  subnet_ids                            = var.subnet_ids
  cluster_additional_security_group_ids = var.cluster_additional_security_group_ids
  cluster_service_ipv4_cidr             = var.cluster_service_ipv4_cidr

  cluster_security_group_name        = coalesce(var.cluster_security_group_name, var.cluster_name)
  cluster_security_group_description = "EKS Cluster ${var.cluster_name} Master"
  cluster_security_group_additional_rules = merge({
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }, var.cluster_security_group_additional_rules)

  node_security_group_name             = coalesce(var.worker_security_group_name, join("_", [var.cluster_name, "worker"]))
  node_security_group_description      = "EKS Cluster ${var.cluster_name} Nodes"
  node_security_group_additional_rules = var.node_security_group_additional_rules

  create_kms_key = false # Created in kms.tf
  cluster_encryption_config = {
    provider_key_arn = module.kms_secret.key_arn
    resources        = ["secrets"]
  }

  # We decouple the creation so that we don't create a circular dependency
  create_iam_role = false
  iam_role_arn    = aws_iam_role.cluster.arn

  enable_irsa = true

  create_node_security_group = true

  # aws-auth configmap
  create_aws_auth_configmap               = var.create_aws_auth_configmap
  manage_aws_auth_configmap               = var.manage_aws_auth_configmap
  aws_auth_node_iam_role_arns_non_windows = [aws_iam_role.workers.arn]
  aws_auth_node_iam_role_arns_windows     = var.enable_cluster_windows_support ? [aws_iam_role.workers.arn] : []
  aws_auth_roles                          = var.role_mapping
  aws_auth_users                          = var.user_mapping
  aws_auth_accounts                       = []

  tags = var.tags
}
