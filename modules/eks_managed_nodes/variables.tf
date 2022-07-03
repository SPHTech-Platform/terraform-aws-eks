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
