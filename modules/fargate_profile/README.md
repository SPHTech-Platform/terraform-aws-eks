Please set the following to the module caller as required IAM policies:

```hcl
resource "aws_iam_policy" "fargate_logging" {
  name        = "fargate_logging_cloudwatch"
  path        = "/"
  description = "AWS recommended cloudwatch perms policy"

  policy = data.aws_iam_policy_document.fargate_logging.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "fargate_logging" {
  #checkov:skip=CKV_AWS_111:Restricted to Cloudwatch Actions only
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

### Caller Example
module "fargate_profile" {
  # source  = "SPHTech-Platform/eks/aws//modules/fargate_profile"
  # version = "~> 0.11.0"

  source = "git::https://github.com/SPHTech-Platform/terraform-aws-eks.git//modules/fargate_profile?ref=fargate-logging"

  cluster_name = local.cluster_name
  fargate_profiles = {
    default = {
      iam_role_name = "fargate_profile_default"
      iam_role_additional_policies = {
        additional = aws_iam_policy.fargate_logging.arn
      }
      subnet_ids = <list_of_subnet_ids>
      selectors = [
        {
          namespace = "<namespace>
        }
      ]
    }
  }

}

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_fargate_profile"></a> [fargate\_profile](#module\_fargate\_profile) | terraform-aws-modules/eks/aws//modules/fargate-profile | ~> 19.10.0 |

## Resources

| Name | Type |
|------|------|
| [kubernetes_config_map_v1.aws_logging](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_namespace_v1.aws_observability](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_addon_config"></a> [addon\_config](#input\_addon\_config) | Fargate fluentbit configuration | `any` | `{}` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_create_aws_observability_ns"></a> [create\_aws\_observability\_ns](#input\_create\_aws\_observability\_ns) | value to determine if aws-observability namespace is created | `bool` | `false` | no |
| <a name="input_fargate_logging_enabled"></a> [fargate\_logging\_enabled](#input\_fargate\_logging\_enabled) | Toggle flag for fargate logging | `bool` | `true` | no |
| <a name="input_fargate_profile_defaults"></a> [fargate\_profile\_defaults](#input\_fargate\_profile\_defaults) | Map of Fargate Profile default configurations | `any` | `{}` | no |
| <a name="input_fargate_profiles"></a> [fargate\_profiles](#input\_fargate\_profiles) | Map of maps of `fargate_profiles` to create | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fargate_profile_arn"></a> [fargate\_profile\_arn](#output\_fargate\_profile\_arn) | Map of Amazon Resource Name (ARN) of the EKS Fargate Profile |
| <a name="output_fargate_profile_id"></a> [fargate\_profile\_id](#output\_fargate\_profile\_id) | Map of EKS Cluster name and EKS Fargate Profile name separated by a colon (`:`) |
| <a name="output_fargate_profile_pod_execution_role_arn"></a> [fargate\_profile\_pod\_execution\_role\_arn](#output\_fargate\_profile\_pod\_execution\_role\_arn) | Map of Amazon Resource Name (ARN) of the EKS Fargate Profile Pod execution role ARN |
| <a name="output_fargate_profile_status"></a> [fargate\_profile\_status](#output\_fargate\_profile\_status) | Map of Status of the EKS Fargate Profile |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | Map of The Amazon Resource Name (ARN) specifying the IAM role |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Map of the name of the IAM role |
| <a name="output_iam_role_unique_id"></a> [iam\_role\_unique\_id](#output\_iam\_role\_unique\_id) | Map of Stable and unique string identifying the IAM role |
<!-- END_TF_DOCS -->
