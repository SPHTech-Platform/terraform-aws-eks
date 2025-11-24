data "aws_caller_identity" "current" {
}

data "aws_partition" "current" {
}

data "aws_ami" "eks_default_bottlerocket" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["bottlerocket-aws-k8s-${var.kubernetes_version}-x86_64-*"]
  }
}

data "aws_subnet" "subnets" {
  for_each = toset(var.subnet_ids)

  id = each.key
}
