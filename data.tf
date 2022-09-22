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
