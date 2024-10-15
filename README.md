# EKS

## Prerequisites

- VPC with enough IP address space. See [the requirements](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)

## Resources Provisioned

- EKS Cluster
- KMS Key is used to encrypt K8S Secrets
- IAM Role for Service Account is enabled
- KMS Key for EBS volumes is created and ASG is given permission to use the key
- A "default" self managed node group on Bottlerocket is provisioned.

In addition, it is expected that all worker nodes will share one IAM Role and a common security
group.

- IAM Role contains the necessary policies for nodes to join the EKS cluster and optionally manage
  ENI for CNI purposes. IAM Role for Service Account usage is **strongly recommended**.
- The Security Group has default rules to allow the cluster to function. Additional groups can be
  added for additional node groups.

Instance refresh on ASG is handled by [AWS Node Termination Handler](https://github.com/aws/aws-node-termination-handler).
For the purposes of instance refresh, the following resources are created:

- SQS Queue where events published to be consumed by Node Termination Handler is published.

The Queue ARN will be subsequently used by the `eks_self_managed_nodes` module to
provision additional node groups.

## Usage

### Defining Providers

Definining providers in reusable modules is
[deprecated](https://www.terraform.io/language/modules/develop/providers) and causes features like
modules `for_each` and `count` to not work. In addition to the `aws` providers, the main module
and submodules can require additional Kubernetes providers to be configured.

#### Main Module

The main module uses the `kubernetes` provider.

```hcl
provider "aws" {
  # ...
}

module "eks" {
  # ...
  create_aws_auth_configmap = false
  manage_aws_auth_configmap = false # set this to true after cluster creation is completed and reapply to set IRSA
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}
```

#### Sub-modules

Other modules might make use of the `kubernetes` or `helm` providers

```hcl
provider "aws" {
  # ...
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }

  experiments {
    manifest = true
  }
}
```

## Karpenter

We need to allow Karpenter controller to start EC2 instances hence, we need to add role mapping for it:
```
role_mapping = local.autoscaling_mode == "karpenter" ? concat([
    for role in local.eks_master_roles :
    {
      rolearn  = role.arn
      groups   = ["system:masters"]
      username = role.user
    }],
    [
      {
        rolearn = module.eks.worker_iam_role_arn
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
        username = "system:node:{{EC2PrivateDNSName}}"
      }
    ]
    ) : [
    for role in local.eks_master_roles :
    {
      rolearn  = role.arn
      groups   = ["system:masters"]
      username = role.user
    }
  ]
```

Then we create Karpenter module with configuration as follows:

```
locals {
  # Karpenter Provisioners Config
  karpenter_provisioners = [
    {
      name                           = "provisioner_name"
      provider_ref_nodetemplate_name = "default"
      karpenter_provisioner_node_labels = {
        "label_key" = "label_value"
      }

      karpenter_provisioner_node_taints = [
        {
          key       = "taintkey",
          value     = "taintvalue",
          effect    = "NoSchedule"
          timeAdded = timestamp() # required if not terraform plan complains
        }
      ]
    },
  ]
  # Karpenter Nodetemplate Config
  karpenter_nodetemplates = [
    {
      name = "default"
      karpenter_subnet_selector_map = {
        "Name" = "subnet-name-here-*"
      }
      karpenter_security_group_selector_map = {
        "aws-ids" = module.eks.worker_security_group_id
      }
      karpenter_nodetemplate_tag_map = {
        "karpenter.sh/discovery" = module.eks.cluster_name
      }
    },
  ]
}

module "karpenter" {
  # source  = "SPHTech-Platform/eks/aws//modules/essentials"
  # version = "~> 0.8.0"

  source = "git::https://github.com/SPHTech-Platform/terraform-aws-eks.git//modules/karpenter?ref=karpenter"

  cluster_name        = local.cluster_name
  cluster_endpoint    = data.aws_eks_cluster.this.endpoint
  oidc_provider_arn   = module.eks.oidc_provider_arn
  worker_iam_role_arn = module.eks.worker_iam_role_arn

  autoscaling_mode        = local.autoscaling_mode
  karpenter_provisioners  = local.karpenter_provisioners
  karpenter_nodetemplates = local.karpenter_nodetemplates

}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.47 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.6 |
| <a name="requirement_kubectl"></a> [kubectl](#requirement\_kubectl) | 1.14.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.47 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_ebs_csi_irsa_role"></a> [ebs\_csi\_irsa\_role](#module\_ebs\_csi\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.11.2 |
| <a name="module_eks"></a> [eks](#module\_eks) | terraform-aws-modules/eks/aws | ~> 19.21.0 |
| <a name="module_fargate_profiles"></a> [fargate\_profiles](#module\_fargate\_profiles) | ./modules/fargate_profile | n/a |
| <a name="module_karpenter"></a> [karpenter](#module\_karpenter) | ./modules/karpenter | n/a |
| <a name="module_kms_ebs"></a> [kms\_ebs](#module\_kms\_ebs) | SPHTech-Platform/kms/aws | ~> 0.1.0 |
| <a name="module_kms_secret"></a> [kms\_secret](#module\_kms\_secret) | SPHTech-Platform/kms/aws | ~> 0.1.0 |
| <a name="module_node_groups"></a> [node\_groups](#module\_node\_groups) | ./modules/eks_managed_nodes | n/a |
| <a name="module_vpc_cni_irsa_role"></a> [vpc\_cni\_irsa\_role](#module\_vpc\_cni\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.11.2 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.workers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.ebs_csi_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.workers](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_service_linked_role.autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_service_linked_role) | resource |
| [kubernetes_config_map_v1.amazon_vpc_cni](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_manifest.fargate_node_security_group_policy](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.fargate_node_security_group_policy_for_karpenter](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [aws_ami.eks_default_bottlerocket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_arn.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.ec2_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.eks_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_csi_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.kms_ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_subnet.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_karpenter_security_group_ids"></a> [additional\_karpenter\_security\_group\_ids](#input\_additional\_karpenter\_security\_group\_ids) | Additional security group IDs to add to the Karpenter node groups | `list(string)` | `[]` | no |
| <a name="input_autoscaling_mode"></a> [autoscaling\_mode](#input\_autoscaling\_mode) | Autoscaling mode: cluster\_autoscaler or karpenter | `string` | `"karpenter"` | no |
| <a name="input_aws_auth_fargate_profile_pod_execution_role_arns"></a> [aws\_auth\_fargate\_profile\_pod\_execution\_role\_arns](#input\_aws\_auth\_fargate\_profile\_pod\_execution\_role\_arns) | List of Fargate profile pod execution role ARNs to add to the aws-auth configmap | `list(string)` | `[]` | no |
| <a name="input_cloudwatch_log_group_tags"></a> [cloudwatch\_log\_group\_tags](#input\_cloudwatch\_log\_group\_tags) | A map of additional tags to add to the cloudwatch log group created | `map(string)` | `{}` | no |
| <a name="input_cluster_additional_security_group_ids"></a> [cluster\_additional\_security\_group\_ids](#input\_cluster\_additional\_security\_group\_ids) | List of additional, externally created security group IDs to attach to the cluster control plane | `list(string)` | `[]` | no |
| <a name="input_cluster_addons"></a> [cluster\_addons](#input\_cluster\_addons) | Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name` | `any` | `{}` | no |
| <a name="input_cluster_addons_timeouts"></a> [cluster\_addons\_timeouts](#input\_cluster\_addons\_timeouts) | Create, update, and delete timeout configurations for the cluster addons | `map(string)` | `{}` | no |
| <a name="input_cluster_enabled_log_types"></a> [cluster\_enabled\_log\_types](#input\_cluster\_enabled\_log\_types) | A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html) | `list(string)` | <pre>[<br>  "audit",<br>  "api",<br>  "authenticator"<br>]</pre> | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Indicates whether or not the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Indicates whether or not the Amazon EKS public API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access_cidrs"></a> [cluster\_endpoint\_public\_access\_cidrs](#input\_cluster\_endpoint\_public\_access\_cidrs) | List of CIDR blocks which can access the Amazon EKS public API server endpoint | `list(string)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cluster_iam_boundary"></a> [cluster\_iam\_boundary](#input\_cluster\_iam\_boundary) | IAM boundary for the cluster IAM role, if any | `string` | `null` | no |
| <a name="input_cluster_iam_role"></a> [cluster\_iam\_role](#input\_cluster\_iam\_role) | Cluster IAM Role name. If undefined, is the same as the cluster name | `string` | `""` | no |
| <a name="input_cluster_ip_family"></a> [cluster\_ip\_family](#input\_cluster\_ip\_family) | The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. You can only specify an IP family when you create a cluster, changing this value will force a new cluster to be created | `string` | `"ipv4"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster Name | `string` | n/a | yes |
| <a name="input_cluster_security_group_additional_rules"></a> [cluster\_security\_group\_additional\_rules](#input\_cluster\_security\_group\_additional\_rules) | List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source | `any` | `{}` | no |
| <a name="input_cluster_security_group_name"></a> [cluster\_security\_group\_name](#input\_cluster\_security\_group\_name) | Cluster security group name | `string` | `null` | no |
| <a name="input_cluster_service_ipv4_cidr"></a> [cluster\_service\_ipv4\_cidr](#input\_cluster\_service\_ipv4\_cidr) | The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks | `string` | `null` | no |
| <a name="input_cluster_service_ipv6_cidr"></a> [cluster\_service\_ipv6\_cidr](#input\_cluster\_service\_ipv6\_cidr) | The CIDR block to assign Kubernetes pod and service IP addresses from if `ipv6` was specified when the cluster was created. Kubernetes assigns service addresses from the unique local address range (fc00::/7) because you can't specify a custom IPv6 CIDR block when you create the cluster | `string` | `null` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Cluster Version | `string` | `"1.27"` | no |
| <a name="input_create_aws_auth_configmap"></a> [create\_aws\_auth\_configmap](#input\_create\_aws\_auth\_configmap) | Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap` | `bool` | `false` | no |
| <a name="input_create_aws_observability_ns"></a> [create\_aws\_observability\_ns](#input\_create\_aws\_observability\_ns) | Whether to create AWS Observability Namespace. | `bool` | `true` | no |
| <a name="input_create_aws_observability_ns_for_karpenter"></a> [create\_aws\_observability\_ns\_for\_karpenter](#input\_create\_aws\_observability\_ns\_for\_karpenter) | Create aws-observability namespace flag | `bool` | `false` | no |
| <a name="input_create_cluster_security_group"></a> [create\_cluster\_security\_group](#input\_create\_cluster\_security\_group) | Determines if a security group is created for the cluster. Note: the EKS service creates a primary security group for the cluster by default | `bool` | `true` | no |
| <a name="input_create_cni_ipv6_iam_policy"></a> [create\_cni\_ipv6\_iam\_policy](#input\_create\_cni\_ipv6\_iam\_policy) | Whether to create CNI IPv6 IAM policy. | `bool` | `false` | no |
| <a name="input_create_fargate_log_group_for_karpenter"></a> [create\_fargate\_log\_group\_for\_karpenter](#input\_create\_fargate\_log\_group\_for\_karpenter) | value for create\_fargate\_log\_group | `bool` | `false` | no |
| <a name="input_create_fargate_logger_configmap"></a> [create\_fargate\_logger\_configmap](#input\_create\_fargate\_logger\_configmap) | Whether to create AWS Fargate logger configmap. | `bool` | `true` | no |
| <a name="input_create_fargate_logger_configmap_for_karpenter"></a> [create\_fargate\_logger\_configmap\_for\_karpenter](#input\_create\_fargate\_logger\_configmap\_for\_karpenter) | create\_fargate\_logger\_configmap flag | `bool` | `false` | no |
| <a name="input_create_fargate_logging_policy_for_karpenter"></a> [create\_fargate\_logging\_policy\_for\_karpenter](#input\_create\_fargate\_logging\_policy\_for\_karpenter) | value for create\_fargate\_logging\_policy | `bool` | `false` | no |
| <a name="input_create_fargate_profile_for_karpenter"></a> [create\_fargate\_profile\_for\_karpenter](#input\_create\_fargate\_profile\_for\_karpenter) | Create fargate profile flag | `bool` | `false` | no |
| <a name="input_create_node_security_group"></a> [create\_node\_security\_group](#input\_create\_node\_security\_group) | Determines whether to create a security group for the node groups or use the existing `node_security_group_id` | `bool` | `true` | no |
| <a name="input_default_group_ami_id"></a> [default\_group\_ami\_id](#input\_default\_group\_ami\_id) | The AMI from which to launch the defualt group instance. If not supplied, EKS will use its own default image | `string` | `""` | no |
| <a name="input_default_group_instance_types"></a> [default\_group\_instance\_types](#input\_default\_group\_instance\_types) | Instance type for the default node group | `list(string)` | <pre>[<br>  "m5a.xlarge",<br>  "m5.xlarge",<br>  "m5n.xlarge",<br>  "m5zn.xlarge"<br>]</pre> | no |
| <a name="input_default_group_launch_template_name"></a> [default\_group\_launch\_template\_name](#input\_default\_group\_launch\_template\_name) | Name of the default node group launch template | `string` | `"default"` | no |
| <a name="input_default_group_max_size"></a> [default\_group\_max\_size](#input\_default\_group\_max\_size) | Configuration for max default node group size | `number` | `5` | no |
| <a name="input_default_group_min_size"></a> [default\_group\_min\_size](#input\_default\_group\_min\_size) | Configuration for min default node group size | `number` | `1` | no |
| <a name="input_default_group_name"></a> [default\_group\_name](#input\_default\_group\_name) | Name of the default node group | `string` | `"default"` | no |
| <a name="input_default_group_node_labels"></a> [default\_group\_node\_labels](#input\_default\_group\_node\_labels) | Additional node label for default group | `map(string)` | `{}` | no |
| <a name="input_default_group_subnet_ids"></a> [default\_group\_subnet\_ids](#input\_default\_group\_subnet\_ids) | Subnet IDs to create the default group ASGs in | `list(string)` | `[]` | no |
| <a name="input_default_group_volume_size"></a> [default\_group\_volume\_size](#input\_default\_group\_volume\_size) | Size of the persistentence volume for the default group | `number` | `50` | no |
| <a name="input_eks_managed_node_group_defaults"></a> [eks\_managed\_node\_group\_defaults](#input\_eks\_managed\_node\_group\_defaults) | Map of EKS managed node group default configurations | `any` | <pre>{<br>  "create_iam_role": false,<br>  "disk_size": 50,<br>  "ebs_optimized": true,<br>  "enable_monitoring": true,<br>  "metadata_options": {<br>    "http_endpoint": "enabled",<br>    "http_protocol_ipv6": "disabled",<br>    "http_put_response_hop_limit": 1,<br>    "http_tokens": "required",<br>    "instance_metadata_tags": "disabled"<br>  },<br>  "protect_from_scale_in": false,<br>  "update_launch_template_default_version": true<br>}</pre> | no |
| <a name="input_eks_managed_node_groups"></a> [eks\_managed\_node\_groups](#input\_eks\_managed\_node\_groups) | Map of EKS managed node group definitions to create | `any` | `{}` | no |
| <a name="input_enable_cluster_windows_support"></a> [enable\_cluster\_windows\_support](#input\_enable\_cluster\_windows\_support) | Determines whether to create the amazon-vpc-cni configmap and windows worker roles into aws-auth. | `bool` | `false` | no |
| <a name="input_fargate_cluster"></a> [fargate\_cluster](#input\_fargate\_cluster) | Whether to create eks cluster with fargate mode. If true, default node group also will be fargate, otherwise managed | `bool` | `false` | no |
| <a name="input_fargate_profile_defaults"></a> [fargate\_profile\_defaults](#input\_fargate\_profile\_defaults) | Map of Fargate Profile default configurations | `any` | `{}` | no |
| <a name="input_fargate_profiles"></a> [fargate\_profiles](#input\_fargate\_profiles) | Map of maps of `fargate_profiles` to create | `any` | `{}` | no |
| <a name="input_force_imdsv2"></a> [force\_imdsv2](#input\_force\_imdsv2) | Force IMDSv2 metadata server. | `bool` | `true` | no |
| <a name="input_force_irsa"></a> [force\_irsa](#input\_force\_irsa) | Force usage of IAM Roles for Service Account | `bool` | `true` | no |
| <a name="input_iam_role_additional_policies"></a> [iam\_role\_additional\_policies](#input\_iam\_role\_additional\_policies) | Additional policies to be added to the IAM role | `set(string)` | `[]` | no |
| <a name="input_karpenter_chart_version"></a> [karpenter\_chart\_version](#input\_karpenter\_chart\_version) | Chart version for Karpenter | `string` | `"0.37.5"` | no |
| <a name="input_karpenter_crd_chart_version"></a> [karpenter\_crd\_chart\_version](#input\_karpenter\_crd\_chart\_version) | Chart version for Karpenter CRDs same version as `karpenter_chart_version` | `string` | `"0.37.5"` | no |
| <a name="input_karpenter_default_subnet_selector_tags"></a> [karpenter\_default\_subnet\_selector\_tags](#input\_karpenter\_default\_subnet\_selector\_tags) | Subnet selector tags for Karpenter default node class | `map(string)` | <pre>{<br>  "kubernetes.io/role/internal-elb": "1"<br>}</pre> | no |
| <a name="input_karpenter_nodeclasses"></a> [karpenter\_nodeclasses](#input\_karpenter\_nodeclasses) | List of nodetemplate maps | <pre>list(object({<br>    nodeclass_name                         = string<br>    karpenter_subnet_selector_maps         = list(map(any))<br>    karpenter_security_group_selector_maps = list(map(any))<br>    karpenter_ami_selector_maps            = list(map(any))<br>    karpenter_node_role                    = string<br>    karpenter_node_tags_map                = map(string)<br>    karpenter_ami_family                   = string<br>    karpenter_node_user_data               = string<br>    karpenter_node_metadata_options        = map(any)<br>    karpenter_block_device_mapping = list(object({<br>      deviceName = string<br>      ebs = object({<br>        encrypted           = bool<br>        volumeSize          = string<br>        volumeType          = string<br>        kmsKeyID            = optional(string)<br>        deleteOnTermination = bool<br>      })<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_karpenter_nodepools"></a> [karpenter\_nodepools](#input\_karpenter\_nodepools) | List of Provisioner maps | <pre>list(object({<br>    nodepool_name                     = string<br>    nodeclass_name                    = string<br>    karpenter_nodepool_node_labels    = map(string)<br>    karpenter_nodepool_annotations    = map(string)<br>    karpenter_nodepool_node_taints    = list(map(string))<br>    karpenter_nodepool_startup_taints = list(map(string))<br>    karpenter_requirements = list(object({<br>      key      = string<br>      operator = string<br>      values   = list(string)<br>      })<br>    )<br>    karpenter_nodepool_disruption = object({<br>      consolidation_policy = string<br>      consolidate_after    = optional(string)<br>      expire_after         = string<br>    })<br>    karpenter_nodepool_disruption_budgets = list(map(any))<br>    karpenter_nodepool_weight             = number<br>  }))</pre> | <pre>[<br>  {<br>    "karpenter_nodepool_annotations": {},<br>    "karpenter_nodepool_disruption": {<br>      "consolidation_policy": "WhenUnderutilized",<br>      "expire_after": "168h"<br>    },<br>    "karpenter_nodepool_disruption_budgets": [<br>      {<br>        "nodes": "10%"<br>      }<br>    ],<br>    "karpenter_nodepool_node_labels": {},<br>    "karpenter_nodepool_node_taints": [],<br>    "karpenter_nodepool_startup_taints": [],<br>    "karpenter_nodepool_weight": 10,<br>    "karpenter_requirements": [<br>      {<br>        "key": "karpenter.k8s.aws/instance-category",<br>        "operator": "In",<br>        "values": [<br>          "t",<br>          "m"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.k8s.aws/instance-cpu",<br>        "operator": "In",<br>        "values": [<br>          "2",<br>          "4"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.k8s.aws/instance-memory",<br>        "operator": "Gt",<br>        "values": [<br>          "2048"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.k8s.aws/instance-generation",<br>        "operator": "Gt",<br>        "values": [<br>          "2"<br>        ]<br>      },<br>      {<br>        "key": "karpenter.sh/capacity-type",<br>        "operator": "In",<br>        "values": [<br>          "on-demand"<br>        ]<br>      },<br>      {<br>        "key": "kubernetes.io/arch",<br>        "operator": "In",<br>        "values": [<br>          "amd64"<br>        ]<br>      },<br>      {<br>        "key": "kubernetes.io/os",<br>        "operator": "In",<br>        "values": [<br>          "linux"<br>        ]<br>      }<br>    ],<br>    "nodeclass_name": "default",<br>    "nodepool_name": "default"<br>  }<br>]</pre> | no |
| <a name="input_karpenter_pod_resources"></a> [karpenter\_pod\_resources](#input\_karpenter\_pod\_resources) | Karpenter Pod Resource | <pre>object({<br>    requests = object({<br>      cpu    = string<br>      memory = string<br>    })<br>    limits = object({<br>      cpu    = string<br>      memory = string<br>    })<br>  })</pre> | <pre>{<br>  "limits": {<br>    "cpu": "1",<br>    "memory": "2Gi"<br>  },<br>  "requests": {<br>    "cpu": "1",<br>    "memory": "2Gi"<br>  }<br>}</pre> | no |
| <a name="input_karpenter_upgrade"></a> [karpenter\_upgrade](#input\_karpenter\_upgrade) | Karpenter Upgrade | `bool` | `false` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Determines whether to manage the contents of the aws-auth configmap | `bool` | `true` | no |
| <a name="input_node_security_group_additional_rules"></a> [node\_security\_group\_additional\_rules](#input\_node\_security\_group\_additional\_rules) | List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source | `any` | `{}` | no |
| <a name="input_node_security_group_enable_recommended_rules"></a> [node\_security\_group\_enable\_recommended\_rules](#input\_node\_security\_group\_enable\_recommended\_rules) | Determines whether to enable recommended security group rules for the node security group created. This includes node-to-node TCP ingress on ephemeral ports and allows all egress traffic | `bool` | `true` | no |
| <a name="input_only_critical_addons_enabled"></a> [only\_critical\_addons\_enabled](#input\_only\_critical\_addons\_enabled) | Enabling this option will taint default node group with CriticalAddonsOnly=true:NoSchedule taint. Changing this forces a new resource to be created. | `bool` | `false` | no |
| <a name="input_role_mapping"></a> [role\_mapping](#input\_role\_mapping) | List of IAM roles to give access to the EKS cluster | <pre>list(object({<br>    rolearn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_skip_asg_role"></a> [skip\_asg\_role](#input\_skip\_asg\_role) | Skip creating ASG Service Linked Role if it's already created | `bool` | `false` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | A list of subnet IDs where the EKS cluster (ENIs) will be provisioned along with the nodes/node groups. Node groups can be deployed within a different set of subnet IDs from within the node group configuration | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_user_mapping"></a> [user\_mapping](#input\_user\_mapping) | List of IAM Users to give access to the EKS Cluster | <pre>list(object({<br>    userarn  = string<br>    username = string<br>    groups   = list(string)<br>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to deploy the cluster into | `string` | n/a | yes |
| <a name="input_worker_security_group_name"></a> [worker\_security\_group\_name](#input\_worker\_security\_group\_name) | Worker security group name | `string` | `null` | no |
| <a name="input_workers_iam_boundary"></a> [workers\_iam\_boundary](#input\_workers\_iam\_boundary) | IAM boundary for the workers IAM role, if any | `string` | `null` | no |
| <a name="input_workers_iam_role"></a> [workers\_iam\_role](#input\_workers\_iam\_role) | Workers IAM Role name. If undefined, is the same as the cluster name suffixed with 'workers' | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The ARN of the EKS cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 Encoded Cluster CA Data |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint of the EKS Cluster |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM Role ARN used by cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM Role Name used by Cluster |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | EKS Cluster name created |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster for the OpenID Connect identity provider |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | Platform version of the EKS Cluster |
| <a name="output_cluster_primary_security_group_id"></a> [cluster\_primary\_security\_group\_id](#output\_cluster\_primary\_security\_group\_id) | Primary Security Group ID of the EKS cluster |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security Group ID of the master nodes |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | Version of the EKS Cluster |
| <a name="output_ebs_kms_key_arn"></a> [ebs\_kms\_key\_arn](#output\_ebs\_kms\_key\_arn) | KMS Key ARN used for EBS encryption |
| <a name="output_ebs_kms_key_id"></a> [ebs\_kms\_key\_id](#output\_ebs\_kms\_key\_id) | KMS Key ID used for EBS encryption |
| <a name="output_fargate_namespaces_for_security_group"></a> [fargate\_namespaces\_for\_security\_group](#output\_fargate\_namespaces\_for\_security\_group) | value for fargate\_namespaces\_for\_security\_group |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | OIDC Provider ARN for IRSA |
| <a name="output_worker_iam_role_arn"></a> [worker\_iam\_role\_arn](#output\_worker\_iam\_role\_arn) | IAM Role ARN used by worker nodes |
| <a name="output_worker_iam_role_name"></a> [worker\_iam\_role\_name](#output\_worker\_iam\_role\_name) | IAM Role Name used by worker nodes |
| <a name="output_worker_security_group_id"></a> [worker\_security\_group\_id](#output\_worker\_security\_group\_id) | Security Group ID of the worker nodes |
<!-- END_TF_DOCS -->
