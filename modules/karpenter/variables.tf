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
  default     = "v0.32.1"
}

variable "karpenter_nodepools" {
  description = "List of Provisioner maps"
  type = list(object({
    nodepool_name                     = string
    nodeclass_name                    = string
    karpenter_nodepool_node_labels    = map(string)
    karpenter_nodepool_annotations    = map(string)
    karpenter_nodepool_node_taints    = list(map(string))
    karpenter_nodepool_startup_taints = list(map(string))
    karpenter_requirements = list(object({
      key      = string
      operator = string
      values   = list(string)
      })
    )
    karpenter_nodepool_disruption = object({
      consolidation_policy = string
      consolidate_after    = optional(string)
      expire_after         = string
    })
    karpenter_nodepool_weight = number
  }))
  default = [{
    nodepool_name                     = "default"
    nodeclass_name                    = "default"
    karpenter_nodepool_node_labels    = {}
    karpenter_nodepool_annotations    = {}
    karpenter_nodepool_node_taints    = []
    karpenter_nodepool_startup_taints = []
    karpenter_requirements = [{
      key      = "karpenter.k8s.aws/instance-category"
      operator = "In"
      values   = ["m"]
      }, {
      key      = "karpenter.k8s.aws/instance-cpu"
      operator = "In"
      values   = ["4,8,16"]
      }, {
      key      = "karpenter.k8s.aws/instance-generation"
      operator = "Gt"
      values   = ["5"]
      }, {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["on-demand"]
      }, {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["amd64"]
      }, {
      key      = "kubernetes.io/os"
      operator = "In"
      values   = ["linux"]
      }
    ]
    karpenter_nodepool_disruption = {
      consolidation_policy = "WhenUnderutilized" # WhenUnderutilized or WhenEmpty
      # consolidate_after    = "10m"               # Only used if consolidation_policy is WhenEmpty
      expire_after = "168h" # 7d | 168h | 1w
    }
    karpenter_nodepool_weight = 10
  }]
}

variable "karpenter_nodeclasses" {
  description = "List of nodetemplate maps"
  type = list(object({
    nodeclass_name                         = string
    karpenter_subnet_selector_maps         = list(map(any))
    karpenter_security_group_selector_maps = list(map(any))
    karpenter_ami_selector_maps            = list(map(any))
    karpenter_node_role                    = string
    karpenter_node_tags_map                = map(string)
    karpenter_ami_family                   = string
    karpenter_node_user_data               = string
    karpenter_node_metadata_options        = map(string)
    karpenter_block_device_mapping = list(object({
      deviceName = string
      ebs = object({
        encrypted           = bool
        volumeSize          = string
        volumeType          = string
        kmsKeyID            = optional(string)
        deleteOnTermination = bool
      })
    }))
  }))
  default = [{
    nodeclass_name                 = "default"
    karpenter_block_device_mapping = []
    karpenter_ami_selector_maps    = []
    karpenter_node_user_data       = ""
    karpenter_node_role            = "module.eks.worker_iam_role_name"
    # Please insert from module user
    # karpenter_subnet_selector_map         =  [{
    #      tags = {
    #    "Name" = "aft-app-ap-southeast*"
    #       },
    #  ]
    # karpenter_security_group_selector_map = [{
    #     "id" = module.eks.worker_security_group_id
    #   }, {
    #     "tags" = {
    #        "Name" = "*Public*",
    #     }
    #  }]
    #   karpenter_nodetemplate_tag_map = {
    #     "karpenter.sh/discovery" = module.eks.cluster_name
    #     "eks:cluster-name"       = module.eks.cluster_name
    #   }
    #  karpenter_node_role = module.eks.worker_iam_role_name
    # karpenter_block_device_mapping = [
    #   {
    #     #karpenter_root_volume_size
    #     "deviceName" = "/dev/xvda"
    #     "ebs" = {
    #       "encrypted"           = true
    #       "volumeSize"          = "5Gi"
    #       "volumeType"          = "gp3"
    #       "kmsKeyID"            = ""
    #       "deleteOnTermination" = true
    #     }
    #     }, {
    #     #karpenter_ephemeral_volume_size
    #     "deviceName" = "/dev/xvdb",
    #     "ebs" = {
    #       "encrypted"           = true
    #       "volumeSize"          = "50Gi"
    #       "volumeType"          = "gp3"
    #       "kmsKeyID"            = ""
    #       "deleteOnTermination" = true
    #     }
    #   }`
    # ]
    karpenter_subnet_selector_maps         = []
    karpenter_security_group_selector_maps = []
    karpenter_node_tags_map                = {}
    karpenter_node_metadata_options        = {}
    karpenter_ami_family                   = "Bottlerocket"
  }]
}

variable "karpenter_provisioners" {
  description = "List of Provisioner maps"
  type = list(object({
    name                              = string
    provider_ref_nodetemplate_name    = string
    karpenter_provisioner_node_labels = map(string)
    karpenter_provisioner_node_taints = list(map(string))
    karpenter_requirements = list(object({
      key      = string
      operator = string
      values   = list(string)
      })
    )
  }))
  default = [{
    name                              = "default"
    provider_ref_nodetemplate_name    = "default"
    karpenter_provisioner_node_labels = {}
    karpenter_provisioner_node_taints = []
    karpenter_requirements = [{
      key      = "karpenter.k8s.aws/instance-category"
      operator = "In"
      values   = ["m"]
      }, {
      key      = "karpenter.k8s.aws/instance-cpu"
      operator = "In"
      values   = ["4,8,16"]
      }, {
      key      = "karpenter.k8s.aws/instance-generation"
      operator = "Gt"
      values   = ["5"]
      }, {
      key      = "karpenter.sh/capacity-type"
      operator = "In"
      values   = ["on-demand"]
      }, {
      key      = "kubernetes.io/arch"
      operator = "In"
      values   = ["amd64"]
      }, {
      key      = "kubernetes.io/os"
      operator = "In"
      values   = ["linux"]
      }
    ]
  }]
}

variable "karpenter_nodetemplates" {
  description = "List of nodetemplate maps"
  type = list(object({
    name                                  = string
    karpenter_subnet_selector_map         = map(string)
    karpenter_security_group_selector_map = map(string)
    karpenter_nodetemplate_tag_map        = map(string)
    karpenter_ami_family                  = string
    karpenter_block_device_mapping = list(object({
      deviceName = string
      ebs = object({
        encrypted           = bool
        volumeSize          = string
        volumeType          = string
        kmsKeyID            = optional(string)
        deleteOnTermination = bool
      })
    }))
  }))
  default = [{
    name                           = "default"
    karpenter_subnet_selector_map  = {}
    karpenter_block_device_mapping = []
    # Please insert from module user
    # karpenter_subnet_selector_map         = {
    #   "Name" = "aft-app-ap-southeast*"
    # }
    # karpenter_security_group_selector_map = {
    #     "aws-ids" = module.eks.worker_security_group_id
    #   }
    #   karpenter_nodetemplate_tag_map = {
    #     "karpenter.sh/discovery" = module.eks.cluster_name
    #     "eks:cluster-name"       = module.eks.cluster_name
    #   }
    # karpenter_block_device_mapping = [
    #   {
    #     #karpenter_root_volume_size
    #     "deviceName" = "/dev/xvda"
    #     "ebs" = {
    #       "encrypted"           = true
    #       "volumeSize"          = "5Gi"
    #       "volumeType"          = "gp3"
    #       "kmsKeyID"            = ""
    #       "deleteOnTermination" = true
    #     }
    #     }, {
    #     #karpenter_ephemeral_volume_size
    #     "deviceName" = "/dev/xvdb",
    #     "ebs" = {
    #       "encrypted"           = true
    #       "volumeSize"          = "50Gi"
    #       "volumeType"          = "gp3"
    #       "kmsKeyID"            = ""
    #       "deleteOnTermination" = true
    #     }
    #   }`
    # ]
    karpenter_security_group_selector_map = {}
    karpenter_nodetemplate_tag_map        = {}
    karpenter_ami_family                  = "Bottlerocket"
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
  default     = false
}

variable "create_fargate_logger_configmap" {
  description = "create_fargate_logger_configmap flag"
  type        = bool
  default     = false
}

variable "create_fargate_log_group" {
  description = "create_fargate_log_group flag"
  type        = bool
  default     = true
}

variable "karpenter_fargate_logging_policy" {
  description = "Name of Fargate Logging Profile Policy"
  type        = string
  default     = "karpenter_fargate_logging_cloudwatch"
}

variable "create_fargate_logging_policy" {
  description = "create_fargate_logging_policy flag"
  type        = bool
  default     = true
}

variable "enable_pod_eni" {
  description = "value for enablePodENI"
  type        = bool
  default     = true

}
