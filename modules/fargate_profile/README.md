<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_fargate_profile"></a> [fargate\_profile](#module\_fargate\_profile) | terraform-aws-modules/eks/aws//modules/fargate-profile | ~> 19.5.1 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_fargate_profiles"></a> [fargate\_profiles](#input\_fargate\_profiles) | Map of maps of `eks_node_groups` to create | `any` | `{}` | no |

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