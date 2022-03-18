data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

locals {
  all_subnets = toset(flatten([for _k, group in var.self_managed_node_groups : try(group.subnet_ids, local.self_managed_node_group_defaults.subnet_ids, data.aws_eks_cluster.this.vpc_config[0].subnet_ids)]))
}

data "aws_subnet" "subnets" {
  for_each = local.all_subnets

  id = each.key
}
