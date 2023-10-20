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


variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`"
  type        = string
  default     = "ipv4"
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

variable "create_fargate_log_group" {
  description = "Create Fargate Cloudwatch Log group"
  type        = bool
  default     = true
}

variable "fargate_log_group_retention_days" {
  description = "Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 90
}

variable "create_fargate_logging_policy" {
  description = "Create and attach fargate logging policy"
  type        = bool
  default     = true
}

variable "fargate_logging_policy_suffix" {
  description = "Name of Fargate Logging Policy"
  type        = string
  default     = "fargate-logging"
}

##################################
### Fargate Selector Namespaces ##
##################################
variable "fargate_namespaces_for_security_group" {
  description = "List of fargate namespaces to craete SecurityGroupPolicy for talking to managed nodes" # remember to `toset` the list before parsing into this variable
  type        = list(string)
  default     = []
}

variable "eks_worker_security_group_id" {
  description = "Security Group ID of the worker nodes"
  type        = string
  default     = ""
}
