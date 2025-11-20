# Karpenter Notes

## Scenarios

- Fresh Karpenter Cluster
- Migration for v0.31.x
- Switching from Cluster Autoscaler Nodegroups to pure Karpenter

### Fresh Karpenter Cluster

### Migration from Karpenter v0.31.x

### Switching from Cluster Autoscaler Nodegroups to pure Karpenter

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 3.0 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 3.0 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | ~> 21.8.0 |
| <a name="module_karpenter_fargate_profile"></a> [karpenter\_fargate\_profile](#module\_karpenter\_fargate\_profile) | ../fargate_profile | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_policy.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_sqs_queue.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_crd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_nodeclass](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_nodepool](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.controller_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_entry_type"></a> [access\_entry\_type](#input\_access\_entry\_type) | Type of the access entry. `EC2_LINUX`, `FARGATE_LINUX`, or `EC2_WINDOWS`; defaults to `EC2_LINUX` | `string` | `"EC2_LINUX"` | no |
| <a name="input_ami_id_ssm_parameter_arns"></a> [ami\_id\_ssm\_parameter\_arns](#input\_ami\_id\_ssm\_parameter\_arns) | List of SSM Parameter ARNs that Karpenter controller is allowed read access (for retrieving AMI IDs) | `list(string)` | `[]` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | EKS Cluster Endpoint | `string` | n/a | yes |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. Note: If `ipv6` is specified, the `AmazonEKS_CNI_IPv6_Policy` must exist in the account. This policy is created by the EKS module with `create_cni_ipv6_iam_policy = true` | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_create_access_entry"></a> [create\_access\_entry](#input\_create\_access\_entry) | Determines whether an access entry is created for the IAM role used by the node IAM role, `enable` it when using self managed nodes | `bool` | `true` | no |
| <a name="input_create_aws_observability_ns"></a> [create\_aws\_observability\_ns](#input\_create\_aws\_observability\_ns) | Create aws-observability namespace flag | `bool` | `false` | no |
| <a name="input_create_fargate_log_group"></a> [create\_fargate\_log\_group](#input\_create\_fargate\_log\_group) | create\_fargate\_log\_group flag | `bool` | `true` | no |
| <a name="input_create_fargate_logger_configmap"></a> [create\_fargate\_logger\_configmap](#input\_create\_fargate\_logger\_configmap) | create\_fargate\_logger\_configmap flag | `bool` | `false` | no |
| <a name="input_create_fargate_logging_policy"></a> [create\_fargate\_logging\_policy](#input\_create\_fargate\_logging\_policy) | create\_fargate\_logging\_policy flag | `bool` | `true` | no |
| <a name="input_create_karpenter_fargate_profile"></a> [create\_karpenter\_fargate\_profile](#input\_create\_karpenter\_fargate\_profile) | Create Karpenter Fargate Profile | `bool` | `false` | no |
| <a name="input_enable_inline_policy"></a> [enable\_inline\_policy](#input\_enable\_inline\_policy) | Determines whether the controller policy is created as a standard IAM policy or inline IAM policy. This can be enabled when the error `LimitExceeded: Cannot exceed quota for PolicySize: 6144` is received since standard IAM policies have a limit of 6,144 characters versus an inline role policy's limit of 10,240 ([Reference](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html)) | `bool` | `false` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Determines whether to enable support for IAM role for service accounts | `bool` | `true` | no |
| <a name="input_enable_service_monitoring"></a> [enable\_service\_monitoring](#input\_enable\_service\_monitoring) | Allow scraping of Karpenter metrics | `bool` | `false` | no |
| <a name="input_enable_spot_termination"></a> [enable\_spot\_termination](#input\_enable\_spot\_termination) | Determines whether to enable native spot termination handling | `bool` | `true` | no |
| <a name="input_iam_policy_description"></a> [iam\_policy\_description](#input\_iam\_policy\_description) | IAM policy description | `string` | `"Karpenter controller IAM policy"` | no |
| <a name="input_iam_policy_name"></a> [iam\_policy\_name](#input\_iam\_policy\_name) | Name of the IAM policy | `string` | `"KarpenterController"` | no |
| <a name="input_iam_policy_path"></a> [iam\_policy\_path](#input\_iam\_policy\_path) | Path of the IAM policy | `string` | `"/"` | no |
| <a name="input_iam_policy_statements"></a> [iam\_policy\_statements](#input\_iam\_policy\_statements) | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific IAM permissions as needed | <pre>list(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })))<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })))<br/>    condition = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })))<br/>  }))</pre> | `null` | no |
| <a name="input_iam_policy_use_name_prefix"></a> [iam\_policy\_use\_name\_prefix](#input\_iam\_policy\_use\_name\_prefix) | Determines whether the name of the IAM policy (`iam_policy_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_iam_role_description"></a> [iam\_role\_description](#input\_iam\_role\_description) | IAM role description | `string` | `"Karpenter controller IAM role"` | no |
| <a name="input_iam_role_max_session_duration"></a> [iam\_role\_max\_session\_duration](#input\_iam\_role\_max\_session\_duration) | Maximum API session duration in seconds between 3600 and 43200 | `number` | `null` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | Name of the IAM role | `string` | `"KarpenterController"` | no |
| <a name="input_iam_role_path"></a> [iam\_role\_path](#input\_iam\_role\_path) | Path of the IAM role | `string` | `"/"` | no |
| <a name="input_iam_role_permissions_boundary_arn"></a> [iam\_role\_permissions\_boundary\_arn](#input\_iam\_role\_permissions\_boundary\_arn) | Permissions boundary ARN to use for the IAM role | `string` | `null` | no |
| <a name="input_iam_role_tags"></a> [iam\_role\_tags](#input\_iam\_role\_tags) | A map of additional tags to add the the IAM role | `map(string)` | `{}` | no |
| <a name="input_iam_role_use_name_prefix"></a> [iam\_role\_use\_name\_prefix](#input\_iam\_role\_use\_name\_prefix) | Determines whether the name of the IAM role (`iam_role_name`) is used as a prefix | `bool` | `true` | no |
| <a name="input_irsa_assume_role_condition_test"></a> [irsa\_assume\_role\_condition\_test](#input\_irsa\_assume\_role\_condition\_test) | Name of the [IAM condition operator](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html) to evaluate when assuming the role | `string` | `"StringEquals"` | no |
| <a name="input_karpenter_chart_name"></a> [karpenter\_chart\_name](#input\_karpenter\_chart\_name) | Chart name for Karpenter | `string` | `"karpenter"` | no |
| <a name="input_karpenter_chart_repository"></a> [karpenter\_chart\_repository](#input\_karpenter\_chart\_repository) | Chart repository for Karpenter | `string` | `"oci://public.ecr.aws/karpenter"` | no |
| <a name="input_karpenter_chart_version"></a> [karpenter\_chart\_version](#input\_karpenter\_chart\_version) | Chart version for Karpenter | `string` | `"1.8.1"` | no |
| <a name="input_karpenter_crd_chart_name"></a> [karpenter\_crd\_chart\_name](#input\_karpenter\_crd\_chart\_name) | Chart name for Karpenter | `string` | `"karpenter-crd"` | no |
| <a name="input_karpenter_crd_chart_repository"></a> [karpenter\_crd\_chart\_repository](#input\_karpenter\_crd\_chart\_repository) | Chart repository for Karpenter | `string` | `"oci://public.ecr.aws/karpenter"` | no |
| <a name="input_karpenter_crd_chart_version"></a> [karpenter\_crd\_chart\_version](#input\_karpenter\_crd\_chart\_version) | Chart version for Karpenter | `string` | `"1.8.1"` | no |
| <a name="input_karpenter_crd_namespace"></a> [karpenter\_crd\_namespace](#input\_karpenter\_crd\_namespace) | Namespace to deploy karpenter | `string` | `"kube-system"` | no |
| <a name="input_karpenter_crd_release_name"></a> [karpenter\_crd\_release\_name](#input\_karpenter\_crd\_release\_name) | Release name for Karpenter | `string` | `"karpenter-crd"` | no |
| <a name="input_karpenter_namespace"></a> [karpenter\_namespace](#input\_karpenter\_namespace) | Namespace to deploy karpenter | `string` | `"kube-system"` | no |
| <a name="input_karpenter_nodeclasses"></a> [karpenter\_nodeclasses](#input\_karpenter\_nodeclasses) | List of nodetemplate maps | <pre>list(object({<br/>    nodeclass_name                         = string<br/>    karpenter_subnet_selector_maps         = list(map(any))<br/>    karpenter_security_group_selector_maps = list(map(any))<br/>    karpenter_ami_selector_maps            = list(map(any))<br/>    karpenter_node_role                    = string<br/>    karpenter_node_tags_map                = map(string)<br/>    karpenter_node_user_data               = string<br/>    karpenter_node_metadata_options        = map(any)<br/>    karpenter_node_kubelet                 = map(any)<br/>    karpenter_block_device_mapping = list(object({<br/>      deviceName = string<br/>      ebs = object({<br/>        encrypted           = bool<br/>        volumeSize          = string<br/>        volumeType          = string<br/>        kmsKeyID            = optional(string)<br/>        deleteOnTermination = bool<br/>      })<br/>    }))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "karpenter_ami_selector_maps": [],<br/>    "karpenter_block_device_mapping": [],<br/>    "karpenter_node_kubelet": {},<br/>    "karpenter_node_metadata_options": {<br/>      "httpEndpoint": "enabled",<br/>      "httpProtocolIPv6": "disabled",<br/>      "httpPutResponseHopLimit": 1,<br/>      "httpTokens": "required"<br/>    },<br/>    "karpenter_node_role": "module.eks.worker_iam_role_name",<br/>    "karpenter_node_tags_map": {},<br/>    "karpenter_node_user_data": "",<br/>    "karpenter_security_group_selector_maps": [],<br/>    "karpenter_subnet_selector_maps": [],<br/>    "nodeclass_name": "default"<br/>  }<br/>]</pre> | no |
| <a name="input_karpenter_nodepools"></a> [karpenter\_nodepools](#input\_karpenter\_nodepools) | List of Provisioner maps | <pre>list(object({<br/>    nodepool_name                     = string<br/>    nodeclass_name                    = string<br/>    karpenter_nodepool_node_labels    = map(string)<br/>    karpenter_nodepool_annotations    = map(string)<br/>    karpenter_nodepool_node_taints    = list(map(string))<br/>    karpenter_nodepool_startup_taints = list(map(string))<br/>    karpenter_requirements = list(object({<br/>      key      = string<br/>      operator = string<br/>      values   = list(string)<br/>      })<br/>    )<br/>    karpenter_nodepool_disruption = object({<br/>      consolidation_policy     = string<br/>      consolidate_after        = string<br/>      expire_after             = string<br/>      termination_grace_period = string<br/>    })<br/>    karpenter_nodepool_disruption_budgets = list(map(any))<br/>    karpenter_nodepool_weight             = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "karpenter_nodepool_annotations": {},<br/>    "karpenter_nodepool_disruption": {<br/>      "consolidate_after": "5m",<br/>      "consolidation_policy": "WhenEmptyOrUnderutilized",<br/>      "expire_after": "168h",<br/>      "termination_grace_period": "5h"<br/>    },<br/>    "karpenter_nodepool_disruption_budgets": [<br/>      {<br/>        "nodes": "10%"<br/>      }<br/>    ],<br/>    "karpenter_nodepool_node_labels": {},<br/>    "karpenter_nodepool_node_taints": [],<br/>    "karpenter_nodepool_startup_taints": [],<br/>    "karpenter_nodepool_weight": 10,<br/>    "karpenter_requirements": [<br/>      {<br/>        "key": "karpenter.k8s.aws/instance-category",<br/>        "operator": "In",<br/>        "values": [<br/>          "m"<br/>        ]<br/>      },<br/>      {<br/>        "key": "karpenter.k8s.aws/instance-cpu",<br/>        "operator": "In",<br/>        "values": [<br/>          "4,8,16"<br/>        ]<br/>      },<br/>      {<br/>        "key": "karpenter.k8s.aws/instance-generation",<br/>        "operator": "Gt",<br/>        "values": [<br/>          "5"<br/>        ]<br/>      },<br/>      {<br/>        "key": "karpenter.sh/capacity-type",<br/>        "operator": "In",<br/>        "values": [<br/>          "on-demand"<br/>        ]<br/>      },<br/>      {<br/>        "key": "kubernetes.io/arch",<br/>        "operator": "In",<br/>        "values": [<br/>          "amd64"<br/>        ]<br/>      },<br/>      {<br/>        "key": "kubernetes.io/os",<br/>        "operator": "In",<br/>        "values": [<br/>          "linux"<br/>        ]<br/>      }<br/>    ],<br/>    "nodeclass_name": "default",<br/>    "nodepool_name": "default"<br/>  }<br/>]</pre> | no |
| <a name="input_karpenter_pod_resources"></a> [karpenter\_pod\_resources](#input\_karpenter\_pod\_resources) | Karpenter Pod Resource | <pre>object({<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "1",<br/>    "memory": "2Gi"<br/>  },<br/>  "requests": {<br/>    "cpu": "1",<br/>    "memory": "2Gi"<br/>  }<br/>}</pre> | no |
| <a name="input_karpenter_release_name"></a> [karpenter\_release\_name](#input\_karpenter\_release\_name) | Release name for Karpenter | `string` | `"karpenter"` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of the OIDC Provider for IRSA | `string` | n/a | yes |
| <a name="input_queue_kms_data_key_reuse_period_seconds"></a> [queue\_kms\_data\_key\_reuse\_period\_seconds](#input\_queue\_kms\_data\_key\_reuse\_period\_seconds) | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again | `number` | `null` | no |
| <a name="input_queue_kms_master_key_id"></a> [queue\_kms\_master\_key\_id](#input\_queue\_kms\_master\_key\_id) | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` | no |
| <a name="input_queue_managed_sse_enabled"></a> [queue\_managed\_sse\_enabled](#input\_queue\_managed\_sse\_enabled) | Boolean to enable server-side encryption (SSE) of message content with SQS-owned encryption keys | `bool` | `true` | no |
| <a name="input_queue_name"></a> [queue\_name](#input\_queue\_name) | Name of the SQS queue | `string` | `null` | no |
| <a name="input_queue_policy_statements"></a> [queue\_policy\_statements](#input\_queue\_policy\_statements) | A list of IAM policy [statements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document#statement) - used for adding specific SQS queue policy permissions as needed | <pre>map(object({<br/>    sid           = optional(string)<br/>    actions       = optional(list(string))<br/>    not_actions   = optional(list(string))<br/>    effect        = optional(string)<br/>    resources     = optional(list(string))<br/>    not_resources = optional(list(string))<br/>    principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })))<br/>    not_principals = optional(list(object({<br/>      type        = string<br/>      identifiers = list(string)<br/>    })))<br/>    condition = optional(list(object({<br/>      test     = string<br/>      values   = list(string)<br/>      variable = string<br/>    })))<br/>  }))</pre> | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration | `string` | `null` | no |
| <a name="input_rule_name_prefix"></a> [rule\_name\_prefix](#input\_rule\_name\_prefix) | Prefix used for all event bridge rules | `string` | `"Karpenter"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | For Fargate subnet selection | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#input\_worker\_iam\_role\_arn) | Worker Nodes IAM Role arn | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fargate_profile_pod_execution_role_arn"></a> [fargate\_profile\_pod\_execution\_role\_arn](#output\_fargate\_profile\_pod\_execution\_role\_arn) | Fargate Profile pod execution role ARN |
<!-- END_TF_DOCS -->
