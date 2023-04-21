############################
# Karpenter
############################

variable "karpenter_namespace" {
  description = "Namespace to deploy karpenter"
  type        = string
  default     = "karpenter"
}

variable "karpenter_release_name" {
  description = "Release name for Cluster Autoscaler"
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_name" {
  description = "Chart name for Cluster Autoscaler"
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_repository" {
  description = "Chart repository for Cluster Autoscaler"
  type        = string
  default     = "oci://public.ecr.aws/karpenter"
}

variable "karpenter_chart_version" {
  description = "Chart version for Cluster Autoscaler"
  type        = string
  default     = "v0.27.0"
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
  default = [{
    name                              = "default"
    provider_ref_nodetemplate_name    = "default"
    karpenter_provisioner_node_labels = {}
    karpenter_provisioner_node_taints = []
    karpenter_instance_types_list     = ["m5a.xlarge", "m6.xlarge"]
    karpenter_capacity_type_list      = ["on-demand"]
    karpenter_arch_list               = ["amd64"]
  }]
}

variable "karpenter_nodetemplates" {
  description = "List of nodetemplate maps"
  type = list(object({
    name                                  = string
    karpenter_subnet_selector_map         = map(string)
    karpenter_security_group_selector_map = map(string)
    karpenter_nodetemplate_tag_map        = map(string)
  }))
  default = [{
    name                                  = "default"
    karpenter_subnet_selector_map         = {}
    karpenter_security_group_selector_map = {}
    karpenter_nodetemplate_tag_map        = {}
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

##########
## MODE ##
##########
variable "autoscaling_mode" {
  description = "Autoscaling mode: cluster_autoscaler or karpenter"
  type        = string
  default     = "cluster_autoscaler"
}
