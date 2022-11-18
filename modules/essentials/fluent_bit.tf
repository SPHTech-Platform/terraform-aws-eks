locals {
  log_group_name       = "fluent-bit"
  service_account_name = "fluentbit-sa"
  default_helm_config = merge(
    var.fluent_bit_helm_config_defaults,
    {
      values = local.default_helm_values
    }
  )

  default_helm_values = [
    templatefile("${path.module}/templates/fluent_bit.yaml", {
      log_group_name       = local.log_group_name,
      service_account_name = local.service_account_name,
      image_repository     = var.fluent_bit_image_repository,
      image_tag            = var.fluent_bit_image_tag,
    })
  ]

  fluent_bit_helm_config = merge(
    local.default_helm_config,
    var.fluent_bit_helm_config
  )
}

resource "aws_cloudwatch_log_group" "aws_for_fluent_bit" {
  #checkov:skip=CKV_AWS_158:Not using CMK to save cost
  name              = local.log_group_name
  retention_in_days = var.cw_log_group_retention
}

module "helm_fluent_bit" {
  count = var.fluent_bit_enabled ? 1 : 0

  source  = "SPHTech-Platform/release/helm"
  version = "~> 0.1.3"

  helm_config = local.fluent_bit_helm_config
  irsa_config = {
    role_name = "${var.cluster_name}-irsa-fluentbit"
    role_policy_arns = {
      "fluent-bit" = aws_iam_policy.fluent_bit_irsa.arn
    }

    create_kubernetes_namespace       = true
    create_kubernetes_service_account = true
    kubernetes_namespace              = "${local.fluent_bit_helm_config.namespace}"
    kubernetes_service_account        = "${local.service_account_name}"
    oidc_providers = {
      bt_drupal = {
        provider_arn = data.tfe_outputs.base.values.oidc_provider_arn
        namespace_service_accounts = [
          "${local.fluent_bit_helm_config.namespace}:${local.service_account_name}"
        ]
      }
    }
  }
}

resource "aws_iam_policy" "fluent_bit_irsa" {
  name        = "${var.cluster_name}-fluentbit"
  description = "IAM Policy for AWS for FluentBit IRSA"
  policy      = data.aws_iam_policy_document.fluent_bit.json
}
