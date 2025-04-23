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
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.70 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.16 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | >= 2.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.16 |
| <a name="provider_kubectl"></a> [kubectl](#provider\_kubectl) | >= 2.1 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | terraform-aws-modules/eks/aws//modules/karpenter | ~> 20.33.1 |
| <a name="module_karpenter_fargate_profile"></a> [karpenter\_fargate\_profile](#module\_karpenter\_fargate\_profile) | ../fargate_profile | n/a |

## Resources

| Name | Type |
|------|------|
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_crd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubectl_manifest.karpenter_nodeclass](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |
| [kubectl_manifest.karpenter_nodepool](https://registry.terraform.io/providers/alekc/kubectl/latest/docs/resources/manifest) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_entry_type"></a> [access\_entry\_type](#input\_access\_entry\_type) | Type of the access entry. `EC2_LINUX`, `FARGATE_LINUX`, or `EC2_WINDOWS`; defaults to `EC2_LINUX` | `string` | `"EC2_LINUX"` | no |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | EKS Cluster Endpoint | `string` | n/a | yes |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. Note: If `ipv6` is specified, the `AmazonEKS_CNI_IPv6_Policy` must exist in the account. This policy is created by the EKS module with `create_cni_ipv6_iam_policy = true` | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_create_access_entry"></a> [create\_access\_entry](#input\_create\_access\_entry) | Determines whether an access entry is created for the IAM role used by the node IAM role, `enable` it when using self managed nodes | `bool` | `true` | no |
| <a name="input_create_aws_observability_ns"></a> [create\_aws\_observability\_ns](#input\_create\_aws\_observability\_ns) | Create aws-observability namespace flag | `bool` | `false` | no |
| <a name="input_create_fargate_log_group"></a> [create\_fargate\_log\_group](#input\_create\_fargate\_log\_group) | create\_fargate\_log\_group flag | `bool` | `true` | no |
| <a name="input_create_fargate_logger_configmap"></a> [create\_fargate\_logger\_configmap](#input\_create\_fargate\_logger\_configmap) | create\_fargate\_logger\_configmap flag | `bool` | `false` | no |
| <a name="input_create_fargate_logging_policy"></a> [create\_fargate\_logging\_policy](#input\_create\_fargate\_logging\_policy) | create\_fargate\_logging\_policy flag | `bool` | `true` | no |
| <a name="input_create_karpenter_fargate_profile"></a> [create\_karpenter\_fargate\_profile](#input\_create\_karpenter\_fargate\_profile) | Create Karpenter Fargate Profile | `bool` | `false` | no |
| <a name="input_create_pod_identity_association"></a> [create\_pod\_identity\_association](#input\_create\_pod\_identity\_association) | Determines whether to create pod identity association | `bool` | `false` | no |
| <a name="input_enable_irsa"></a> [enable\_irsa](#input\_enable\_irsa) | Determines whether to enable support for IAM role for service accounts | `bool` | `true` | no |
| <a name="input_enable_pod_identity"></a> [enable\_pod\_identity](#input\_enable\_pod\_identity) | Determines whether to enable support for EKS pod identity, DON'T `enable` if you are using FARGATE profile for Karpenter | `bool` | `false` | no |
| <a name="input_enable_service_monitoring"></a> [enable\_service\_monitoring](#input\_enable\_service\_monitoring) | Allow scraping of Karpenter metrics | `bool` | `false` | no |
| <a name="input_enable_v1_permissions"></a> [enable\_v1\_permissions](#input\_enable\_v1\_permissions) | Determines whether to enable permissions suitable for v1+ (`true`) or for v0.33.x-v0.37.x (`false`) | `bool` | `true` | no |
| <a name="input_karpenter_chart_name"></a> [karpenter\_chart\_name](#input\_karpenter\_chart\_name) | Chart name for Karpenter | `string` | `"karpenter"` | no |
| <a name="input_karpenter_chart_repository"></a> [karpenter\_chart\_repository](#input\_karpenter\_chart\_repository) | Chart repository for Karpenter | `string` | `"oci://public.ecr.aws/karpenter"` | no |
| <a name="input_karpenter_chart_version"></a> [karpenter\_chart\_version](#input\_karpenter\_chart\_version) | Chart version for Karpenter | `string` | `"1.3.3"` | no |
| <a name="input_karpenter_crd_chart_name"></a> [karpenter\_crd\_chart\_name](#input\_karpenter\_crd\_chart\_name) | Chart name for Karpenter | `string` | `"karpenter-crd"` | no |
| <a name="input_karpenter_crd_chart_repository"></a> [karpenter\_crd\_chart\_repository](#input\_karpenter\_crd\_chart\_repository) | Chart repository for Karpenter | `string` | `"oci://public.ecr.aws/karpenter"` | no |
| <a name="input_karpenter_crd_chart_version"></a> [karpenter\_crd\_chart\_version](#input\_karpenter\_crd\_chart\_version) | Chart version for Karpenter | `string` | `"1.3.3"` | no |
| <a name="input_karpenter_crd_namespace"></a> [karpenter\_crd\_namespace](#input\_karpenter\_crd\_namespace) | Namespace to deploy karpenter | `string` | `"kube-system"` | no |
| <a name="input_karpenter_crd_release_name"></a> [karpenter\_crd\_release\_name](#input\_karpenter\_crd\_release\_name) | Release name for Karpenter | `string` | `"karpenter-crd"` | no |
| <a name="input_karpenter_namespace"></a> [karpenter\_namespace](#input\_karpenter\_namespace) | Namespace to deploy karpenter | `string` | `"kube-system"` | no |
| <a name="input_karpenter_nodeclasses"></a> [karpenter\_nodeclasses](#input\_karpenter\_nodeclasses) | List of nodetemplate maps | <pre>list(object({<br/>    nodeclass_name                         = string<br/>    karpenter_subnet_selector_maps         = list(map(any))<br/>    karpenter_security_group_selector_maps = list(map(any))<br/>    karpenter_ami_selector_maps            = list(map(any))<br/>    karpenter_node_role                    = string<br/>    karpenter_node_tags_map                = map(string)<br/>    karpenter_node_user_data               = string<br/>    karpenter_node_metadata_options        = map(any)<br/>    karpenter_node_kubelet_yaml            = map(any)<br/>    karpenter_block_device_mapping = list(object({<br/>      deviceName = string<br/>      ebs = object({<br/>        encrypted           = bool<br/>        volumeSize          = string<br/>        volumeType          = string<br/>        kmsKeyID            = optional(string)<br/>        deleteOnTermination = bool<br/>      })<br/>    }))<br/>  }))</pre> | <pre>[<br/>  {<br/>    "karpenter_ami_selector_maps": [],<br/>    "karpenter_block_device_mapping": [],<br/>    "karpenter_node_kubelet_yaml": {},<br/>    "karpenter_node_metadata_options": {<br/>      "httpEndpoint": "enabled",<br/>      "httpProtocolIPv6": "disabled",<br/>      "httpPutResponseHopLimit": 1,<br/>      "httpTokens": "required"<br/>    },<br/>    "karpenter_node_role": "module.eks.worker_iam_role_name",<br/>    "karpenter_node_tags_map": {},<br/>    "karpenter_node_user_data": "",<br/>    "karpenter_security_group_selector_maps": [],<br/>    "karpenter_subnet_selector_maps": [],<br/>    "nodeclass_name": "default"<br/>  }<br/>]</pre> | no |
| <a name="input_karpenter_nodepools"></a> [karpenter\_nodepools](#input\_karpenter\_nodepools) | List of Provisioner maps | <pre>list(object({<br/>    nodepool_name                     = string<br/>    nodeclass_name                    = string<br/>    karpenter_nodepool_node_labels    = map(string)<br/>    karpenter_nodepool_annotations    = map(string)<br/>    karpenter_nodepool_node_taints    = list(map(string))<br/>    karpenter_nodepool_startup_taints = list(map(string))<br/>    karpenter_requirements = list(object({<br/>      key      = string<br/>      operator = string<br/>      values   = list(string)<br/>      })<br/>    )<br/>    karpenter_nodepool_disruption = object({<br/>      consolidation_policy = string<br/>      consolidate_after    = string<br/>      expire_after         = string<br/>    })<br/>    karpenter_nodepool_disruption_budgets = list(map(any))<br/>    karpenter_nodepool_weight             = number<br/>  }))</pre> | <pre>[<br/>  {<br/>    "karpenter_nodepool_annotations": {},<br/>    "karpenter_nodepool_disruption": {<br/>      "consolidate_after": "5m",<br/>      "consolidation_policy": "WhenEmptyOrUnderutilized",<br/>      "expire_after": "168h"<br/>    },<br/>    "karpenter_nodepool_disruption_budgets": [<br/>      {<br/>        "nodes": "10%"<br/>      }<br/>    ],<br/>    "karpenter_nodepool_node_labels": {},<br/>    "karpenter_nodepool_node_taints": [],<br/>    "karpenter_nodepool_startup_taints": [],<br/>    "karpenter_nodepool_weight": 10,<br/>    "karpenter_requirements": [<br/>      {<br/>        "key": "karpenter.k8s.aws/instance-category",<br/>        "operator": "In",<br/>        "values": [<br/>          "m"<br/>        ]<br/>      },<br/>      {<br/>        "key": "karpenter.k8s.aws/instance-cpu",<br/>        "operator": "In",<br/>        "values": [<br/>          "4,8,16"<br/>        ]<br/>      },<br/>      {<br/>        "key": "karpenter.k8s.aws/instance-generation",<br/>        "operator": "Gt",<br/>        "values": [<br/>          "5"<br/>        ]<br/>      },<br/>      {<br/>        "key": "karpenter.sh/capacity-type",<br/>        "operator": "In",<br/>        "values": [<br/>          "on-demand"<br/>        ]<br/>      },<br/>      {<br/>        "key": "kubernetes.io/arch",<br/>        "operator": "In",<br/>        "values": [<br/>          "amd64"<br/>        ]<br/>      },<br/>      {<br/>        "key": "kubernetes.io/os",<br/>        "operator": "In",<br/>        "values": [<br/>          "linux"<br/>        ]<br/>      }<br/>    ],<br/>    "nodeclass_name": "default",<br/>    "nodepool_name": "default"<br/>  }<br/>]</pre> | no |
| <a name="input_karpenter_pod_resources"></a> [karpenter\_pod\_resources](#input\_karpenter\_pod\_resources) | Karpenter Pod Resource | <pre>object({<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "1",<br/>    "memory": "2Gi"<br/>  },<br/>  "requests": {<br/>    "cpu": "1",<br/>    "memory": "2Gi"<br/>  }<br/>}</pre> | no |
| <a name="input_karpenter_release_name"></a> [karpenter\_release\_name](#input\_karpenter\_release\_name) | Release name for Karpenter | `string` | `"karpenter"` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of the OIDC Provider for IRSA | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | For Fargate subnet selection | `list(string)` | `[]` | no |
| <a name="input_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#input\_worker\_iam\_role\_arn) | Worker Nodes IAM Role arn | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_fargate_profile_pod_execution_role_arn"></a> [fargate\_profile\_pod\_execution\_role\_arn](#output\_fargate\_profile\_pod\_execution\_role\_arn) | Fargate Profile pod execution role ARN |
<!-- END_TF_DOCS -->
