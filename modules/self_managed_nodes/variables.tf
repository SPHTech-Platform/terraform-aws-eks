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

variable "worker_iam_instance_profile_arn" {
  description = "Worker Nodes IAM Instance Profile ARN"
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
# Refer to https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/self-managed-node-group
# for the parameters supported. See README for more information.
####################################
variable "self_managed_node_groups" {
  description = "Map of self-managed node group definitions to create"
  type        = any
  default     = {}
}

variable "self_managed_node_group_defaults" {
  description = "Map of self-managed node group default configurations to override the built in defaults"
  type        = any
  default = {
    disk_size = 50

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "disabled"
    }

    instance_refresh = {
      strategy = "Rolling"
    }
    update_launch_template_default_version = true
    protect_from_scale_in                  = false

    create_iam_role       = false
    create_security_group = false
  }
}

############################################
# Instance Refresh/Node Termination Handler
############################################
variable "node_termination_handler_sqs_arn" {
  description = "ARN of the SQS queue used to handle node termination events"
  type        = string
}

variable "node_termination_handler_event_name" {
  description = "Override name of the Cloudwatch Event to handle termination of nodes"
  type        = string
  default     = ""
}
