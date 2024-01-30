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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.7 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 1.14 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.7 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 1.14 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | ~> 19.18.0 |
| <a name="module_karpenter-crds"></a> [karpenter-crds](#module\_karpenter-crds) | rpadovani/helm-crds/kubectl | ~> 0.3.0 |
| <a name="module_karpenter_fargate_profile"></a> [karpenter\_fargate\_profile](#module\_karpenter\_fargate\_profile) | ../fargate_profile | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.karpenter_fargate_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_nodeclass](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_nodepool](https://registry.terraform.io/providers/gavinbunney/kubectl/latest/docs/resources/manifest) | resource |
| [aws_iam_policy_document.karpenter_fargate_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | EKS Cluster Endpoint | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_create_aws_observability_ns"></a> [create\_aws\_observability\_ns](#input\_create\_aws\_observability\_ns) | Create aws-observability namespace flag | `bool` | `false` | no |
| <a name="input_create_fargate_log_group"></a> [create\_fargate\_log\_group](#input\_create\_fargate\_log\_group) | create\_fargate\_log\_group flag | `bool` | `true` | no |
| <a name="input_create_fargate_logger_configmap"></a> [create\_fargate\_logger\_configmap](#input\_create\_fargate\_logger\_configmap) | create\_fargate\_logger\_configmap flag | `bool` | `false` | no |
| <a name="input_create_fargate_logging_policy"></a> [create\_fargate\_logging\_policy](#input\_create\_fargate\_logging\_policy) | create\_fargate\_logging\_policy flag | `bool` | `true` | no |
| <a name="input_karpenter_chart_name"></a> [karpenter\_chart\_name](#input\_karpenter\_chart\_name) | Chart name for Karpenter | `string` | `"karpenter"` | no |
| <a name="input_karpenter_chart_repository"></a> [karpenter\_chart\_repository](#input\_karpenter\_chart\_repository) | Chart repository for Karpenter | `string` | `"oci://public.ecr.aws/karpenter"` | no |
| <a name="input_karpenter_chart_version"></a> [karpenter\_chart\_version](#input\_karpenter\_chart\_version) | Chart version for Karpenter | `string` | `"v0.32.1"` | no |
| <a name="input_karpenter_fargate_logging_policy"></a> [karpenter\_fargate\_logging\_policy](#input\_karpenter\_fargate\_logging\_policy) | Name of Fargate Logging Profile Policy | `string` | `"karpenter_fargate_logging_cloudwatch"` | no |
| <a name="input_karpenter_namespace"></a> [karpenter\_namespace](#input\_karpenter\_namespace) | Namespace to deploy karpenter | `string` | `"karpenter"` | no |
| <a name="input_karpenter_nodeclasses"></a> [karpenter\_nodeclasses](#input\_karpenter\_nodeclasses) | List of nodetemplate maps | <pre>list(object({<br>    nodeclass_name                         = string<br>    karpenter_subnet_selector_maps         = list(map(any))<br>    karpenter_security_group_selector_maps = list(map(any))<br>    karpenter_ami_selector_maps            = list(map(any))<br>    karpenter_node_role                    = string<br>    karpenter_node_tags_map                = map(string)<br>    karpenter_ami_family                   = string<br>    karpenter_node_user_data               = string<br>    karpenter_node_metadata_options        = map(any)<br>    karpenter_block_device_mapping = list(object({<br>      deviceName = string<br>      ebs = object({<br>        encrypted           = bool<br>        volumeSize          = string<br>        volumeType          = string<br>        kmsKeyID            = optional(string)<br>        deleteOnTermination = bool<br>      })<br>    }))<br>  }))</pre> | <pre>[<br>  {<br>    "karpenter_ami_family": "Bottlerocket",<br>    "karpenter_ami_selector_maps": [],<br>    "karpenter_block_device_mapping": [],<br>    "karpenter_node_metadata_options": {},<br>    "karpenter_node_role": "module.eks.worker_iam_role_name",<br>    "karpenter_node_tags_map": {},<br>    "karpenter_node_user_data": "",<br>    "karpenter_security_group_selector_maps": [],<br>    "karpenter_subnet_selector_maps": [],<br>    "nodeclass_name": "default"<br>  }<br>]</pre> | no |
| <a name="input_karpenter_nodepools"></a> [karpenter\_nodepools](#input\_karpenter\_nodepools) | List of Provisioner maps | <pre>list(object({<br>    nodepool_name                     = string<br>    nodeclass_name                    = string<br>    karpenter_nodepool_node_labels    = map(string)<br>    karpenter_nodepool_annotations    = map(string)<br>    karpenter_nodepool_node_taints    = list(map(string))<br>    karpenter_nodepool_startup_taints = list(map(string))<br>    karpenter_requirements = list(object({<br>      key      = string<br>      operator = string<br>      values   = list(string)<br>      })<br>    )<br>    karpenter_nodepool_disruption = object({<br>      consolidation_policy = string<br>      consolidate_after    = optional(string)<br>      expire_after         = string<br>    })<br>    karpenter_nodepool_weight = number<br>  }))</pre> | <pre>[<br>  {<br>    "karpenter_nodepool_annotations": {},<br>    "karpenter_nodepool_disruption": {<br>      "consolidation_policy": "WhenUnderutilized",<br>      "expire_after": "168h"<br>    },<br>    "karpenter_nodepool_node_labels": {},<br>    "karpenter_nodepool_node_taints": [],<br>    "karpenter_nodepool_startup_taints": [],<br>    "karpenter_nodepool_weight": 10,<br>    "karpenter_requirements": [<br>      {<br>        "key": "karpenter.k8s.aws/instance-category",<br>        "operator": "In",<br>        "values": [<br>          "m"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.k8s.aws/instance-cpu",<br>        "operator": "In",<br>        "values": [<br>          "4,8,16"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.k8s.aws/instance-generation",<br>        "operator": "Gt",<br>        "values": [<br>          "5"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.sh/capacity-type",<br>        "operator": "In",<br>        "values": [<br>          "on-demand"<br>        ]<br>      },<br>      {<br>        "key": "kubernetes.io/arch",<br>        "operator": "In",<br>        "values": [<br>          "amd64"<br>        ]<br>      },<br>      {<br>        "key": "kubernetes.io/os",<br>        "operator": "In",<br>        "values": [<br>          "linux"<br>        ]<br>      }<br>    ],<br>    "nodeclass_name": "default",<br>    "nodepool_name": "default"<br>  }<br>]</pre> | no |
| <a name="input_karpenter_release_name"></a> [karpenter\_release\_name](#input\_karpenter\_release\_name) | Release name for Karpenter | `string` | `"karpenter"` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of the OIDC Provider for IRSA | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | For Fargate subnet selection | `list(string)` | `[]` | no |
| <a name="input_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#input\_worker\_iam\_role\_arn) | Worker Nodes IAM Role arn | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fargate_profile_pod_execution_role_arn"></a> [fargate\_profile\_pod\_execution\_role\_arn](#output\_fargate\_profile\_pod\_execution\_role\_arn) | Fargate Profile pod execution role ARN |
<!-- END_TF_DOCS -->
