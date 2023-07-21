
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_caller_identity" "current" {
}

data "aws_partition" "current" {
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
  for_each = toset(var.subnet_ids)

  id = each.key
}
