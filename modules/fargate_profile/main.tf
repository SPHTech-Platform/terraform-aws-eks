module "fargate_profile" {
  source  = "terraform-aws-modules/eks/aws//modules/fargate-profile"
  version = "~> 19.10.0"

  for_each = var.fargate_profiles

  name         = lookup(each.value, "name", each.key)
  cluster_name = var.cluster_name
  subnet_ids   = each.value.subnet_ids
  selectors    = lookup(each.value, "selectors", lookup(var.fargate_profile_defaults, "selectors", []))
  timeouts     = lookup(each.value, "timeouts", lookup(var.fargate_profile_defaults, "timeouts", {}))

  create_iam_role               = lookup(each.value, "create_iam_role", lookup(var.fargate_profile_defaults, "create_iam_role", true))
  iam_role_arn                  = lookup(each.value, "iam_role_arn", lookup(var.fargate_profile_defaults, "iam_role_arn", null))
  iam_role_name                 = lookup(each.value, "iam_role_name", lookup(var.fargate_profile_defaults, "iam_role_name", ""))
  iam_role_use_name_prefix      = lookup(each.value, "iam_role_use_name_prefix", lookup(var.fargate_profile_defaults, "iam_role_use_name_prefix", true))
  iam_role_path                 = lookup(each.value, "iam_role_path", lookup(var.fargate_profile_defaults, "iam_role_path", null))
  iam_role_description          = lookup(each.value, "iam_role_description", lookup(var.fargate_profile_defaults, "iam_role_description", null))
  iam_role_permissions_boundary = lookup(each.value, "iam_role_permissions_boundary", lookup(var.fargate_profile_defaults, "iam_role_permissions_boundary", null))
  iam_role_attach_cni_policy    = lookup(each.value, "iam_role_attach_cni_policy", lookup(var.fargate_profile_defaults, "iam_role_attach_cni_policy", true))
  iam_role_additional_policies  = lookup(each.value, "iam_role_additional_policies", lookup(var.fargate_profile_defaults, "iam_role_additional_policies", {}))
  iam_role_tags                 = lookup(each.value, "iam_role_tags", {})
  tags                          = merge(var.tags, lookup(each.value, "tags", {}))
}

## Only used when needed for testing pods running in a namespace which requires access to the managed nodes
resource "kubernetes_manifest" "sg" {

  for_each = toset(var.fargate_namespaces_for_security_group)

  manifest = {
    apiVersion = "vpcresources.k8s.aws/v1beta1"
    kind       = "SecurityGroupPolicy"
    metadata = {
      name      = "fargate-node-${each.value}-sg"
      namespace = each.value
    }
    spec = {
      podSelector = {
        matchLabels = {}
      }
      securityGroups = {
        groupIds = [var.eks_worker_security_group_id]
      }
    }
  }

}
