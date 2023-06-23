locals {

  essentials_namespaces  = ["opentelemetry-operator-system", "cert-manager", "brupop-bottlerocket-aws"] # to add more if the essentials module deploys in any new namespaces
  kube_system_namespaces = ["kube-system"]

  fargate_namespaces = concat(local.essentials_namespaces, local.kube_system_namespaces)

  default_fargate_profiles = merge(
    {
      essentials = {
        iam_role_name = "fargate_profile_essentials"
        iam_role_additional_policies = {
          additional = aws_iam_policy.fargate_logging.arn
        }
        subnet_ids = var.subnet_ids
        selectors = [
          for ns_value in local.essentials_namespaces : {
            namespace = ns_value
          }
        ]
      }
    },
    { for subnet in var.subnet_ids :
      "kube-system-${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}" => {
        iam_role_name = "fargate_profile_${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}"
        iam_role_additional_policies = {
          additional = aws_iam_policy.fargate_logging.arn
        }
        selectors = [
          { namespace = "kube-system" }
        ]
        # Create one profile per AZ for even spread
        subnet_ids = [subnet]
      }
    },

  )

  fargate_profiles = merge(
    local.default_fargate_profiles,
    var.fargate_profiles,
  )
}
module "fargate_profiles" {
  source = "./modules/fargate_profile"

  count = var.fargate_cluster ? 1 : 0

  cluster_name                    = split("/", data.aws_arn.cluster.resource)[1]
  fargate_profiles                = local.fargate_profiles
  fargate_profile_defaults        = var.fargate_profile_defaults
  create_aws_observability_ns     = var.create_aws_observability_ns
  create_fargate_logger_configmap = var.create_fargate_logger_configmap

  tags = var.tags
}

resource "kubernetes_manifest" "fargate_node_security_group_policy" {

  count = var.fargate_cluster && var.create_node_security_group ? 1 : 0

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-node-default-namespace-sg"
      namespace = "kube-system"
    }
    spec = {
      podSelector = {
        matchLabels = {}
      }
      securityGroups = {
        groupIds = [module.eks.node_security_group_id]
      }
    }
  }
}

resource "aws_iam_policy" "fargate_logging" {
  name        = "fargate_logging_cloudwatch"
  path        = "/"
  description = "AWS recommended cloudwatch perms policy"

  policy = data.aws_iam_policy_document.fargate_logging.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "fargate_logging" {
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
