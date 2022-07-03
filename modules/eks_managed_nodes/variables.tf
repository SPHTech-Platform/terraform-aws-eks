variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}

############################
# K8S Cluster Information
############################
variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "worker_iam_role_arn" {
  description = "Worker Nodes IAM Role ARN"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Security Group ID of the master nodes"
  type        = string
}

variable "worker_security_group_id" {
  description = "Security Group ID of the worker nodes"
  type        = string
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
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
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "disabled"
    }

    update_launch_template_default_version = true
    protect_from_scale_in                  = false

    create_iam_role       = false
    create_security_group = false
  }
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
