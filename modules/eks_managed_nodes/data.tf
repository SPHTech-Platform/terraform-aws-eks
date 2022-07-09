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

data "aws_autoscaling_group" "node_groups" {
  for_each = module.eks_managed_node_group
  name     = each.value.node_group_resources.0.autoscaling_groups.0.name
}
