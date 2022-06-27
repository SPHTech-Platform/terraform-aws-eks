resource "aws_ecr_pull_through_cache_rule" "cache" {
  for_each = var.configure_ecr_pull_through ? var.ecr_pull_through_cache_rules : {}

  ecr_repository_prefix = each.value.prefix
  upstream_registry_url = each.value.registry
}

data "aws_iam_policy_document" "ecr_cache" {
  count = var.configure_ecr_pull_through ? 1 : 0

  statement {
    actions = [
      "ecr:CreateRepository",
      "ecr:BatchImportUpstreamImage",
    ]

    resources = [for rule in aws_ecr_pull_through_cache_rule.cache : (
      "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${rule.ecr_repository_prefix}/*"
    )]
  }
}

resource "aws_iam_policy" "ecr_cache" {
  count = var.configure_ecr_pull_through ? 1 : 0

  name = var.ecr_cache_iam_cache_policy

  description = "Use ECR Pull Through Cache"
  policy      = data.aws_iam_policy_document.ecr_cache[0].json
}


resource "aws_iam_role_policy_attachment" "worker_ecr_pullthrough" {
  count = var.configure_ecr_pull_through ? 1 : 0

  role       = var.worker_iam_role_name
  policy_arn = aws_iam_policy.ecr_cache[0].arn
}

resource "aws_iam_role_policy_attachment" "worker_ecr_pullthrough_existing" {
  for_each = toset(var.ecr_pull_through_existing_policy_arn)

  role       = var.worker_iam_role_name
  policy_arn = each.key
}
