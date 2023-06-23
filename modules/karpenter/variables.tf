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
  default     = "v0.27.5"
}

variable "karpenter_provisioners" {
  description = "List of Provisioner maps"
  type = list(object({
    name                              = string
    provider_ref_nodetemplate_name    = string
    karpenter_provisioner_node_labels = map(string)
    karpenter_provisioner_node_taints = list(map(string))
    karpenter_instance_types_list     = list(string)
    karpenter_capacity_type_list      = list(string)
    karpenter_arch_list               = list(string)
  }))
  default = []
  ## Sample Below
  #[{
  #   name                              = "default"
  #   provider_ref_nodetemplate_name    = "default"
  #   karpenter_provisioner_node_labels = {}
  #   karpenter_provisioner_node_taints = []
  #   karpenter_instance_types_list     = ["m5a.xlarge", "m6.xlarge"]
  #   karpenter_capacity_type_list      = ["on-demand"]
  #   karpenter_arch_list               = ["amd64"]
  # }]
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
  default = []
  ## sample below
  # [{
  #   name                                  = "default"
  #   karpenter_subnet_selector_map         = {}
  #   karpenter_security_group_selector_map = {}
  #   karpenter_nodetemplate_tag_map        = {}
  #   karpenter_ami_family                  = "Bottlerocket"
  #   karpenter_root_volume_size            = "5Gi"
  #   karpenter_ephemeral_volume_size       = "50Gi"
  # }]
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

##########
## MODE ##
##########
variable "autoscaling_mode" {
  description = "Autoscaling mode: cluster_autoscaler or karpenter"
  type        = string
  default     = "cluster_autoscaler"
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
  default     = true
}

variable "create_fargate_logger_configmap" {
  description = "create_fargate_logger_configmap flag"
  type        = bool
  default     = true
}
