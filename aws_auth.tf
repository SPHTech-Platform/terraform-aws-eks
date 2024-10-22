locals {
  aws_auth_fargate_profile_pod_execution_role_arns = var.fargate_cluster ? distinct(
    compact(
      concat(
        values(module.fargate_profiles[0].fargate_profile_pod_execution_role_arn),
        var.aws_auth_fargate_profile_pod_execution_role_arns,
      )
    )
  ) : var.aws_auth_fargate_profile_pod_execution_role_arns

  additional_aws_auth_fargate_profile_pod_execution_role_arns = var.autoscaling_mode == "karpenter" && var.create_fargate_profile_for_karpenter ? concat(
    values(module.karpenter[0].fargate_profile_pod_execution_role_arn)
  ) : []

  node_iam_role_arns_non_windows          = [aws_iam_role.workers.arn]
  node_iam_role_arns_windows              = var.enable_cluster_windows_support ? [aws_iam_role.workers.arn] : []
  fargate_profile_pod_execution_role_arns = concat(local.aws_auth_fargate_profile_pod_execution_role_arns, local.additional_aws_auth_fargate_profile_pod_execution_role_arns)

  aws_auth_roles = concat(
    [for role_arn in local.node_iam_role_arns_non_windows : {
      rolearn  = role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
      }
    ],
    [for role_arn in local.node_iam_role_arns_windows : {
      rolearn  = role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "eks:kube-proxy-windows",
        "system:bootstrappers",
        "system:nodes",
      ]
      }
    ],
    # Fargate profile
    [for role_arn in local.fargate_profile_pod_execution_role_arns : {
      rolearn  = role_arn
      username = "system:node:{{SessionName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
        "system:node-proxier",
      ]
      }
    ],
    var.role_mapping
  )
}

module "eks_aws_auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.26.0"

  create_aws_auth_configmap = var.create_aws_auth_configmap
  manage_aws_auth_configmap = var.manage_aws_auth_configmap
  aws_auth_roles            = var.migrate_aws_auth_to_access_entry ? local.aws_auth_roles : var.role_mapping
  aws_auth_users            = var.user_mapping
  aws_auth_accounts         = []
}
