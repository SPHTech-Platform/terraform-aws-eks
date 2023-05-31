module "karpenter_fargate_profile" {
  # source  = "SPHTech-Platform/eks/aws//modules/fargate_profile"
  # version = "~> 0.11.0"

  source = "git::https://github.com/SPHTech-Platform/terraform-aws-eks.git//modules/fargate_profile?ref=fargate-logging"

  #   cluster_name = local.cluster_name
  cluster_name = var.cluster_name
  fargate_profiles = {
    karpenter = {
      iam_role_name = "fargate_profile_karpenter"
      iam_role_additional_policies = {
        additional = aws_iam_policy.karpenter_fargate_logging.arn
      }
      #   subnet_ids = local.app_subnets
      subnet_ids = var.subnet_ids
      selectors = [
        {
          namespace = var.karpenter_namespace
        }
      ]
    }
  }

}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "karpenter_fargate_logging" {
  #checkov:skip=CKV_AWS_111:Restricted to Cloudwatch Actions only
  #checkov:skip=CKV_AWS_356: Only logs actions
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
  }
}

resource "aws_iam_policy" "karpenter_fargate_logging" {
  name        = "fargate_logging_cloudwatch"
  path        = "/"
  description = "AWS recommended cloudwatch perms policy"

  policy = data.aws_iam_policy_document.karpenter_fargate_logging.json
}
