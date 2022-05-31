# EKS Self Managed Nodes

This is an opinionated module to create one or more self-managed node groups on EKS. It depends on
the `eks` module by making the following assumptions:

- IAM Roles for Service Accounts is in use.
- Therefore, all worker nodes will share one IAM role which has the necessary policies for EKS
  to function and nothing more.
- All worker nodes will share one common security group which contains rules for the EKS cluster
  to function. Additional security groups can, however, be added on.
- Each ASG will be created in exactly one subnet. You can specify multiple subnets for each node
  group but the module will perform a cartesian product of the node groups and their subnets. This
  is so that each ASG will create instances in exactly one AZ and subnet and allow the cluster
  autoscaler to work properly.
- ASGs will be tagged to allow the Cluster AutoScaler to scale the node group.
- ASG lifecycle hook is created to enable instance refresh facilitated by
  [AWS Node Termination Handler](https://github.com/aws/aws-node-termination-handler).

## Node Groups Specification

Refer to the base
[module](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/self-managed-node-group)
for the parameters for each node group defined in either `var.self_managed_node_groups` or
`var.self_managed_node_group_defaults`.

### Additional modules (TODO)

Additional submodules will allow you to define the following that will be configured according to
the type of images:

- `kube_labels`: Kubernetes labels to add to nodes.
  Will be automatically added to the kublet arguments and ASG tags
- `kube_taints`: Kubernetes taints to add to nodes.
  Will be automatically added to the kubelet arguments and ASG tags.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | ~> 0.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.16.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.7.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_self_managed_group"></a> [self\_managed\_group](#module\_self\_managed\_group) | terraform-aws-modules/eks/aws//modules/self-managed-node-group | ~> 18.21.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_lifecycle_hook.node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_lifecycle_hook) | resource |
| [aws_cloudwatch_event_rule.node_termination_handler_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.node_termination_handler_asg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [time_static.creation](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_subnet.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | Security Group ID of the master nodes | `string` | n/a | yes |
| <a name="input_node_termination_handler_event_name"></a> [node\_termination\_handler\_event\_name](#input\_node\_termination\_handler\_event\_name) | Override name of the Cloudwatch Event to handle termination of nodes | `string` | `""` | no |
| <a name="input_node_termination_handler_sqs_arn"></a> [node\_termination\_handler\_sqs\_arn](#input\_node\_termination\_handler\_sqs\_arn) | ARN of the SQS queue used to handle node termination events | `string` | n/a | yes |
| <a name="input_self_managed_node_group_defaults"></a> [self\_managed\_node\_group\_defaults](#input\_self\_managed\_node\_group\_defaults) | Map of self-managed node group default configurations to override the built in defaults | `any` | <pre>{<br>  "create_iam_role": false,<br>  "create_security_group": false,<br>  "disk_size": 50,<br>  "instance_refresh": {<br>    "strategy": "Rolling"<br>  },<br>  "metadata_options": {<br>    "http_endpoint": "enabled",<br>    "http_put_response_hop_limit": 1,<br>    "http_tokens": "required",<br>    "instance_metadata_tags": "disabled"<br>  },<br>  "protect_from_scale_in": false,<br>  "update_launch_template_default_version": true<br>}</pre> | no |
| <a name="input_self_managed_node_groups"></a> [self\_managed\_node\_groups](#input\_self\_managed\_node\_groups) | Map of self-managed node group definitions to create | `any` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for all resources | `map(string)` | `{}` | no |
| <a name="input_worker_iam_instance_profile_arn"></a> [worker\_iam\_instance\_profile\_arn](#input\_worker\_iam\_instance\_profile\_arn) | Worker Nodes IAM Instance Profile ARN | `string` | n/a | yes |
| <a name="input_worker_security_group_id"></a> [worker\_security\_group\_id](#input\_worker\_security\_group\_id) | Security Group ID of the worker nodes | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
