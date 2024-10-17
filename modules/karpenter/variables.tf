##################
# Karpenter CRDs #
##################
variable "karpenter_crd_namespace" {
  description = "Namespace to deploy karpenter"
  type        = string
  default     = "kube-system"
}

variable "karpenter_crd_release_name" {
  description = "Release name for Karpenter"
  type        = string
  default     = "karpenter-crd"
}

variable "karpenter_crd_chart_name" {
  description = "Chart name for Karpenter"
  type        = string
  default     = "karpenter-crd"
}

variable "karpenter_crd_chart_repository" {
  description = "Chart repository for Karpenter"
  type        = string
  default     = "oci://public.ecr.aws/karpenter"
}

variable "karpenter_crd_chart_version" {
  description = "Chart version for Karpenter"
  type        = string
  default     = "1.0.6"
}

###############
## Karpenter ##
###############
variable "karpenter_namespace" {
  description = "Namespace to deploy karpenter"
  type        = string
  default     = "kube-system"
}

variable "karpenter_release_name" {
  description = "Release name for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_name" {
  description = "Chart name for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_repository" {
  description = "Chart repository for Karpenter"
  type        = string
  default     = "oci://public.ecr.aws/karpenter"
}

variable "karpenter_chart_version" {
  description = "Chart version for Karpenter"
  type        = string
  default     = "1.0.6"
}

variable "karpenter_nodepools" {
  description = "List of Provisioner maps"
  type = list(object({
    nodepool_name                     = string
    nodeclass_name                    = string
    karpenter_nodepool_node_labels    = map(string)
    karpenter_nodepool_annotations    = map(string)
    karpenter_nodepool_node_taints    = list(map(string))
    karpenter_nodepool_startup_taints = list(map(string))
    karpenter_requirements = list(object({
      key      = string
      operator = string
      values   = list(string)
      })
    )
    karpenter_nodepool_disruption = object({
      consolidation_policy = string
      consolidate_after    = string
      expire_after         = string
    })
    karpenter_nodepool_disruption_budgets = list(map(any))
    karpenter_nodepool_weight             = number
  }))
  default = [{
    nodepool_name                     = "default"
    nodeclass_name                    = "default"
    karpenter_nodepool_node_labels    = {}
    karpenter_nodepool_annotations    = {}
    karpenter_nodepool_node_taints    = []
    karpenter_nodepool_startup_taints = []
    karpenter_requirements = [{
      key      = "karpenter.k8s.aws/instance-category"
      operator = "In"
      values   = ["m"]
      }, {
      key      = "karpenter.k8s.aws/instance-cpu"
      operator = "In"
      values   = ["4,8,16"]
      }, {
      key      = "karpenter.k8s.aws/instance-generation"
      operator = "Gt"
      values   = ["5"]
      }, {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["on-demand"]
      }, {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["amd64"]
      }, {
      key      = "kubernetes.io/os"
      operator = "In"
      values   = ["linux"]
      }
    ]
    karpenter_nodepool_disruption = {
      consolidation_policy = "WhenEmptyOrUnderutilized" # WhenEmpty or WhenEmptyOrUnderutilized
      consolidate_after    = "5m"
      expire_after         = "168h" # 7d | 168h | 1w
    }
    karpenter_nodepool_disruption_budgets = [{
      nodes = "10%"
    }]
    karpenter_nodepool_weight = 10
  }]
}

variable "karpenter_nodeclasses" {
  description = "List of nodetemplate maps"
  type = list(object({
    nodeclass_name                         = string
    karpenter_subnet_selector_maps         = list(map(any))
    karpenter_security_group_selector_maps = list(map(any))
    karpenter_ami_selector_maps            = list(map(any))
    karpenter_node_role                    = string
    karpenter_node_tags_map                = map(string)
    karpenter_node_user_data               = string
    karpenter_node_metadata_options        = map(any)
    karpenter_block_device_mapping = list(object({
      deviceName = string
      ebs = object({
        encrypted           = bool
        volumeSize          = string
        volumeType          = string
        kmsKeyID            = optional(string)
        deleteOnTermination = bool
      })
    }))
  }))
  default = [{
    nodeclass_name                         = "default"
    karpenter_block_device_mapping         = []
    karpenter_ami_selector_maps            = []
    karpenter_node_user_data               = ""
    karpenter_node_role                    = "module.eks.worker_iam_role_name"
    karpenter_subnet_selector_maps         = []
    karpenter_security_group_selector_maps = []
    karpenter_node_tags_map                = {}
    karpenter_node_metadata_options = {
      httpEndpoint            = "enabled"
      httpProtocolIPv6        = "disabled"
      httpPutResponseHopLimit = 1
      httpTokens              = "required"
    }
  }]
}

# TODO - make v1 permssions the default policy at next breaking change
variable "enable_v1_permissions" {
  description = "Determines whether to enable permissions suitable for v1+ (`true`) or for v0.33.x-v0.37.x (`false`)"
  type        = bool
  default     = true
}

############################
# K8S Cluster Information
############################
variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  type        = string
}

variable "worker_iam_role_arn" {
  description = "Worker Nodes IAM Role arn"
  type        = string
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. Note: If `ipv6` is specified, the `AmazonEKS_CNI_IPv6_Policy` must exist in the account. This policy is created by the EKS module with `create_cni_ipv6_iam_policy = true`"
  type        = string
  default     = "ipv4"
}

##############
## FARGATE ###
##############
variable "create_karpenter_fargate_profile" {
  description = "Create Karpenter Fargate Profile"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "For Fargate subnet selection"
  type        = list(string)
  default     = []
}

variable "create_aws_observability_ns" {
  description = "Create aws-observability namespace flag"
  type        = bool
  default     = false
}

variable "create_fargate_logger_configmap" {
  description = "create_fargate_logger_configmap flag"
  type        = bool
  default     = false
}

variable "create_fargate_log_group" {
  description = "create_fargate_log_group flag"
  type        = bool
  default     = true
}

variable "create_fargate_logging_policy" {
  description = "create_fargate_logging_policy flag"
  type        = bool
  default     = true
}

variable "karpenter_pod_resources" {
  description = "Karpenter Pod Resource"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "1"
      memory = "2Gi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
}

###############################################################################
# Pod Identity Association
################################################################################
# TODO - Change default to `true` at next breaking change
variable "create_pod_identity_association" {
  description = "Determines whether to create pod identity association"
  type        = bool
  default     = false
}

variable "enable_pod_identity" {
  description = "Determines whether to enable support for EKS pod identity"
  type        = bool
  default     = false
}
