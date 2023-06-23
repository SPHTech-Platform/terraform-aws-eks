############################
# K8S Cluster Information
############################
variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

####################################
# Fargate profiles
# Refer to https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/fargate-profile
# for the parameters supported. See README for more information.
####################################

variable "fargate_profiles" {
  description = "Map of maps of `fargate_profiles` to create"
  type        = any
  default     = {}
}

variable "fargate_profile_defaults" {
  description = "Map of Fargate Profile default configurations"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default     = {}
}

####################
## Fargate Logging #
####################
variable "addon_config" {
  description = "Fargate fluentbit configuration"
  type        = any
  default     = {}
}

variable "create_aws_observability_ns" {
  description = "value to determine if aws-observability namespace is created"
  type        = bool
  default     = true
}

variable "create_fargate_logger_configmap" {
  description = "value to determine if create_fargate_logger_configmap is created"
  type        = bool
  default     = true
}

##################################
### Fargate Selector Namespaces ##
##################################
variable "fargate_namespaces_for_security_group" {
  description = "List of fargate namespaces to craete SecurityGroupPolicy for talking to managed nodes"
  type        = list(string)
  default     = ["kube-system"]
}

variable "eks_worker_security_group_id" {
  description = "Security Group ID of the worker nodes"
  type        = string
}
