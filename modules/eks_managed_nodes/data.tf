data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  all_subnets = toset(flatten([for _k, group in var.eks_managed_node_groups : try(group.subnet_ids, local.eks_managed_node_group_defaults.subnet_ids, data.aws_eks_cluster.this.vpc_config[0].subnet_ids)]))
}

data "aws_subnet" "subnets" {
  for_each = local.all_subnets

  id = each.key
}

data "aws_eks_node_groups" "this" {
  cluster_name = var.cluster_name
}

data "aws_eks_node_group" "this" {
  for_each = data.aws_eks_node_groups.this.names

  cluster_name    = var.cluster_name
  node_group_name = each.value
}

data "aws_autoscaling_group" "node_groups" {
  for_each = module.eks_managed_node_group
  name     = each.value.node_group_resources.0.autoscaling_groups.0.name
}
