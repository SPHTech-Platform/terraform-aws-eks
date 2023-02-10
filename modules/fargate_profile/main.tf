module "fargate_profile" {
  source  = "terraform-aws-modules/eks/aws//modules/fargate-profile"
  version = "~> 19.5.1"

  for_each = var.fargate_profiles

  name         = lookup(each.value, "name", each.key)
  cluster_name = var.cluster_name
  subnet_ids   = each.value.subnet_ids
  selectors    = each.value.selectors
  timeouts     = lookup(each.value, "timeouts", {})

  create_iam_role               = lookup(each.value, "create_iam_role", true)
  iam_role_arn                  = lookup(each.value, "iam_role_arn", null)
  iam_role_name                 = lookup(each.value, "iam_role_name", "")
  iam_role_use_name_prefix      = lookup(each.value, "iam_role_use_name_prefix", true)
  iam_role_path                 = lookup(each.value, "iam_role_path", null)
  iam_role_description          = lookup(each.value, "iam_role_description", null)
  iam_role_permissions_boundary = lookup(each.value, "iam_role_permissions_boundary", null)
  iam_role_attach_cni_policy    = lookup(each.value, "iam_role_attach_cni_policy", true)
  iam_role_additional_policies  = lookup(each.value, "iam_role_additional_policies", {})
  iam_role_tags                 = lookup(each.value, "iam_role_tags", {})
}
