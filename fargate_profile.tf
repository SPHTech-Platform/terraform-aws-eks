locals {
  essentials_namespaces  = ["opentelemetry-operator-system", "cert-manager"] # to add more if the essentials module deploys in any new namespaces
  kube_system_namespaces = ["kube-system"]

  fargate_namespaces = concat(local.essentials_namespaces, local.kube_system_namespaces)

  iam_role_additional_policies = var.fargate_cluster ? {
    additional = aws_iam_policy.fargate_logging[0].arn
  } : {}

  default_fargate_profiles = merge(
    {
      essentials = {
        iam_role_name                = "fargate_profile_essentials"
        iam_role_additional_policies = local.iam_role_additional_policies
        subnet_ids                   = var.subnet_ids
        selectors = [
          for ns_value in local.essentials_namespaces : {
            namespace = ns_value
          }
        ]
      }
    },
    { for subnet in var.subnet_ids :
      "kube-system-${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}" => {
        iam_role_name                = "fargate_profile_${substr(data.aws_subnet.subnets[subnet].availability_zone, -2, -1)}"
        iam_role_additional_policies = local.iam_role_additional_policies
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
  for_each = var.fargate_cluster && var.create_node_security_group ? toset(local.fargate_namespaces) : []

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-${each.value}-namespace-sg"
      namespace = each.value
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
  count = var.fargate_cluster ? 1 : 0

  name        = "fargate_logging_cloudwatch_default"
  path        = "/"
  description = "AWS recommended cloudwatch perms policy"
  policy      = data.aws_iam_policy_document.fargate_logging.json
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
