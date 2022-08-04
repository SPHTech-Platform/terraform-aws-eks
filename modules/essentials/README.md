# EKS Essentials

## Usage

### Defining Providers

Definining providers in reusable modules is
[deprecated](https://www.terraform.io/language/modules/develop/providers) and causes features like
modules `for_each` and `count` to not work. In addition to the `aws` providers, the main module
and submodules can require additional Kubernetes providers to be configured.

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

module "eks_essentials" {
  # ...
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.2 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.2 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.10 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler_irsa_role"></a> [cluster\_autoscaler\_irsa\_role](#module\_cluster\_autoscaler\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.21.1 |
| <a name="module_node_termination_handler_irsa"></a> [node\_termination\_handler\_irsa](#module\_node\_termination\_handler\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 4.21.1 |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_pull_through_cache_rule.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_iam_policy.ecr_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.worker_ecr_pullthrough](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_annotations.gp2_storage_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_namespace.namespaces](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_pod_disruption_budget.coredns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod_disruption_budget) | resource |
| [kubernetes_storage_class.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class) | resource |
| [aws_arn.node_termination_handler_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy_document.ecr_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_sqs_queue.node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_autoscaler_affinity"></a> [cluster\_autoscaler\_affinity](#input\_cluster\_autoscaler\_affinity) | Affinity for Cluster Autoscaler | `any` | <pre>{<br>  "nodeAffinity": {<br>    "requiredDuringSchedulingIgnoredDuringExecution": {<br>      "nodeSelectorTerms": [<br>        {<br>          "matchExpressions": [<br>            {<br>              "key": "node.kubernetes.io/lifecycle",<br>              "operator": "NotIn",<br>              "values": [<br>                "spot"<br>              ]<br>            }<br>          ]<br>        }<br>      ]<br>    }<br>  },<br>  "podAntiAffinity": {<br>    "preferredDuringSchedulingIgnoredDuringExecution": [<br>      {<br>        "podAffinityTerm": {<br>          "labelSelector": {<br>            "matchExpressions": [<br>              {<br>                "key": "app.kubernetes.io/instance",<br>                "operator": "In",<br>                "values": [<br>                  "cluster-autoscaler"<br>                ]<br>              }<br>            ]<br>          },<br>          "topologyKey": "kubernetes.io/hostname"<br>        },<br>        "weight": 100<br>      }<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_cluster_autoscaler_chart_name"></a> [cluster\_autoscaler\_chart\_name](#input\_cluster\_autoscaler\_chart\_name) | Chart name for Cluster Autoscaler | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_chart_repository"></a> [cluster\_autoscaler\_chart\_repository](#input\_cluster\_autoscaler\_chart\_repository) | Chart repository for Cluster Autoscaler | `string` | `"https://kubernetes.github.io/autoscaler"` | no |
| <a name="input_cluster_autoscaler_chart_version"></a> [cluster\_autoscaler\_chart\_version](#input\_cluster\_autoscaler\_chart\_version) | Chart version for Cluster Autoscaler | `string` | `"9.15.0"` | no |
| <a name="input_cluster_autoscaler_expander"></a> [cluster\_autoscaler\_expander](#input\_cluster\_autoscaler\_expander) | Expander to use for Cluster Autoscaler. See https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-expanders | `string` | `"least-waste"` | no |
| <a name="input_cluster_autoscaler_iam_role"></a> [cluster\_autoscaler\_iam\_role](#input\_cluster\_autoscaler\_iam\_role) | Override name of the IAM role for autoscaler | `string` | `""` | no |
| <a name="input_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#input\_cluster\_autoscaler\_image) | Docker image for Cluster Autoscaler | `string` | `"asia.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_namespace"></a> [cluster\_autoscaler\_namespace](#input\_cluster\_autoscaler\_namespace) | Namespace to deploy the cluster autoscaler | `string` | `"kube-system"` | no |
| <a name="input_cluster_autoscaler_pdb"></a> [cluster\_autoscaler\_pdb](#input\_cluster\_autoscaler\_pdb) | PDB for Cluster AutoScaler | `any` | <pre>{<br>  "maxUnavailable": 1<br>}</pre> | no |
| <a name="input_cluster_autoscaler_permissions_boundary"></a> [cluster\_autoscaler\_permissions\_boundary](#input\_cluster\_autoscaler\_permissions\_boundary) | Permissions boundary ARN to use for autoscaler's IAM role | `string` | `null` | no |
| <a name="input_cluster_autoscaler_pod_annotations"></a> [cluster\_autoscaler\_pod\_annotations](#input\_cluster\_autoscaler\_pod\_annotations) | Pod annotations for Cluster Autoscaler | `map(string)` | <pre>{<br>  "scheduler.alpha.kubernetes.io/critical-pod": ""<br>}</pre> | no |
| <a name="input_cluster_autoscaler_pod_labels"></a> [cluster\_autoscaler\_pod\_labels](#input\_cluster\_autoscaler\_pod\_labels) | Pod Labels for Cluster Autoscaler | `map(string)` | `{}` | no |
| <a name="input_cluster_autoscaler_priority_class"></a> [cluster\_autoscaler\_priority\_class](#input\_cluster\_autoscaler\_priority\_class) | Priority class for Cluster Autoscaler | `string` | `"system-cluster-critical"` | no |
| <a name="input_cluster_autoscaler_release_name"></a> [cluster\_autoscaler\_release\_name](#input\_cluster\_autoscaler\_release\_name) | Release name for Cluster Autoscaler | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_replica"></a> [cluster\_autoscaler\_replica](#input\_cluster\_autoscaler\_replica) | Number of replicas for Cluster Autoscaler | `number` | `2` | no |
| <a name="input_cluster_autoscaler_resources"></a> [cluster\_autoscaler\_resources](#input\_cluster\_autoscaler\_resources) | Resources for Cluster Autoscaler | `any` | <pre>{<br>  "limits": {<br>    "memory": "700Mi"<br>  },<br>  "requests": {<br>    "cpu": "100m",<br>    "memory": "700Mi"<br>  }<br>}</pre> | no |
| <a name="input_cluster_autoscaler_service_account_name"></a> [cluster\_autoscaler\_service\_account\_name](#input\_cluster\_autoscaler\_service\_account\_name) | K8S sevice account name for Cluster Autoscaler | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_service_annotations"></a> [cluster\_autoscaler\_service\_annotations](#input\_cluster\_autoscaler\_service\_annotations) | Service annotations for Cluster Autoscaler | `map(string)` | <pre>{<br>  "prometheus.io/scrape": "true"<br>}</pre> | no |
| <a name="input_cluster_autoscaler_tag"></a> [cluster\_autoscaler\_tag](#input\_cluster\_autoscaler\_tag) | Docker image tag for Cluster Autoscaler. This should correspond to the Kubernetes version | `string` | `"v1.22.2"` | no |
| <a name="input_cluster_autoscaler_tolerations"></a> [cluster\_autoscaler\_tolerations](#input\_cluster\_autoscaler\_tolerations) | Tolerations for Cluster Autoscaler | `any` | `[]` | no |
| <a name="input_cluster_autoscaler_topology_spread_constraints"></a> [cluster\_autoscaler\_topology\_spread\_constraints](#input\_cluster\_autoscaler\_topology\_spread\_constraints) | Topology spread constraints for Cluster Autoscaler | `any` | <pre>[<br>  {<br>    "labelSelector": {<br>      "matchLabels": {<br>        "app.kubernetes.io/instance": "cluster-autoscaler"<br>      }<br>    },<br>    "maxSkew": 1,<br>    "topologyKey": "topology.kubernetes.io/zone",<br>    "whenUnsatisfiable": "DoNotSchedule"<br>  }<br>]</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_configure_ecr_pull_through"></a> [configure\_ecr\_pull\_through](#input\_configure\_ecr\_pull\_through) | Configure ECR Pull Through Cache. | `bool` | `true` | no |
| <a name="input_coredns_pdb_min_available"></a> [coredns\_pdb\_min\_available](#input\_coredns\_pdb\_min\_available) | PDB min available CoreDNS pods. | `number` | `1` | no |
| <a name="input_csi_allow_volume_expansion"></a> [csi\_allow\_volume\_expansion](#input\_csi\_allow\_volume\_expansion) | Allow volume expansion in the StorageClass for CSI. Can be true or false | `bool` | `true` | no |
| <a name="input_csi_default_storage_class"></a> [csi\_default\_storage\_class](#input\_csi\_default\_storage\_class) | Set the CSI StorageClass as the default storage class | `bool` | `true` | no |
| <a name="input_csi_encryption_enable"></a> [csi\_encryption\_enable](#input\_csi\_encryption\_enable) | Enable encryption for CSI Storage Class | `bool` | `true` | no |
| <a name="input_csi_encryption_key_id"></a> [csi\_encryption\_key\_id](#input\_csi\_encryption\_key\_id) | Encryption key for the CSI Storage Class | `string` | `""` | no |
| <a name="input_csi_parameters_override"></a> [csi\_parameters\_override](#input\_csi\_parameters\_override) | Parameters for the StorageClass for Raft.<br>For AWS EBS see https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs<br>for AWS EBS CSI driver see https://github.com/kubernetes-sigs/aws-ebs-csi-driver#createvolume-parameters | `any` | <pre>{<br>  "type": "gp3"<br>}</pre> | no |
| <a name="input_csi_reclaim_policy"></a> [csi\_reclaim\_policy](#input\_csi\_reclaim\_policy) | Reclaim policy of the StorageClass for CSI. Can be Delete or Retain | `string` | `"Delete"` | no |
| <a name="input_csi_storage_class"></a> [csi\_storage\_class](#input\_csi\_storage\_class) | CSI Storage Class name | `string` | `"ebs-csi"` | no |
| <a name="input_csi_volume_binding_mode"></a> [csi\_volume\_binding\_mode](#input\_csi\_volume\_binding\_mode) | Volume binding mode of the StorageClass for CSI. Can be Immediate or WaitForFirstConsumer | `string` | `"WaitForFirstConsumer"` | no |
| <a name="input_ecr_cache_iam_cache_policy"></a> [ecr\_cache\_iam\_cache\_policy](#input\_ecr\_cache\_iam\_cache\_policy) | Name of ECR Cache IAM Policy | `string` | `"EcrCachePullThrough"` | no |
| <a name="input_ecr_pull_through_cache_rules"></a> [ecr\_pull\_through\_cache\_rules](#input\_ecr\_pull\_through\_cache\_rules) | ECR Pull Through Cache Rules | <pre>map(object({<br>    registry = string<br>    prefix   = string<br>  }))</pre> | <pre>{<br>  "aws_public": {<br>    "prefix": "public.ecr.aws",<br>    "registry": "public.ecr.aws"<br>  },<br>  "quay": {<br>    "prefix": "quay.io",<br>    "registry": "quay.io"<br>  }<br>}</pre> | no |
| <a name="input_helm_release_max_history"></a> [helm\_release\_max\_history](#input\_helm\_release\_max\_history) | The maximum number of history releases to keep track in each Helm release | `number` | `20` | no |
| <a name="input_kubernetes_annotations"></a> [kubernetes\_annotations](#input\_kubernetes\_annotations) | Annotations for Kubernetes resources | `map(string)` | <pre>{<br>  "terraform": "true"<br>}</pre> | no |
| <a name="input_kubernetes_labels"></a> [kubernetes\_labels](#input\_kubernetes\_labels) | Labels for resources | `map(string)` | <pre>{<br>  "app.kubernetes.io/managed-by": "Terraform"<br>}</pre> | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | List of namespaces to create | <pre>list(object({<br>    name        = string<br>    description = optional(string)<br>  }))</pre> | <pre>[<br>  {<br>    "description": "For core Kubernetes services",<br>    "name": "core"<br>  }<br>]</pre> | no |
| <a name="input_node_termination_handler_chart_name"></a> [node\_termination\_handler\_chart\_name](#input\_node\_termination\_handler\_chart\_name) | Chart name for Node Termination Handler. Repo: https://github.com/aws/eks-charts/tree/master/stable/aws-node-termination-handler | `string` | `"aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_chart_repository_url"></a> [node\_termination\_handler\_chart\_repository\_url](#input\_node\_termination\_handler\_chart\_repository\_url) | Chart Repository URL for Node Termination Handler | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_node_termination_handler_chart_version"></a> [node\_termination\_handler\_chart\_version](#input\_node\_termination\_handler\_chart\_version) | Chart version for Node Termination Handler | `string` | `"0.17.0"` | no |
| <a name="input_node_termination_handler_cordon_only"></a> [node\_termination\_handler\_cordon\_only](#input\_node\_termination\_handler\_cordon\_only) | Cordon but do not drain nodes upon spot interruption termination notice | `bool` | `false` | no |
| <a name="input_node_termination_handler_dry_run"></a> [node\_termination\_handler\_dry\_run](#input\_node\_termination\_handler\_dry\_run) | Only log calls to kubernetes control plane | `bool` | `false` | no |
| <a name="input_node_termination_handler_iam_role"></a> [node\_termination\_handler\_iam\_role](#input\_node\_termination\_handler\_iam\_role) | Override the name of the Node Termination Handler IAM Role | `string` | `""` | no |
| <a name="input_node_termination_handler_image"></a> [node\_termination\_handler\_image](#input\_node\_termination\_handler\_image) | Docker image for Node Termination Handler | `string` | `"public.ecr.aws/aws-ec2/aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_json_logging"></a> [node\_termination\_handler\_json\_logging](#input\_node\_termination\_handler\_json\_logging) | Log messages in JSON format | `bool` | `true` | no |
| <a name="input_node_termination_handler_metadata_tries"></a> [node\_termination\_handler\_metadata\_tries](#input\_node\_termination\_handler\_metadata\_tries) | Total number of times to try making the metadata request before failing | `number` | `3` | no |
| <a name="input_node_termination_handler_pdb_min_available"></a> [node\_termination\_handler\_pdb\_min\_available](#input\_node\_termination\_handler\_pdb\_min\_available) | Pod Disruption Budget Min Available for Node Termination Handler. | `string` | `1` | no |
| <a name="input_node_termination_handler_permissions_boundary"></a> [node\_termination\_handler\_permissions\_boundary](#input\_node\_termination\_handler\_permissions\_boundary) | IAM Boundary for the Node Termination Handler IAM Role, if any | `string` | `null` | no |
| <a name="input_node_termination_handler_priority_class"></a> [node\_termination\_handler\_priority\_class](#input\_node\_termination\_handler\_priority\_class) | Priority class for Node Termination Handler | `string` | `"system-cluster-critical"` | no |
| <a name="input_node_termination_handler_release_name"></a> [node\_termination\_handler\_release\_name](#input\_node\_termination\_handler\_release\_name) | Release name for Node Termination Handler | `string` | `"node-termination-handler"` | no |
| <a name="input_node_termination_handler_replicas"></a> [node\_termination\_handler\_replicas](#input\_node\_termination\_handler\_replicas) | Number of replicas for Node Termination Handler | `number` | `1` | no |
| <a name="input_node_termination_handler_resources"></a> [node\_termination\_handler\_resources](#input\_node\_termination\_handler\_resources) | Resources for Node Termination Handler | `any` | <pre>{<br>  "limits": {<br>    "cpu": "100m",<br>    "memory": "100Mi"<br>  },<br>  "requests": {<br>    "cpu": "10m",<br>    "memory": "100Mi"<br>  }<br>}</pre> | no |
| <a name="input_node_termination_handler_scheduled_event_draining_enabled"></a> [node\_termination\_handler\_scheduled\_event\_draining\_enabled](#input\_node\_termination\_handler\_scheduled\_event\_draining\_enabled) | Drain nodes before the maintenance window starts for an EC2 instance scheduled event | `bool` | `false` | no |
| <a name="input_node_termination_handler_spot_interruption_draining_enabled"></a> [node\_termination\_handler\_spot\_interruption\_draining\_enabled](#input\_node\_termination\_handler\_spot\_interruption\_draining\_enabled) | Drain nodes when the spot interruption termination notice is received | `bool` | `true` | no |
| <a name="input_node_termination_handler_sqs_arn"></a> [node\_termination\_handler\_sqs\_arn](#input\_node\_termination\_handler\_sqs\_arn) | ARN of the SQS used in Node Termination Handler | `string` | n/a | yes |
| <a name="input_node_termination_handler_tag"></a> [node\_termination\_handler\_tag](#input\_node\_termination\_handler\_tag) | Docker image tag for Node Termination Handler. This should correspond to the Kubernetes version | `string` | `"v1.16.0"` | no |
| <a name="input_node_termination_handler_taint_node"></a> [node\_termination\_handler\_taint\_node](#input\_node\_termination\_handler\_taint\_node) | Taint node upon spot interruption termination notice | `bool` | `true` | no |
| <a name="input_node_termination_iam_role"></a> [node\_termination\_iam\_role](#input\_node\_termination\_iam\_role) | Name of the IAM Role for Node Termination Handler | `string` | `"bedrock_node_termination_handler"` | no |
| <a name="input_node_termination_iam_role_boundary"></a> [node\_termination\_iam\_role\_boundary](#input\_node\_termination\_iam\_role\_boundary) | IAM Role boundary for Node Termination Handler | `string` | `null` | no |
| <a name="input_node_termination_namespace"></a> [node\_termination\_namespace](#input\_node\_termination\_namespace) | Namespace to deploy Node Termination Handler | `string` | `"kube-system"` | no |
| <a name="input_node_termination_service_account"></a> [node\_termination\_service\_account](#input\_node\_termination\_service\_account) | Service account for Node Termination Handler pods | `string` | `"node-termination-handler"` | no |
| <a name="input_node_termination_sqs"></a> [node\_termination\_sqs](#input\_node\_termination\_sqs) | SQS Queue for node termination handler | <pre>object({<br>    url = string<br>    arn = string<br>  })</pre> | `null` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of the OIDC Provider for IRSA | `string` | n/a | yes |
| <a name="input_worker_iam_role_name"></a> [worker\_iam\_role\_name](#input\_worker\_iam\_role\_name) | Worker Nodes IAM Role name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
