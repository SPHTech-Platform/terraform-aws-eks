locals {
  log_group_name       = "/aws/eks/${var.cluster_name}/fluent-bit"
  service_account_name = "fluentbit-sa"
  default_helm_config = merge(
    var.fluent_bit_helm_config_defaults,
    {
      values = [
        local.default_helm_values,
      ]
    }
  )
  affinity = {
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            matchExpressions = [
              {
                key      = "eks.amazonaws.com/compute-type"
                operator = "NotIn"
                values   = ["fargate"]
              },
            ]
          },
        ]
      }
    }
  }

  default_helm_values = var.fluent_bit_overwrite_helm_values != null && var.fluent_bit_overwrite_helm_values != "" ? var.fluent_bit_overwrite_helm_values : templatefile("${path.module}/templates/fluent_bit.yaml", {
    log_group_name       = local.log_group_name,
    service_account_name = local.service_account_name,
    image_repository     = var.fluent_bit_image_repository,
    image_tag            = var.fluent_bit_image_tag,
    custom_parser        = var.fluent_bit_custom_parser,
    liveness_probe       = jsonencode(var.fluent_bit_liveness_probe),
    readiness_probe      = jsonencode(var.fluent_bit_readiness_probe),
    resources            = jsonencode(var.fluent_bit_resources),
    tolerations          = jsonencode(var.fluent_bit_tolerations),
    affinity             = jsonencode(local.affinity),
    excluded_namespaces  = var.fluent_bit_excluded_namespaces,
    s3_bucket_name       = var.fluent_bit_enable_s3_output ? module.fluentbit_s3_bucket[0].s3_bucket_id : null,
    cw_enable            = var.fluent_bit_enable_cw_output
    kube_api_endpoint    = var.fluent_bit_kube_api_endpoint
  })

  fluent_bit_helm_config = merge(
    local.default_helm_config,
    var.fluent_bit_helm_config
  )
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key Not using CMK to save cost
resource "aws_cloudwatch_log_group" "aws_for_fluent_bit" {
  #checkov:skip=CKV_AWS_158:Not using CMK to save cost
  #checkov:skip=CKV_AWS_338: "Ensure CloudWatch log groups retains logs for at least 1 year"
  count = var.fluent_bit_enabled ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.fluent_bit_log_group_retention
}

module "helm_fluent_bit" {
  count = var.fluent_bit_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.1.4"

  helm_config = local.fluent_bit_helm_config
  irsa_config = {
    role_name = "${var.cluster_name}-irsa-fluentbit"
    role_policy_arns = merge(
      {
        "fluent-bit" = one(aws_iam_policy.fluent_bit_irsa[*].arn)
      },
      var.fluent_bit_role_policy_arns,
    )

    create_kubernetes_namespace       = true
    create_kubernetes_service_account = true
    kubernetes_namespace              = local.fluent_bit_helm_config.namespace
    kubernetes_service_account        = local.service_account_name
    oidc_providers = {
      fluent_bit = {
        provider_arn = var.oidc_provider_arn
        namespace_service_accounts = [
          "${local.fluent_bit_helm_config.namespace}:${local.service_account_name}"
        ]
      }
    }
  }
}

resource "aws_iam_policy" "fluent_bit_irsa" {
  count = var.fluent_bit_enabled ? 1 : 0

  name        = "${var.cluster_name}-fluentbit"
  description = "IAM Policy for AWS for FluentBit IRSA"
  policy      = data.aws_iam_policy_document.fluent_bit.json
}

moved {
  from = aws_cloudwatch_log_group.aws_for_fluent_bit
  to   = aws_cloudwatch_log_group.aws_for_fluent_bit[0]
}
