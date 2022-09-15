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

data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.cluster_version}-x86_64-*"]
  }
}
