<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_managed_node_group"></a> [eks\_managed\_node\_group](#module\_eks\_managed\_node\_group) | terraform-aws-modules/eks/aws//modules/eks-managed-node-group | ~> 19.17.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group_tag.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag) | resource |
| [aws_ami.eks_default_bottlerocket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_subnet.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6` | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Cluster Version | `string` | `"1.27"` | no |
| <a name="input_eks_managed_node_group_defaults"></a> [eks\_managed\_node\_group\_defaults](#input\_eks\_managed\_node\_group\_defaults) | Map of EKS managed node group default configurations | `any` | <pre>{<br>  "create_iam_role": false,<br>  "ebs_optimized": true,<br>  "enable_monitoring": true,<br>  "protect_from_scale_in": false,<br>  "update_launch_template_default_version": true<br>}</pre> | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | Map of EKS managed node group definitions to create | `any` | `{}` | no |
| <a name="input_force_imdsv2"></a> [force\_imdsv2](#input\_force\_imdsv2) | Force IMDSv2 metadata server. | `bool` | `true` | no |
| <a name="input_force_irsa"></a> [force\_irsa](#input\_force\_irsa) | Force usage of IAM Roles for Service Account | `bool` | `true` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for all resources | `map(string)` | `{}` | no |
| <a name="input_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#input\_worker\_iam\_role\_arn) | Worker Nodes IAM Role ARN | `string` | n/a | yes |
| <a name="input_worker_security_group_id"></a> [worker\_security\_group\_id](#input\_worker\_security\_group\_id) | Security Group ID of the worker nodes | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_tags"></a> [autoscaling\_group\_tags](#output\_autoscaling\_group\_tags) | Tags applied to autoscaling groups |
| <a name="output_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#output\_eks\_managed\_node\_groups) | EKS managed node groups |
| <a name="output_node_group_autoscaling_group_names"></a> [node\_group\_autoscaling\_group\_names](#output\_node\_group\_autoscaling\_group\_names) | Map of the autoscaling group names |
| <a name="output_node_group_labels"></a> [node\_group\_labels](#output\_node\_group\_labels) | Map of labels applied to each node group |
| <a name="output_node_group_resources"></a> [node\_group\_resources](#output\_node\_group\_resources) | Map of objects containing information about underlying resources |
| <a name="output_node_group_status"></a> [node\_group\_status](#output\_node\_group\_status) | Map of EKS Node Group status |
| <a name="output_node_group_taints"></a> [node\_group\_taints](#output\_node\_group\_taints) | Map objects containing information about taints applied to each node group |
<!-- END_TF_DOCS -->
