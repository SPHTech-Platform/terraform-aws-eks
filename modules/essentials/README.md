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

## To use Karpenter instead of cluster autoscaler [for managed_nodegroups only for now]

> The key difference between nodegroups and fargate profiles Karpenter config is, the latter sets the IAM role at EKS cluster level using Karpenter's Role, while nodegroups gives its IAM roles to the Karpenter to assume. Note the config diff at https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/karpenter

Set the autoscaling mode so that essentials module will skip creation of autoscaler resources
```
module "eks_essentials" {
  autoscaling_mode        = "karpenter"
   # ...
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.70 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.16 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.70 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | >= 2.16 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cluster_autoscaler_irsa_role"></a> [cluster\_autoscaler\_irsa\_role](#module\_cluster\_autoscaler\_irsa\_role) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.47 |
| <a name="module_helm_fluent_bit"></a> [helm\_fluent\_bit](#module\_helm\_fluent\_bit) | SPHTech-Platform/release/helm | ~> 0.1.4 |
| <a name="module_helm_kube_state_metrics"></a> [helm\_kube\_state\_metrics](#module\_helm\_kube\_state\_metrics) | SPHTech-Platform/release/helm | ~> 0.1.4 |
| <a name="module_helm_metrics_server"></a> [helm\_metrics\_server](#module\_helm\_metrics\_server) | SPHTech-Platform/release/helm | ~> 0.1.4 |
| <a name="module_helm_node_exporter"></a> [helm\_node\_exporter](#module\_helm\_node\_exporter) | SPHTech-Platform/release/helm | ~> 0.1.4 |
| <a name="module_node_termination_handler_irsa"></a> [node\_termination\_handler\_irsa](#module\_node\_termination\_handler\_irsa) | terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks | ~> 5.47 |
| <a name="module_node_termination_handler_sqs"></a> [node\_termination\_handler\_sqs](#module\_node\_termination\_handler\_sqs) | terraform-aws-modules/sqs/aws | ~> 4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.node_termination_handler_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.node_termination_handler_spot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_cloudwatch_log_group.aws_for_fluent_bit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecr_pull_through_cache_rule.cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_pull_through_cache_rule) | resource |
| [aws_eks_addon.adot_operator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_iam_policy.ecr_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.fluent_bit_irsa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role_policy_attachment.worker_ecr_pullthrough](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [helm_release.brupop](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.brupop_crd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cert_manager](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.node_termination_handler](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_annotations.gp2_storage_class](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/annotations) | resource |
| [kubernetes_namespace_v1.namespaces](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |
| [kubernetes_pod_disruption_budget_v1.coredns](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/pod_disruption_budget_v1) | resource |
| [kubernetes_storage_class_v1.default](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/storage_class_v1) | resource |
| [aws_arn.node_termination_handler_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_addon_version.latest_adot](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_addon_version) | data source |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_policy_document.ecr_cache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.fluent_bit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.node_termination_handler_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_sqs_queue.node_termination_handler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/sqs_queue) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adot_addon_version"></a> [adot\_addon\_version](#input\_adot\_addon\_version) | value of the adot addon version | `string` | `null` | no |
| <a name="input_affinity"></a> [affinity](#input\_affinity) | Pod affinity | `map(string)` | `{}` | no |
| <a name="input_autoscaling_mode"></a> [autoscaling\_mode](#input\_autoscaling\_mode) | Autoscaling mode: cluster\_autoscaler or karpenter | `string` | `"cluster_autoscaler"` | no |
| <a name="input_brupop_chart_name"></a> [brupop\_chart\_name](#input\_brupop\_chart\_name) | Chart name for brupop | `string` | `"bottlerocket-update-operator"` | no |
| <a name="input_brupop_chart_repository"></a> [brupop\_chart\_repository](#input\_brupop\_chart\_repository) | Chart repository for brupop | `string` | `"https://bottlerocket-os.github.io/bottlerocket-update-operator"` | no |
| <a name="input_brupop_chart_version"></a> [brupop\_chart\_version](#input\_brupop\_chart\_version) | Chart version for brupop | `string` | `"1.4.0"` | no |
| <a name="input_brupop_crd_apiserver_service_port"></a> [brupop\_crd\_apiserver\_service\_port](#input\_brupop\_crd\_apiserver\_service\_port) | API server service port for brupop CRD | `number` | `443` | no |
| <a name="input_brupop_crd_chart_name"></a> [brupop\_crd\_chart\_name](#input\_brupop\_crd\_chart\_name) | Chart name for brupop CRD | `string` | `"bottlerocket-shadow"` | no |
| <a name="input_brupop_crd_chart_repository"></a> [brupop\_crd\_chart\_repository](#input\_brupop\_crd\_chart\_repository) | Chart repository for brupop | `string` | `"https://bottlerocket-os.github.io/bottlerocket-update-operator"` | no |
| <a name="input_brupop_crd_chart_version"></a> [brupop\_crd\_chart\_version](#input\_brupop\_crd\_chart\_version) | Chart version for brupop CRD | `string` | `"1.0.0"` | no |
| <a name="input_brupop_crd_release_name"></a> [brupop\_crd\_release\_name](#input\_brupop\_crd\_release\_name) | Release name for brupop CRD | `string` | `"brupop-crd"` | no |
| <a name="input_brupop_enabled"></a> [brupop\_enabled](#input\_brupop\_enabled) | Enable Bottle Rocket Update Operator | `bool` | `false` | no |
| <a name="input_brupop_image"></a> [brupop\_image](#input\_brupop\_image) | Docker image for brupop | `string` | `"public.ecr.aws/bottlerocket/bottlerocket-update-operator"` | no |
| <a name="input_brupop_namespace"></a> [brupop\_namespace](#input\_brupop\_namespace) | Namespace for all resources under bottlerocket update operator | `string` | `"brupop-bottlerocket-aws"` | no |
| <a name="input_brupop_release_name"></a> [brupop\_release\_name](#input\_brupop\_release\_name) | Release name for brupop | `string` | `"brupop-operator"` | no |
| <a name="input_brupop_tag"></a> [brupop\_tag](#input\_brupop\_tag) | Docker image tag for brupop. This should correspond to the Kubernetes version | `string` | `"v1.4.0"` | no |
| <a name="input_ca_injector_affinity"></a> [ca\_injector\_affinity](#input\_ca\_injector\_affinity) | Affinity for ca\_injector | `map(string)` | `{}` | no |
| <a name="input_ca_injector_container_security_context"></a> [ca\_injector\_container\_security\_context](#input\_ca\_injector\_container\_security\_context) | CA Injector Container Security Context | `map(any)` | `{}` | no |
| <a name="input_ca_injector_deployment_annotations"></a> [ca\_injector\_deployment\_annotations](#input\_ca\_injector\_deployment\_annotations) | Extra annotations for ca\_injector deployment | `map(string)` | `{}` | no |
| <a name="input_ca_injector_enabled"></a> [ca\_injector\_enabled](#input\_ca\_injector\_enabled) | Enable CA Injector. | `bool` | `true` | no |
| <a name="input_ca_injector_extra_args"></a> [ca\_injector\_extra\_args](#input\_ca\_injector\_extra\_args) | Extra args for ca\_injector | `any` | `[]` | no |
| <a name="input_ca_injector_image_repository"></a> [ca\_injector\_image\_repository](#input\_ca\_injector\_image\_repository) | Image repository for ca\_injector | `string` | `"quay.io/jetstack/cert-manager-cainjector"` | no |
| <a name="input_ca_injector_image_tag"></a> [ca\_injector\_image\_tag](#input\_ca\_injector\_image\_tag) | Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used. | `any` | `null` | no |
| <a name="input_ca_injector_node_selector"></a> [ca\_injector\_node\_selector](#input\_ca\_injector\_node\_selector) | Node selector for ca\_injector | `map(string)` | `{}` | no |
| <a name="input_ca_injector_pod_annotations"></a> [ca\_injector\_pod\_annotations](#input\_ca\_injector\_pod\_annotations) | Extra annotations for ca\_injector pods | `map(string)` | `{}` | no |
| <a name="input_ca_injector_pod_labels"></a> [ca\_injector\_pod\_labels](#input\_ca\_injector\_pod\_labels) | Extra labels for ca\_injector pods | `map(string)` | `{}` | no |
| <a name="input_ca_injector_replica_count"></a> [ca\_injector\_replica\_count](#input\_ca\_injector\_replica\_count) | Number of replica for injector | `number` | `1` | no |
| <a name="input_ca_injector_resources"></a> [ca\_injector\_resources](#input\_ca\_injector\_resources) | ca\_injector pod resources | `map(any)` | <pre>{<br/>  "limits": {<br/>    "cpu": "100m",<br/>    "memory": "300Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "300Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_ca_injector_security_context"></a> [ca\_injector\_security\_context](#input\_ca\_injector\_security\_context) | CA Injector Pod Security Context | `map(any)` | `{}` | no |
| <a name="input_ca_injector_service_account_annotations"></a> [ca\_injector\_service\_account\_annotations](#input\_ca\_injector\_service\_account\_annotations) | Annotations for ca\_injector service account | `map(string)` | `{}` | no |
| <a name="input_ca_injector_service_account_create"></a> [ca\_injector\_service\_account\_create](#input\_ca\_injector\_service\_account\_create) | Create ca\_injector service account | `bool` | `true` | no |
| <a name="input_ca_injector_service_account_name"></a> [ca\_injector\_service\_account\_name](#input\_ca\_injector\_service\_account\_name) | Name for ca\_injector service account. If not set and create is true, a name is generated using the fullname template | `string` | `""` | no |
| <a name="input_ca_injector_strategy"></a> [ca\_injector\_strategy](#input\_ca\_injector\_strategy) | CA Injector deployment update strategy | `any` | <pre>{<br/>  "rollingUpdate": {<br/>    "maxSurge": 1,<br/>    "maxUnavailable": "50%"<br/>  },<br/>  "type": "RollingUpdate"<br/>}</pre> | no |
| <a name="input_ca_injector_tolerations"></a> [ca\_injector\_tolerations](#input\_ca\_injector\_tolerations) | Tolerations for ca\_injector | `list(any)` | `[]` | no |
| <a name="input_cert_manager_chart_name"></a> [cert\_manager\_chart\_name](#input\_cert\_manager\_chart\_name) | Helm chart name to provision | `string` | `"cert-manager"` | no |
| <a name="input_cert_manager_chart_repository"></a> [cert\_manager\_chart\_repository](#input\_cert\_manager\_chart\_repository) | Helm repository for the chart | `string` | `"https://charts.jetstack.io"` | no |
| <a name="input_cert_manager_chart_timeout"></a> [cert\_manager\_chart\_timeout](#input\_cert\_manager\_chart\_timeout) | Timeout to wait for the Chart to be deployed. | `number` | `300` | no |
| <a name="input_cert_manager_chart_version"></a> [cert\_manager\_chart\_version](#input\_cert\_manager\_chart\_version) | Version of Chart to install. Set to empty to install the latest version | `string` | `"1.15.3"` | no |
| <a name="input_cert_manager_max_history"></a> [cert\_manager\_max\_history](#input\_cert\_manager\_max\_history) | Max History for Helm | `number` | `20` | no |
| <a name="input_cert_manager_release_name"></a> [cert\_manager\_release\_name](#input\_cert\_manager\_release\_name) | Helm release name | `string` | `"cert-manager"` | no |
| <a name="input_certmanager_namespace"></a> [certmanager\_namespace](#input\_certmanager\_namespace) | Namespace to install the chart into | `string` | `"cert-manager"` | no |
| <a name="input_cluster_autoscaler_affinity"></a> [cluster\_autoscaler\_affinity](#input\_cluster\_autoscaler\_affinity) | Affinity for Cluster Autoscaler | `any` | <pre>{<br/>  "nodeAffinity": {<br/>    "requiredDuringSchedulingIgnoredDuringExecution": {<br/>      "nodeSelectorTerms": [<br/>        {<br/>          "matchExpressions": [<br/>            {<br/>              "key": "node.kubernetes.io/lifecycle",<br/>              "operator": "NotIn",<br/>              "values": [<br/>                "spot"<br/>              ]<br/>            }<br/>          ]<br/>        }<br/>      ]<br/>    }<br/>  },<br/>  "podAntiAffinity": {<br/>    "preferredDuringSchedulingIgnoredDuringExecution": [<br/>      {<br/>        "podAffinityTerm": {<br/>          "labelSelector": {<br/>            "matchExpressions": [<br/>              {<br/>                "key": "app.kubernetes.io/instance",<br/>                "operator": "In",<br/>                "values": [<br/>                  "cluster-autoscaler"<br/>                ]<br/>              }<br/>            ]<br/>          },<br/>          "topologyKey": "kubernetes.io/hostname"<br/>        },<br/>        "weight": 100<br/>      }<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_cluster_autoscaler_chart_name"></a> [cluster\_autoscaler\_chart\_name](#input\_cluster\_autoscaler\_chart\_name) | Chart name for Cluster Autoscaler | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_chart_repository"></a> [cluster\_autoscaler\_chart\_repository](#input\_cluster\_autoscaler\_chart\_repository) | Chart repository for Cluster Autoscaler | `string` | `"https://kubernetes.github.io/autoscaler"` | no |
| <a name="input_cluster_autoscaler_chart_version"></a> [cluster\_autoscaler\_chart\_version](#input\_cluster\_autoscaler\_chart\_version) | Chart version for Cluster Autoscaler | `string` | `"9.40.0"` | no |
| <a name="input_cluster_autoscaler_expander"></a> [cluster\_autoscaler\_expander](#input\_cluster\_autoscaler\_expander) | Expander to use for Cluster Autoscaler. See https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-expanders | `string` | `"least-waste"` | no |
| <a name="input_cluster_autoscaler_iam_role"></a> [cluster\_autoscaler\_iam\_role](#input\_cluster\_autoscaler\_iam\_role) | Override name of the IAM role for autoscaler | `string` | `""` | no |
| <a name="input_cluster_autoscaler_image"></a> [cluster\_autoscaler\_image](#input\_cluster\_autoscaler\_image) | Docker image for Cluster Autoscaler | `string` | `"registry.k8s.io/autoscaling/cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_namespace"></a> [cluster\_autoscaler\_namespace](#input\_cluster\_autoscaler\_namespace) | Namespace to deploy the cluster autoscaler | `string` | `"kube-system"` | no |
| <a name="input_cluster_autoscaler_pdb"></a> [cluster\_autoscaler\_pdb](#input\_cluster\_autoscaler\_pdb) | PDB for Cluster AutoScaler | `any` | <pre>{<br/>  "maxUnavailable": 1<br/>}</pre> | no |
| <a name="input_cluster_autoscaler_permissions_boundary"></a> [cluster\_autoscaler\_permissions\_boundary](#input\_cluster\_autoscaler\_permissions\_boundary) | Permissions boundary ARN to use for autoscaler's IAM role | `string` | `null` | no |
| <a name="input_cluster_autoscaler_pod_annotations"></a> [cluster\_autoscaler\_pod\_annotations](#input\_cluster\_autoscaler\_pod\_annotations) | Pod annotations for Cluster Autoscaler | `map(string)` | <pre>{<br/>  "scheduler.alpha.kubernetes.io/critical-pod": ""<br/>}</pre> | no |
| <a name="input_cluster_autoscaler_pod_labels"></a> [cluster\_autoscaler\_pod\_labels](#input\_cluster\_autoscaler\_pod\_labels) | Pod Labels for Cluster Autoscaler | `map(string)` | `{}` | no |
| <a name="input_cluster_autoscaler_priority_class"></a> [cluster\_autoscaler\_priority\_class](#input\_cluster\_autoscaler\_priority\_class) | Priority class for Cluster Autoscaler | `string` | `"system-cluster-critical"` | no |
| <a name="input_cluster_autoscaler_release_name"></a> [cluster\_autoscaler\_release\_name](#input\_cluster\_autoscaler\_release\_name) | Release name for Cluster Autoscaler | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_replica"></a> [cluster\_autoscaler\_replica](#input\_cluster\_autoscaler\_replica) | Number of replicas for Cluster Autoscaler | `number` | `2` | no |
| <a name="input_cluster_autoscaler_resources"></a> [cluster\_autoscaler\_resources](#input\_cluster\_autoscaler\_resources) | Resources for Cluster Autoscaler | `any` | <pre>{<br/>  "limits": {<br/>    "memory": "700Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "700Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_cluster_autoscaler_secret_key_ref_name_override"></a> [cluster\_autoscaler\_secret\_key\_ref\_name\_override](#input\_cluster\_autoscaler\_secret\_key\_ref\_name\_override) | Override the name of the secret key ref for Cluster Autoscaler | `string` | `""` | no |
| <a name="input_cluster_autoscaler_service_account_name"></a> [cluster\_autoscaler\_service\_account\_name](#input\_cluster\_autoscaler\_service\_account\_name) | K8S sevice account name for Cluster Autoscaler | `string` | `"cluster-autoscaler"` | no |
| <a name="input_cluster_autoscaler_service_annotations"></a> [cluster\_autoscaler\_service\_annotations](#input\_cluster\_autoscaler\_service\_annotations) | Service annotations for Cluster Autoscaler | `map(string)` | <pre>{<br/>  "prometheus.io/scrape": "true"<br/>}</pre> | no |
| <a name="input_cluster_autoscaler_tag"></a> [cluster\_autoscaler\_tag](#input\_cluster\_autoscaler\_tag) | Docker image tag for Cluster Autoscaler. This should correspond to the Kubernetes version | `string` | `"v1.31.0"` | no |
| <a name="input_cluster_autoscaler_tolerations"></a> [cluster\_autoscaler\_tolerations](#input\_cluster\_autoscaler\_tolerations) | Tolerations for Cluster Autoscaler | `any` | `[]` | no |
| <a name="input_cluster_autoscaler_topology_spread_constraints"></a> [cluster\_autoscaler\_topology\_spread\_constraints](#input\_cluster\_autoscaler\_topology\_spread\_constraints) | Topology spread constraints for Cluster Autoscaler | `any` | <pre>[<br/>  {<br/>    "labelSelector": {<br/>      "matchLabels": {<br/>        "app.kubernetes.io/instance": "cluster-autoscaler"<br/>      }<br/>    },<br/>    "maxSkew": 1,<br/>    "topologyKey": "topology.kubernetes.io/zone",<br/>    "whenUnsatisfiable": "DoNotSchedule"<br/>  }<br/>]</pre> | no |
| <a name="input_cluster_autoscaler_vpa"></a> [cluster\_autoscaler\_vpa](#input\_cluster\_autoscaler\_vpa) | VPA for Cluster AutoScaler | `any` | <pre>{<br/>  "containerPolicy": {},<br/>  "enabled": false,<br/>  "updateMode": "Auto"<br/>}</pre> | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | EKS Cluster name | `string` | n/a | yes |
| <a name="input_cluster_resource_namespace"></a> [cluster\_resource\_namespace](#input\_cluster\_resource\_namespace) | Override the namespace used to store DNS provider credentials etc. for ClusterIssuer resources. By default, the same namespace as cert-manager is deployed within is used. This namespace will not be automatically created by the Helm chart. | `string` | `""` | no |
| <a name="input_configure_ecr_pull_through"></a> [configure\_ecr\_pull\_through](#input\_configure\_ecr\_pull\_through) | Configure ECR Pull Through Cache. | `bool` | `true` | no |
| <a name="input_container_security_context"></a> [container\_security\_context](#input\_container\_security\_context) | Configure container security context | `map(string)` | `{}` | no |
| <a name="input_coredns_pdb_max_unavailable"></a> [coredns\_pdb\_max\_unavailable](#input\_coredns\_pdb\_max\_unavailable) | PDB max unavailable CoreDNS pods. | `number` | `1` | no |
| <a name="input_crds_enabled"></a> [crds\_enabled](#input\_crds\_enabled) | Install CRDs with chart | `bool` | `true` | no |
| <a name="input_crds_keep"></a> [crds\_keep](#input\_crds\_keep) | Keep cert-manager custom resources | `bool` | `true` | no |
| <a name="input_create_node_termination_handler_sqs"></a> [create\_node\_termination\_handler\_sqs](#input\_create\_node\_termination\_handler\_sqs) | Whether to create node\_termination\_handler\_sqs. | `bool` | `false` | no |
| <a name="input_create_pdb_for_coredns"></a> [create\_pdb\_for\_coredns](#input\_create\_pdb\_for\_coredns) | Create PDB for CoreDNS | `bool` | `false` | no |
| <a name="input_csi_allow_volume_expansion"></a> [csi\_allow\_volume\_expansion](#input\_csi\_allow\_volume\_expansion) | Allow volume expansion in the StorageClass for CSI. Can be true or false | `bool` | `true` | no |
| <a name="input_csi_default_storage_class"></a> [csi\_default\_storage\_class](#input\_csi\_default\_storage\_class) | Set the CSI StorageClass as the default storage class | `bool` | `true` | no |
| <a name="input_csi_encryption_enable"></a> [csi\_encryption\_enable](#input\_csi\_encryption\_enable) | Enable encryption for CSI Storage Class | `bool` | `true` | no |
| <a name="input_csi_encryption_key_id"></a> [csi\_encryption\_key\_id](#input\_csi\_encryption\_key\_id) | Encryption key for the CSI Storage Class | `string` | `""` | no |
| <a name="input_csi_parameters_override"></a> [csi\_parameters\_override](#input\_csi\_parameters\_override) | Parameters for the StorageClass for Raft.<br/>For AWS EBS see https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs<br/>for AWS EBS CSI driver see https://github.com/kubernetes-sigs/aws-ebs-csi-driver#createvolume-parameters | `any` | <pre>{<br/>  "type": "gp3"<br/>}</pre> | no |
| <a name="input_csi_reclaim_policy"></a> [csi\_reclaim\_policy](#input\_csi\_reclaim\_policy) | Reclaim policy of the StorageClass for CSI. Can be Delete or Retain | `string` | `"Delete"` | no |
| <a name="input_csi_storage_class"></a> [csi\_storage\_class](#input\_csi\_storage\_class) | CSI Storage Class name | `string` | `"ebs-csi"` | no |
| <a name="input_csi_volume_binding_mode"></a> [csi\_volume\_binding\_mode](#input\_csi\_volume\_binding\_mode) | Volume binding mode of the StorageClass for CSI. Can be Immediate or WaitForFirstConsumer | `string` | `"WaitForFirstConsumer"` | no |
| <a name="input_deployment_annotations"></a> [deployment\_annotations](#input\_deployment\_annotations) | Extra annotations for the deployment | `map(string)` | `{}` | no |
| <a name="input_ecr_cache_iam_cache_policy"></a> [ecr\_cache\_iam\_cache\_policy](#input\_ecr\_cache\_iam\_cache\_policy) | Name of ECR Cache IAM Policy | `string` | `"EcrCachePullThrough"` | no |
| <a name="input_ecr_pull_through_cache_rules"></a> [ecr\_pull\_through\_cache\_rules](#input\_ecr\_pull\_through\_cache\_rules) | ECR Pull Through Cache Rules | <pre>map(object({<br/>    registry = string<br/>    prefix   = string<br/>  }))</pre> | <pre>{<br/>  "aws_public": {<br/>    "prefix": "public.ecr.aws",<br/>    "registry": "public.ecr.aws"<br/>  },<br/>  "kubernetes": {<br/>    "prefix": "registry.k8s.io",<br/>    "registry": "registry.k8s.io"<br/>  },<br/>  "quay": {<br/>    "prefix": "quay.io",<br/>    "registry": "quay.io"<br/>  }<br/>}</pre> | no |
| <a name="input_extra_args"></a> [extra\_args](#input\_extra\_args) | Extra arguments | `list(any)` | `[]` | no |
| <a name="input_extra_env"></a> [extra\_env](#input\_extra\_env) | Extra environment variables | `list(any)` | `[]` | no |
| <a name="input_fargate_cluster"></a> [fargate\_cluster](#input\_fargate\_cluster) | Deploying workloads on Fargate, set this to TRUE | `bool` | `false` | no |
| <a name="input_fargate_mix_node_groups"></a> [fargate\_mix\_node\_groups](#input\_fargate\_mix\_node\_groups) | Deploying mix workloads as in EKS Manage Node Groups and Fragate Node Groups, set this to TRUE | `bool` | `false` | no |
| <a name="input_feature_gates"></a> [feature\_gates](#input\_feature\_gates) | Feature gates to enable on the pod | `list(any)` | `[]` | no |
| <a name="input_fluent_bit_enabled"></a> [fluent\_bit\_enabled](#input\_fluent\_bit\_enabled) | Enable fluent-bit helm charts installation. | `bool` | `true` | no |
| <a name="input_fluent_bit_helm_config"></a> [fluent\_bit\_helm\_config](#input\_fluent\_bit\_helm\_config) | Helm provider config for AWS for Fluent Bit. | `any` | `{}` | no |
| <a name="input_fluent_bit_helm_config_defaults"></a> [fluent\_bit\_helm\_config\_defaults](#input\_fluent\_bit\_helm\_config\_defaults) | Helm provider default config for Fluent Bit. | `any` | <pre>{<br/>  "chart": "fluent-bit",<br/>  "description": "Fluent Bit helm Chart deployment configuration",<br/>  "name": "fluent-bit",<br/>  "namespace": "logging",<br/>  "repository": "https://fluent.github.io/helm-charts",<br/>  "version": "0.47.9"<br/>}</pre> | no |
| <a name="input_fluent_bit_image_repository"></a> [fluent\_bit\_image\_repository](#input\_fluent\_bit\_image\_repository) | Fluent Bit Image repo | `string` | `"public.ecr.aws/aws-observability/aws-for-fluent-bit"` | no |
| <a name="input_fluent_bit_image_tag"></a> [fluent\_bit\_image\_tag](#input\_fluent\_bit\_image\_tag) | Fluent Bit Image tag | `string` | `"2.32.0"` | no |
| <a name="input_fluent_bit_log_group_retention"></a> [fluent\_bit\_log\_group\_retention](#input\_fluent\_bit\_log\_group\_retention) | Number of days to retain the cloudwatch logs | `number` | `30` | no |
| <a name="input_fluent_bit_overwrite_helm_values"></a> [fluent\_bit\_overwrite\_helm\_values](#input\_fluent\_bit\_overwrite\_helm\_values) | helm values for overwrite configuration | `string` | `""` | no |
| <a name="input_fluent_bit_role_policy_arns"></a> [fluent\_bit\_role\_policy\_arns](#input\_fluent\_bit\_role\_policy\_arns) | ARNs of any policies to attach to the IAM role | `map(string)` | `{}` | no |
| <a name="input_helm_release_max_history"></a> [helm\_release\_max\_history](#input\_helm\_release\_max\_history) | The maximum number of history releases to keep track in each Helm release | `number` | `20` | no |
| <a name="input_image_pull_secrets"></a> [image\_pull\_secrets](#input\_image\_pull\_secrets) | Secrets for image pulling | `list(any)` | `[]` | no |
| <a name="input_image_repository"></a> [image\_repository](#input\_image\_repository) | Image repository | `string` | `"quay.io/jetstack/cert-manager-controller"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used. | `string` | `null` | no |
| <a name="input_ingress_shim"></a> [ingress\_shim](#input\_ingress\_shim) | Configure Ingess Shim. See https://cert-manager.io/docs/usage/ingress/ | `map(any)` | `{}` | no |
| <a name="input_ip_dual_stack_enabled"></a> [ip\_dual\_stack\_enabled](#input\_ip\_dual\_stack\_enabled) | Enable essentials to support EKS dual stack cluster | `bool` | `false` | no |
| <a name="input_kube_state_metrics_enabled"></a> [kube\_state\_metrics\_enabled](#input\_kube\_state\_metrics\_enabled) | Enable kube-state-metrics helm charts installation. | `bool` | `true` | no |
| <a name="input_kube_state_metrics_helm_config"></a> [kube\_state\_metrics\_helm\_config](#input\_kube\_state\_metrics\_helm\_config) | Helm provider config for kube-state-metrics. | `any` | `{}` | no |
| <a name="input_kube_state_metrics_helm_config_defaults"></a> [kube\_state\_metrics\_helm\_config\_defaults](#input\_kube\_state\_metrics\_helm\_config\_defaults) | Helm provider default config for kube-state-metrics. | `any` | <pre>{<br/>  "chart": "kube-state-metrics",<br/>  "description": "kube-state-metrics helm Chart deployment configuration",<br/>  "name": "kube-state-metrics",<br/>  "namespace": "kube-system",<br/>  "repository": "https://prometheus-community.github.io/helm-charts",<br/>  "version": "5.25.1"<br/>}</pre> | no |
| <a name="input_kubernetes_annotations"></a> [kubernetes\_annotations](#input\_kubernetes\_annotations) | Annotations for Kubernetes resources | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_kubernetes_labels"></a> [kubernetes\_labels](#input\_kubernetes\_labels) | Labels for resources | `map(string)` | <pre>{<br/>  "app.kubernetes.io/managed-by": "Terraform"<br/>}</pre> | no |
| <a name="input_leader_election_lease_duration"></a> [leader\_election\_lease\_duration](#input\_leader\_election\_lease\_duration) | Duration that non-leader candidates will wait after observing a leadership renewal | `string` | `"60s"` | no |
| <a name="input_leader_election_namespace"></a> [leader\_election\_namespace](#input\_leader\_election\_namespace) | Namespace used for Leader Election ConfigMap | `string` | `"kube-system"` | no |
| <a name="input_leader_election_renew_deadline"></a> [leader\_election\_renew\_deadline](#input\_leader\_election\_renew\_deadline) | Interval between attempts by the acting master to renew a leadership slot before it stops leading | `string` | `"40s"` | no |
| <a name="input_leader_election_retry_period"></a> [leader\_election\_retry\_period](#input\_leader\_election\_retry\_period) | Duration the clients should wait between attempting acquisition and renewal of a leadership. | `string` | `"15s"` | no |
| <a name="input_log_level"></a> [log\_level](#input\_log\_level) | Set the verbosity of cert-manager. Range of 0 - 6 with 6 being the most verbose. | `number` | `2` | no |
| <a name="input_metrics_server_enabled"></a> [metrics\_server\_enabled](#input\_metrics\_server\_enabled) | Enable metrics-server helm charts installation. | `bool` | `true` | no |
| <a name="input_metrics_server_helm_config"></a> [metrics\_server\_helm\_config](#input\_metrics\_server\_helm\_config) | Helm provider config for Metrics Server. | `any` | `{}` | no |
| <a name="input_metrics_server_helm_config_defaults"></a> [metrics\_server\_helm\_config\_defaults](#input\_metrics\_server\_helm\_config\_defaults) | Helm provider default config for Metrics Server. | `any` | <pre>{<br/>  "chart": "metrics-server",<br/>  "description": "Metric server helm Chart deployment configuration",<br/>  "name": "metrics-server",<br/>  "repository": "https://kubernetes-sigs.github.io/metrics-server/",<br/>  "version": "3.12.1"<br/>}</pre> | no |
| <a name="input_mutating_webhook_configuration"></a> [mutating\_webhook\_configuration](#input\_mutating\_webhook\_configuration) | Mutating webhook configuration | `any` | <pre>{<br/>  "namespcaceSelector": {}<br/>}</pre> | no |
| <a name="input_mutating_webhook_configuration_annotations"></a> [mutating\_webhook\_configuration\_annotations](#input\_mutating\_webhook\_configuration\_annotations) | Optional additional annotations to add to the webhook MutatingWebhookConfiguration | `map(string)` | `{}` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | List of namespaces to create | <pre>list(object({<br/>    name        = string<br/>    description = optional(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "description": "For core Kubernetes services",<br/>    "name": "core"<br/>  }<br/>]</pre> | no |
| <a name="input_node_exporter_enabled"></a> [node\_exporter\_enabled](#input\_node\_exporter\_enabled) | Enable prometheus-node-exporters helm charts installation. | `bool` | `true` | no |
| <a name="input_node_exporter_helm_config"></a> [node\_exporter\_helm\_config](#input\_node\_exporter\_helm\_config) | Helm provider config for prometheus-node-exporter. | `any` | `{}` | no |
| <a name="input_node_exporter_helm_config_defaults"></a> [node\_exporter\_helm\_config\_defaults](#input\_node\_exporter\_helm\_config\_defaults) | Helm provider default config for prometheus-node-exporter. | `any` | <pre>{<br/>  "chart": "prometheus-node-exporter",<br/>  "description": "prometheus-node-exporter helm Chart deployment configuration",<br/>  "name": "prometheus-node-exporter",<br/>  "namespace": "kube-system",<br/>  "repository": "https://prometheus-community.github.io/helm-charts",<br/>  "version": "4.39.0"<br/>}</pre> | no |
| <a name="input_node_selector"></a> [node\_selector](#input\_node\_selector) | Node selector for cert-manager-controller pods | `map(string)` | `{}` | no |
| <a name="input_node_termination_handler_chart_name"></a> [node\_termination\_handler\_chart\_name](#input\_node\_termination\_handler\_chart\_name) | Chart name for Node Termination Handler. Repo: https://github.com/aws/eks-charts/tree/master/stable/aws-node-termination-handler | `string` | `"aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_chart_repository_url"></a> [node\_termination\_handler\_chart\_repository\_url](#input\_node\_termination\_handler\_chart\_repository\_url) | Chart Repository URL for Node Termination Handler | `string` | `"https://aws.github.io/eks-charts"` | no |
| <a name="input_node_termination_handler_chart_version"></a> [node\_termination\_handler\_chart\_version](#input\_node\_termination\_handler\_chart\_version) | Chart version for Node Termination Handler | `string` | `"0.21.0"` | no |
| <a name="input_node_termination_handler_cordon_only"></a> [node\_termination\_handler\_cordon\_only](#input\_node\_termination\_handler\_cordon\_only) | Cordon but do not drain nodes upon spot interruption termination notice | `bool` | `false` | no |
| <a name="input_node_termination_handler_dry_run"></a> [node\_termination\_handler\_dry\_run](#input\_node\_termination\_handler\_dry\_run) | Only log calls to kubernetes control plane | `bool` | `false` | no |
| <a name="input_node_termination_handler_enable"></a> [node\_termination\_handler\_enable](#input\_node\_termination\_handler\_enable) | Enable node\_termination\_handler creation. Only needed for self managed node groups. | `bool` | `false` | no |
| <a name="input_node_termination_handler_iam_role"></a> [node\_termination\_handler\_iam\_role](#input\_node\_termination\_handler\_iam\_role) | Override the name of the Node Termination Handler IAM Role | `string` | `""` | no |
| <a name="input_node_termination_handler_image"></a> [node\_termination\_handler\_image](#input\_node\_termination\_handler\_image) | Docker image for Node Termination Handler | `string` | `"public.ecr.aws/aws-ec2/aws-node-termination-handler"` | no |
| <a name="input_node_termination_handler_json_logging"></a> [node\_termination\_handler\_json\_logging](#input\_node\_termination\_handler\_json\_logging) | Log messages in JSON format | `bool` | `true` | no |
| <a name="input_node_termination_handler_metadata_tries"></a> [node\_termination\_handler\_metadata\_tries](#input\_node\_termination\_handler\_metadata\_tries) | Total number of times to try making the metadata request before failing | `number` | `3` | no |
| <a name="input_node_termination_handler_pdb_min_available"></a> [node\_termination\_handler\_pdb\_min\_available](#input\_node\_termination\_handler\_pdb\_min\_available) | Pod Disruption Budget Min Available for Node Termination Handler. | `string` | `1` | no |
| <a name="input_node_termination_handler_permissions_boundary"></a> [node\_termination\_handler\_permissions\_boundary](#input\_node\_termination\_handler\_permissions\_boundary) | IAM Boundary for the Node Termination Handler IAM Role, if any | `string` | `null` | no |
| <a name="input_node_termination_handler_priority_class"></a> [node\_termination\_handler\_priority\_class](#input\_node\_termination\_handler\_priority\_class) | Priority class for Node Termination Handler | `string` | `"system-cluster-critical"` | no |
| <a name="input_node_termination_handler_release_name"></a> [node\_termination\_handler\_release\_name](#input\_node\_termination\_handler\_release\_name) | Release name for Node Termination Handler | `string` | `"node-termination-handler"` | no |
| <a name="input_node_termination_handler_replicas"></a> [node\_termination\_handler\_replicas](#input\_node\_termination\_handler\_replicas) | Number of replicas for Node Termination Handler | `number` | `1` | no |
| <a name="input_node_termination_handler_resources"></a> [node\_termination\_handler\_resources](#input\_node\_termination\_handler\_resources) | Resources for Node Termination Handler | `any` | <pre>{<br/>  "limits": {<br/>    "cpu": "100m",<br/>    "memory": "100Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "100Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_node_termination_handler_scheduled_event_draining_enabled"></a> [node\_termination\_handler\_scheduled\_event\_draining\_enabled](#input\_node\_termination\_handler\_scheduled\_event\_draining\_enabled) | Drain nodes before the maintenance window starts for an EC2 instance scheduled event | `bool` | `false` | no |
| <a name="input_node_termination_handler_spot_event_name"></a> [node\_termination\_handler\_spot\_event\_name](#input\_node\_termination\_handler\_spot\_event\_name) | Override name of the Cloudwatch Event to handle spot termination of nodes | `string` | `""` | no |
| <a name="input_node_termination_handler_spot_interruption_draining_enabled"></a> [node\_termination\_handler\_spot\_interruption\_draining\_enabled](#input\_node\_termination\_handler\_spot\_interruption\_draining\_enabled) | Drain nodes when the spot interruption termination notice is received | `bool` | `true` | no |
| <a name="input_node_termination_handler_sqs_arn"></a> [node\_termination\_handler\_sqs\_arn](#input\_node\_termination\_handler\_sqs\_arn) | ARN of the SQS used in Node Termination Handler | `string` | `null` | no |
| <a name="input_node_termination_handler_sqs_name"></a> [node\_termination\_handler\_sqs\_name](#input\_node\_termination\_handler\_sqs\_name) | Override the name for the SQS used in Node Termination Handler | `string` | `""` | no |
| <a name="input_node_termination_handler_tag"></a> [node\_termination\_handler\_tag](#input\_node\_termination\_handler\_tag) | Docker image tag for Node Termination Handler. This should correspond to the Kubernetes version | `string` | `"v1.22.1"` | no |
| <a name="input_node_termination_handler_taint_node"></a> [node\_termination\_handler\_taint\_node](#input\_node\_termination\_handler\_taint\_node) | Taint node upon spot interruption termination notice | `bool` | `true` | no |
| <a name="input_node_termination_namespace"></a> [node\_termination\_namespace](#input\_node\_termination\_namespace) | Namespace to deploy Node Termination Handler | `string` | `"kube-system"` | no |
| <a name="input_node_termination_service_account"></a> [node\_termination\_service\_account](#input\_node\_termination\_service\_account) | Service account for Node Termination Handler pods | `string` | `"node-termination-handler"` | no |
| <a name="input_oidc_provider_arn"></a> [oidc\_provider\_arn](#input\_oidc\_provider\_arn) | ARN of the OIDC Provider for IRSA | `string` | n/a | yes |
| <a name="input_pod_annotations"></a> [pod\_annotations](#input\_pod\_annotations) | Extra annotations for pods | `map(string)` | `{}` | no |
| <a name="input_pod_labels"></a> [pod\_labels](#input\_pod\_labels) | Extra labels for pods | `map(string)` | `{}` | no |
| <a name="input_priority_class_name"></a> [priority\_class\_name](#input\_priority\_class\_name) | Priority class for all cert-manager pods | `string` | `""` | no |
| <a name="input_prometheus_enabled"></a> [prometheus\_enabled](#input\_prometheus\_enabled) | Enable Prometheus metrics | `bool` | `true` | no |
| <a name="input_psp_apparmor"></a> [psp\_apparmor](#input\_psp\_apparmor) | Use AppArmor with PSP. | `bool` | `true` | no |
| <a name="input_psp_enable"></a> [psp\_enable](#input\_psp\_enable) | Create PodSecurityPolicy | `bool` | `false` | no |
| <a name="input_rbac_create"></a> [rbac\_create](#input\_rbac\_create) | Create RBAC resources | `bool` | `true` | no |
| <a name="input_replica_count"></a> [replica\_count](#input\_replica\_count) | Number of controller replicas | `number` | `1` | no |
| <a name="input_resolve_conflicts_on_create"></a> [resolve\_conflicts\_on\_create](#input\_resolve\_conflicts\_on\_create) | value for resolve\_conflicts\_on\_create for aws\_eks\_addon resource | `string` | `"OVERWRITE"` | no |
| <a name="input_resolve_conflicts_on_update"></a> [resolve\_conflicts\_on\_update](#input\_resolve\_conflicts\_on\_update) | value for resolve\_conflicts\_on\_update for aws\_eks\_addon resource | `string` | `"PRESERVE"` | no |
| <a name="input_resources"></a> [resources](#input\_resources) | Resources for pods | `any` | <pre>{<br/>  "limits": {<br/>    "cpu": "100m",<br/>    "memory": "300Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "300Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_security_context"></a> [security\_context](#input\_security\_context) | Configure pod security context | `map(string)` | `{}` | no |
| <a name="input_service_account_annotations"></a> [service\_account\_annotations](#input\_service\_account\_annotations) | Service acocunt annotations | `map(string)` | `{}` | no |
| <a name="input_service_account_automount_token"></a> [service\_account\_automount\_token](#input\_service\_account\_automount\_token) | Automount API credentials for a Service Account | `bool` | `true` | no |
| <a name="input_service_account_create"></a> [service\_account\_create](#input\_service\_account\_create) | Create service account | `bool` | `true` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | Override the default service account name | `string` | `""` | no |
| <a name="input_startupapicheck_affinity"></a> [startupapicheck\_affinity](#input\_startupapicheck\_affinity) | Affinity for startupapicheck | `map(string)` | `{}` | no |
| <a name="input_startupapicheck_backoff_limit"></a> [startupapicheck\_backoff\_limit](#input\_startupapicheck\_backoff\_limit) | startupapicheck backoff limit | `number` | `4` | no |
| <a name="input_startupapicheck_enabled"></a> [startupapicheck\_enabled](#input\_startupapicheck\_enabled) | Enable startupapicheck | `bool` | `true` | no |
| <a name="input_startupapicheck_extra_args"></a> [startupapicheck\_extra\_args](#input\_startupapicheck\_extra\_args) | Extra args for startupapicheck | `list(any)` | `[]` | no |
| <a name="input_startupapicheck_image_repository"></a> [startupapicheck\_image\_repository](#input\_startupapicheck\_image\_repository) | Image repository for startupapicheck | `string` | `"quay.io/jetstack/cert-manager-ctl"` | no |
| <a name="input_startupapicheck_image_tag"></a> [startupapicheck\_image\_tag](#input\_startupapicheck\_image\_tag) | Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used. | `any` | `null` | no |
| <a name="input_startupapicheck_node_selector"></a> [startupapicheck\_node\_selector](#input\_startupapicheck\_node\_selector) | Node selector for startupapicheck | `map(string)` | `{}` | no |
| <a name="input_startupapicheck_pod_labels"></a> [startupapicheck\_pod\_labels](#input\_startupapicheck\_pod\_labels) | Extra labels for startupapicheck pods | `map(string)` | `{}` | no |
| <a name="input_startupapicheck_resources"></a> [startupapicheck\_resources](#input\_startupapicheck\_resources) | startupapicheck pod resources | `map(any)` | <pre>{<br/>  "limits": {<br/>    "cpu": "10m",<br/>    "memory": "32Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "10m",<br/>    "memory": "32Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_startupapicheck_security_context"></a> [startupapicheck\_security\_context](#input\_startupapicheck\_security\_context) | startupapicheck security context | `map(any)` | <pre>{<br/>  "runAsNonRoot": true<br/>}</pre> | no |
| <a name="input_startupapicheck_timeout"></a> [startupapicheck\_timeout](#input\_startupapicheck\_timeout) | startupapicheck timeout | `string` | `"1m"` | no |
| <a name="input_startupapicheck_tolerations"></a> [startupapicheck\_tolerations](#input\_startupapicheck\_tolerations) | Tolerations for startupapicheck | `any` | `[]` | no |
| <a name="input_strategy"></a> [strategy](#input\_strategy) | Update strategy of deployment | `any` | <pre>{<br/>  "rollingUpdate": {<br/>    "maxSurge": 1,<br/>    "maxUnavailable": "50%"<br/>  },<br/>  "type": "RollingUpdate"<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_tolerations"></a> [tolerations](#input\_tolerations) | Pod tolerations | `list(any)` | `[]` | no |
| <a name="input_validating_webhook_configuration"></a> [validating\_webhook\_configuration](#input\_validating\_webhook\_configuration) | Validating webhook configuration | `any` | <pre>{<br/>  "namespcaceSelector": {<br/>    "matchExpressions": [<br/>      {<br/>        "key": "cert-manager.io/disable-validation",<br/>        "operator": "NotIn",<br/>        "values": [<br/>          "true"<br/>        ]<br/>      }<br/>    ]<br/>  }<br/>}</pre> | no |
| <a name="input_validating_webhook_configuration_annotations"></a> [validating\_webhook\_configuration\_annotations](#input\_validating\_webhook\_configuration\_annotations) | Optional additional annotations to add to the webhook ValidatingWebhookConfiguration | `map(string)` | `{}` | no |
| <a name="input_volume_mounts"></a> [volume\_mounts](#input\_volume\_mounts) | Extra volume mounts for the container | `any` | `[]` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | Extra volumes for the pod | `any` | `[]` | no |
| <a name="input_webhook_affinity"></a> [webhook\_affinity](#input\_webhook\_affinity) | Affinity for webhook | `map(string)` | `{}` | no |
| <a name="input_webhook_deployment_annotations"></a> [webhook\_deployment\_annotations](#input\_webhook\_deployment\_annotations) | Extra annotations for webhook deployment | `map(string)` | `{}` | no |
| <a name="input_webhook_extra_args"></a> [webhook\_extra\_args](#input\_webhook\_extra\_args) | Extra args for webhook | `any` | `[]` | no |
| <a name="input_webhook_host_network"></a> [webhook\_host\_network](#input\_webhook\_host\_network) | Whether webhook should use host network | `bool` | `false` | no |
| <a name="input_webhook_image_repository"></a> [webhook\_image\_repository](#input\_webhook\_image\_repository) | Image repository for webhook | `string` | `"quay.io/jetstack/cert-manager-webhook"` | no |
| <a name="input_webhook_image_tag"></a> [webhook\_image\_tag](#input\_webhook\_image\_tag) | Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used. | `any` | `null` | no |
| <a name="input_webhook_liveness_probe"></a> [webhook\_liveness\_probe](#input\_webhook\_liveness\_probe) | Liveness probe for webhook | `map(any)` | <pre>{<br/>  "failureThreshold": 3,<br/>  "initialDelaySeconds": 60,<br/>  "periodSeconds": 10,<br/>  "successThreshold": 1,<br/>  "timeoutSeconds": 5<br/>}</pre> | no |
| <a name="input_webhook_node_selector"></a> [webhook\_node\_selector](#input\_webhook\_node\_selector) | Node selector for webhook | `map(string)` | `{}` | no |
| <a name="input_webhook_pod_annotations"></a> [webhook\_pod\_annotations](#input\_webhook\_pod\_annotations) | Extra annotations for webhook pods | `map(string)` | `{}` | no |
| <a name="input_webhook_pod_labels"></a> [webhook\_pod\_labels](#input\_webhook\_pod\_labels) | Extra labels for webhook pods | `map(string)` | `{}` | no |
| <a name="input_webhook_port"></a> [webhook\_port](#input\_webhook\_port) | Port used by webhook to listen for request from Kubernetes Master | `number` | `10260` | no |
| <a name="input_webhook_readiness_probe"></a> [webhook\_readiness\_probe](#input\_webhook\_readiness\_probe) | Readiness probe for webhook | `map(any)` | <pre>{<br/>  "failureThreshold": 3,<br/>  "initialDelaySeconds": 5,<br/>  "periodSeconds": 5,<br/>  "successThreshold": 1,<br/>  "timeoutSeconds": 5<br/>}</pre> | no |
| <a name="input_webhook_replica_count"></a> [webhook\_replica\_count](#input\_webhook\_replica\_count) | Number of replicas for webhook | `number` | `1` | no |
| <a name="input_webhook_resources"></a> [webhook\_resources](#input\_webhook\_resources) | Webhook pod resources | `map(any)` | <pre>{<br/>  "limits": {<br/>    "cpu": "100m",<br/>    "memory": "300Mi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "300Mi"<br/>  }<br/>}</pre> | no |
| <a name="input_webhook_security_context"></a> [webhook\_security\_context](#input\_webhook\_security\_context) | Security context for webhook pod | `map(any)` | `{}` | no |
| <a name="input_webhook_service_account_annotations"></a> [webhook\_service\_account\_annotations](#input\_webhook\_service\_account\_annotations) | Annotations for webhook service account | `map(string)` | `{}` | no |
| <a name="input_webhook_service_account_create"></a> [webhook\_service\_account\_create](#input\_webhook\_service\_account\_create) | Create Webhook service account | `bool` | `true` | no |
| <a name="input_webhook_service_account_name"></a> [webhook\_service\_account\_name](#input\_webhook\_service\_account\_name) | Name for webhook service account. If not set and create is true, a name is generated using the fullname template | `string` | `""` | no |
| <a name="input_webhook_timeout_seconds"></a> [webhook\_timeout\_seconds](#input\_webhook\_timeout\_seconds) | Timeout in seconds for webook | `number` | `10` | no |
| <a name="input_webhook_tolerations"></a> [webhook\_tolerations](#input\_webhook\_tolerations) | Tolerations for webhook | `list(any)` | `[]` | no |
| <a name="input_webook_container_security_context"></a> [webook\_container\_security\_context](#input\_webook\_container\_security\_context) | Security context for webhook containers | `map(any)` | `{}` | no |
| <a name="input_webook_strategy"></a> [webook\_strategy](#input\_webook\_strategy) | Update strategy for admission webhook | `any` | <pre>{<br/>  "rollingUpdate": {<br/>    "maxSurge": 1,<br/>    "maxUnavailable": "50%"<br/>  },<br/>  "type": "RollingUpdate"<br/>}</pre> | no |
| <a name="input_worker_iam_role_name"></a> [worker\_iam\_role\_name](#input\_worker\_iam\_role\_name) | Worker Nodes IAM Role name | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_node_termination_handler_sqs_arn"></a> [node\_termination\_handler\_sqs\_arn](#output\_node\_termination\_handler\_sqs\_arn) | ARN of the SQS queue used to handle node termination events |
<!-- END_TF_DOCS -->
