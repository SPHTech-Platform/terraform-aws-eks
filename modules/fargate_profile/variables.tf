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
  description = "Map of maps of `eks_node_groups` to create"
  type        = any
  default     = {}
}
