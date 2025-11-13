############################
# K8S Cluster Information
############################
variable "region" {
  description = "Region where the resource(s) will be managed. Defaults to the Region set in the provider configuration"
  type        = string
  default     = null
}

variable "partition" {
  description = "The AWS partition - pass through value to reduce number of GET requests from data sources"
  type        = string
  default     = ""
}

variable "account_id" {
  description = "The AWS account ID - pass through value to reduce number of GET requests from data sources"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Cluster Version"
  type        = string
  default     = "1.27"
}

variable "worker_iam_role_arn" {
  description = "Worker Nodes IAM Role ARN"
  type        = string
}

variable "worker_security_group_id" {
  description = "Security Group ID of the worker nodes"
  type        = string
}

variable "cluster_service_cidr" {
  description = "The CIDR block (IPv4 or IPv6) used by the cluster to assign Kubernetes service IP addresses. This is derived from the cluster itself"
  type        = string
  default     = null
}

####################################
# Node Groups
# Refer to https://github.com/terraform-aws-modules/terraform-aws-eks/blob/master/modules/eks-managed-node-group
# for the parameters supported. See README for more information.
####################################
variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default = {
    update_launch_template_default_version = true
    protect_from_scale_in                  = false

    ebs_optimized     = true
    enable_monitoring = true

    create_iam_role = false
  }
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`"
  type        = string
  default     = "ipv4"
}

############################
# Metadata Server
############################
variable "force_imdsv2" {
  description = "Force IMDSv2 metadata server."
  type        = bool
  default     = true
}

variable "force_irsa" {
  description = "Force usage of IAM Roles for Service Account"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}
