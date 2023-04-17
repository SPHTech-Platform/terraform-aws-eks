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

variable "addon_context" {
  description = "Input configuration for the addon"
  type = object({
    aws_caller_identity_account_id = string
    aws_caller_identity_arn        = string
    aws_eks_cluster_endpoint       = string
    aws_partition_id               = string
    aws_region_name                = string
    eks_cluster_id                 = string
    eks_oidc_issuer_url            = string
    eks_oidc_provider_arn          = string
    tags                           = map(string)
  })
}
