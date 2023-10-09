############################
# Karpenter
############################

variable "karpenter_namespace" {
  description = "Namespace to deploy karpenter"
  type        = string
  default     = "karpenter"
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
  default     = "v0.31.0"
}

variable "karpenter_provisioners" {
  description = "List of Provisioner maps"
  type = list(object({
    name                              = string
    provider_ref_nodetemplate_name    = string
    karpenter_provisioner_node_labels = map(string)
    karpenter_provisioner_node_taints = list(map(string))
    karpenter_requirements = list(object({
      key      = string
      operator = string
      values   = list(string)
      })
    )
  }))
  default = [{
    name                              = "default"
    provider_ref_nodetemplate_name    = "default"
    karpenter_provisioner_node_labels = {}
    karpenter_provisioner_node_taints = []
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
  }]
}

variable "karpenter_nodetemplates" {
  description = "List of nodetemplate maps"
  type = list(object({
    name                                  = string
    karpenter_subnet_selector_map         = map(string)
    karpenter_security_group_selector_map = map(string)
    karpenter_nodetemplate_tag_map        = map(string)
    karpenter_ami_family                  = string
    karpenter_root_volume_size            = string
    karpenter_ephemeral_volume_size       = string
  }))
  default = [{
    name                          = "default"
    karpenter_subnet_selector_map = {}
    # Please insert from module user
    # karpenter_subnet_selector_map         = {
    #   "Name" = "aft-app-ap-southeast*"
    # }
    # karpenter_security_group_selector_map = {
    #     "aws-ids" = module.eks.worker_security_group_id
    #   }
    #   karpenter_nodetemplate_tag_map = {
    #     "karpenter.sh/discovery" = module.eks.cluster_name
    #     "eks:cluster-name"       = module.eks.cluster_name
    #   }
    karpenter_security_group_selector_map = {}
    karpenter_nodetemplate_tag_map        = {}
    karpenter_ami_family                  = "Bottlerocket"
    karpenter_root_volume_size            = "5Gi"
    karpenter_ephemeral_volume_size       = "50Gi"
  }]
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

##############
## FARGATE ###
##############
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

variable "karpenter_fargate_logging_policy" {
  description = "Name of Fargate Logging Profile Policy"
  type        = string
  default     = "karpenter_fargate_logging_cloudwatch"
}

variable "create_fargate_logging_policy" {
  description = "create_fargate_logging_policy flag"
  type        = bool
  default     = true
}
