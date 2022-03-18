data "aws_caller_identity" "current" {
}

data "aws_partition" "current" {
}

data "aws_region" "current" {
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_id
}

data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.cluster_version}-x86_64-*"]
  }
}

data "aws_subnet" "subnets" {
  for_each = toset(concat(
    var.default_group_subnet_ids,
    var.subnet_ids,
  ))

  id = each.key
}
