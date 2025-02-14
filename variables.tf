#######################
# EKS Cluster Settings
#######################
variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "cluster_version" {
  description = "EKS Cluster Version"
  type        = string
  default     = "1.31"

  validation {
    condition     = try(tonumber(var.cluster_version) < 1.33, false)
    error_message = "EKS Cluster Version 1.33 is not supported by this module. Please use a version less than 1.33"
  }
}

variable "cluster_enabled_log_types" {
  description = "A list of the desired control plane logs to enable. For more information, see Amazon EKS Control Plane Logging documentation (https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html)"
  type        = list(string)
  default     = ["audit", "api", "authenticator"]
}

variable "authentication_mode" {
  description = "The authentication mode for the cluster. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  type        = string
  default     = "API"

  validation {
    condition     = contains(["CONFIG_MAP", "API", "API_AND_CONFIG_MAP"], var.authentication_mode)
    error_message = "Invalid authentication mode. Valid values are `CONFIG_MAP`, `API` or `API_AND_CONFIG_MAP`"
  }
}

variable "cluster_compute_config" {
  description = "Configuration block for the cluster compute configuration"
  type        = any
  default     = {}
}
#######################
# Cluster IAM Role
#######################
variable "cluster_iam_role" {
  description = "Cluster IAM Role name. If undefined, is the same as the cluster name"
  type        = string
  default     = ""
}

variable "cluster_iam_boundary" {
  description = "IAM boundary for the cluster IAM role, if any"
  type        = string
  default     = null
}

#######################
# Workers IAM Role
#######################
variable "workers_iam_role" {
  description = "Workers IAM Role name. If undefined, is the same as the cluster name suffixed with 'workers'"
  type        = string
  default     = ""
}

variable "workers_iam_boundary" {
  description = "IAM boundary for the workers IAM role, if any"
  type        = string
  default     = null
}

variable "iam_role_additional_policies" {
  description = "Additional policies to be added to the IAM role"
  type        = set(string)
  default     = []
}

#######################
# Cluster RBAC (AWS Auth)
#######################

# For Self managed nodes groups set the create_aws_auth to true
variable "create_aws_auth_configmap" {
  description = "Determines whether to create the aws-auth configmap. NOTE - this is only intended for scenarios where the configmap does not exist (i.e. - when using only self-managed node groups). Most users should use `manage_aws_auth_configmap`"
  type        = bool
  default     = false
}

variable "manage_aws_auth_configmap" {
  description = "Determines whether to manage the contents of the aws-auth configmap. NOTE - make it `true` when `authentication_mode = CONFIG_MAP`"
  type        = bool
  default     = false
}

variable "enable_cluster_windows_support" {
  description = "Determines whether to create the amazon-vpc-cni configmap and windows worker roles into aws-auth."
  type        = bool
  default     = false
}

variable "role_mapping" {
  description = "List of IAM roles to give access to the EKS cluster"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "user_mapping" {
  description = "List of IAM Users to give access to the EKS Cluster"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_fargate_profile_pod_execution_role_arns" {
  description = "List of Fargate profile pod execution role ARNs to add to the aws-auth configmap"
  type        = list(string)
  default     = []
}

#############
# EKS Addons
#############
variable "cluster_addons" {
  description = "Map of cluster addon configurations to enable for the cluster. Addon name can be the map keys or set with `name`"
  type        = any
  default     = {}
}

variable "cluster_addons_timeouts" {
  description = "Create, update, and delete timeout configurations for the cluster addons"
  type        = map(string)
  default     = {}
}

#######################
# Cluster Networking
#######################

variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_additional_security_group_ids" {
  description = "List of additional, externally created security group IDs to attach to the cluster control plane"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID to deploy the cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs where the EKS cluster (ENIs) will be provisioned along with the nodes/node groups. Node groups can be deployed within a different set of subnet IDs from within the node group configuration"
  type        = list(string)
}

variable "cluster_service_ipv4_cidr" {
  description = "The CIDR block to assign Kubernetes service IP addresses from. If you don't specify a block, Kubernetes assigns addresses from either the 10.100.0.0/16 or 172.20.0.0/16 CIDR blocks"
  type        = string
  default     = null
}

variable "create_cluster_security_group" {
  description = "Determines if a security group is created for the cluster. Note: the EKS service creates a primary security group for the cluster by default"
  type        = bool
  default     = true
}

variable "cluster_security_group_name" {
  description = "Cluster security group name"
  type        = string
  default     = null
}

variable "create_node_security_group" {
  description = "Determines whether to create a security group for the node groups or use the existing `node_security_group_id`"
  type        = bool
  default     = true
}

variable "node_security_group_tags" {
  description = "A map of additional tags to add to the node security group created"
  type        = map(string)
  default     = {}
}

variable "worker_security_group_name" {
  description = "Worker security group name"
  type        = string
  default     = null
}

variable "cluster_security_group_additional_rules" {
  description = "List of additional security group rules to add to the cluster security group created. Set `source_node_security_group = true` inside rules to set the `node_security_group` as source"
  type        = any
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "List of additional security group rules to add to the node security group created. Set `source_cluster_security_group = true` inside rules to set the `cluster_security_group` as source"
  type        = any
  default     = {}
}

variable "node_security_group_enable_recommended_rules" {
  description = "Determines whether to enable recommended security group rules for the node security group created. This includes node-to-node TCP ingress on ephemeral ports and allows all egress traffic"
  type        = bool
  default     = true
}

#######################
# Other IAM
#######################
variable "skip_asg_role" {
  description = "Skip creating ASG Service Linked Role if it's already created"
  type        = bool
  default     = false
}

#######################
# Nodes Configuration
# It is recommended that users create their own node pools using the relevant submodules
# at https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
# after the EKS cluster is created.
#
# The configuration here is deliberately kept simpler to avoid overcomplicating things. We use
# some "sane" defaults so that the basic services that an EKS cluster need can run to create a
# "default" node group
#######################
variable "default_group_name" {
  description = "Name of the default node group"
  type        = string
  default     = "default"
}

variable "default_group_launch_template_name" {
  description = "Name of the default node group launch template"
  type        = string
  default     = "default"
}

variable "default_group_ami_id" {
  description = "The AMI from which to launch the defualt group instance. If not supplied, EKS will use its own default image"
  type        = string
  default     = ""
}

variable "default_group_instance_types" {
  description = "Instance type for the default node group"
  type        = list(string)
  default     = ["m5a.xlarge", "m5.xlarge", "m5n.xlarge", "m5zn.xlarge"]
}

variable "default_group_min_size" {
  description = "Configuration for min default node group size"
  type        = number
  default     = 1
}

variable "default_group_max_size" {
  description = "Configuration for max default node group size"
  type        = number
  default     = 5
}

variable "default_group_volume_size" {
  description = "Size of the persistentence volume for the default group"
  type        = number
  default     = 50
}

variable "default_group_subnet_ids" {
  description = "Subnet IDs to create the default group ASGs in"
  type        = list(string)
  default     = []
}

variable "default_group_node_labels" {
  description = "Additional node label for default group"
  type        = map(string)
  default     = {}
}

variable "only_critical_addons_enabled" {
  description = "Enabling this option will taint default node group with CriticalAddonsOnly=true:NoSchedule taint. Changing this forces a new resource to be created."
  type        = bool
  default     = false
}

variable "eks_managed_node_groups" {
  description = "Map of EKS managed node group definitions to create"
  type        = any
  default     = {}
}

variable "eks_managed_node_group_defaults" {
  description = "Map of EKS managed node group default configurations"
  type        = any
  default = {
    disk_size = 50

    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "disabled"
      http_protocol_ipv6          = "disabled"
    }

    update_launch_template_default_version = true
    protect_from_scale_in                  = false

    ebs_optimized     = true
    enable_monitoring = true

    create_iam_role = false
  }
}

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
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "cloudwatch_log_group_tags" {
  description = "A map of additional tags to add to the cloudwatch log group created"
  type        = map(string)
  default     = {}
}

variable "fargate_cluster" {
  description = "Whether to create eks cluster with fargate mode. If true, default node group also will be fargate, otherwise managed"
  type        = bool
  default     = false
}

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

variable "create_aws_observability_ns" {
  description = "Whether to create AWS Observability Namespace."
  type        = bool
  default     = true
}

variable "create_fargate_logger_configmap" {
  description = "Whether to create AWS Fargate logger configmap."
  type        = bool
  default     = true
}

#######################
# Ipv6
#######################

variable "create_cni_ipv6_iam_policy" {
  description = "Whether to create CNI IPv6 IAM policy."
  type        = bool
  default     = false
}

variable "cluster_service_ipv6_cidr" {
  description = "The CIDR block to assign Kubernetes pod and service IP addresses from if `ipv6` was specified when the cluster was created. Kubernetes assigns service addresses from the unique local address range (fc00::/7) because you can't specify a custom IPv6 CIDR block when you create the cluster"
  type        = string
  default     = null
}

variable "cluster_ip_family" {
  description = "The IP family used to assign Kubernetes pod and service addresses. Valid values are `ipv4` (default) and `ipv6`. You can only specify an IP family when you create a cluster, changing this value will force a new cluster to be created"
  type        = string
  default     = "ipv4"

  validation {
    condition     = contains(["ipv4", "ipv6"], var.cluster_ip_family)
    error_message = "Invalid IP family. Valid values are `ipv4` and `ipv6`"
  }
}
##########
## MODE ##
##########
variable "autoscaling_mode" {
  description = "Autoscaling mode: cluster_autoscaler or karpenter"
  type        = string
  default     = "karpenter"
}

##############################
## KARPENTER DEFAULT CONFIG ##
##############################
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
      consolidate_after    = string
      expire_after         = string
    })
    karpenter_nodepool_disruption_budgets = list(map(any))
    karpenter_nodepool_weight             = number
  }))
  default = [{
    nodepool_name  = "default"
    nodeclass_name = "default"
    karpenter_nodepool_node_labels = {
      "bottlerocket.aws/updater-interface-version" = "2.0.0"
    }
    karpenter_nodepool_annotations    = {}
    karpenter_nodepool_node_taints    = []
    karpenter_nodepool_startup_taints = []
    karpenter_requirements = [{
      key      = "karpenter.k8s.aws/instance-category"
      operator = "In"
      values   = ["t", "m"]
      }, {
      key      = "karpenter.k8s.aws/instance-cpu"
      operator = "In"
      values   = ["2", "4"]
      }, {
      key      = "karpenter.k8s.aws/instance-memory"
      operator = "Gt"
      values   = ["2048"]
      }, {
      key      = "karpenter.k8s.aws/instance-generation"
      operator = "Gt"
      values   = ["2"]
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
      consolidation_policy = "WhenEmptyOrUnderutilized" # WhenEmptyOrUnderutilized or WhenEmpty
      consolidate_after    = "10m"
      expire_after         = "168h" # 7d | 168h | 1w
    }
    karpenter_nodepool_disruption_budgets = [{
      nodes = "10%"
    }]
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
    karpenter_node_user_data               = string
    karpenter_node_metadata_options        = map(any)
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
  default = []
}

variable "create_fargate_profile_for_karpenter" {
  description = "Create fargate profile flag"
  type        = bool
  default     = false
}

variable "create_aws_observability_ns_for_karpenter" {
  description = "Create aws-observability namespace flag"
  type        = bool
  default     = false
}

variable "create_fargate_logger_configmap_for_karpenter" {
  description = "create_fargate_logger_configmap flag"
  type        = bool
  default     = false
}

variable "create_fargate_log_group_for_karpenter" {
  description = "value for create_fargate_log_group"
  type        = bool
  default     = false
}

variable "create_fargate_logging_policy_for_karpenter" {
  description = "value for create_fargate_logging_policy"
  type        = bool
  default     = false
}

variable "karpenter_chart_version" {
  description = "Chart version for Karpenter"
  type        = string
  default     = "1.2.1"
}

variable "karpenter_crd_chart_version" {
  description = "Chart version for Karpenter CRDs same version as `karpenter_chart_version`"
  type        = string
  default     = "1.2.1"
}

variable "karpenter_default_subnet_selector_tags" {
  description = "Subnet selector tags for Karpenter default node class"
  type        = map(string)
  default = {
    "kubernetes.io/role/internal-elb" = "1"
  }
}

variable "additional_karpenter_security_group_selector_tags" {
  description = "Additional security group tags to add to the Karpenter node groups. Pass values if `karpenter_security_group_selector_terms_type = tags`"
  type        = map(string)
  default     = {}
}

variable "additional_karpenter_security_group_selector_ids" {
  description = "Additional security group IDs to add to the Karpenter node groups, Pass values if `karpenter_security_group_selector_terms_type = ids`"
  type        = list(string)
  default     = []
}

variable "karpenter_security_group_selector_terms_type" {
  description = "Type of terms to use in the security group selector"
  type        = string
  default     = "tags"

  validation {
    condition     = contains(["tags", "ids"], var.karpenter_security_group_selector_terms_type)
    error_message = "Invalid security group selector terms type. Valid values are `tags` or `ids`"
  }
}

variable "karpenter_ephemeral_volume_size" {
  description = "Ephemeral volume size for Karpenter node groups"
  type        = string
  default     = "50Gi"
}

variable "karpenter_pod_resources" {
  description = "Karpenter Pod Resource"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "1"
      memory = "2Gi"
    }
    limits = {
      cpu    = "1"
      memory = "2Gi"
    }
  }
}

# TODO - make v1 permssions the default policy at next breaking change
variable "enable_v1_permissions_for_karpenter" {
  description = "Determines whether to enable permissions suitable for v1+ (`true`) or for v0.33.x-v0.37.x (`false`)"
  type        = bool
  default     = true
}

variable "karpenter_upgrade" {
  description = "Karpenter Upgrade"
  type        = bool
  default     = false
}

variable "enable_pod_identity_for_karpenter" {
  description = "Enable pod identity for karpenter"
  type        = bool
  default     = false
}

variable "enable_pod_identity_for_eks_addons" {
  description = "Enable pod identity for eks addons"
  type        = bool
  default     = false
}

variable "enable_karpenter_service_monitoring" {
  description = "Allow scraping of Karpenter metrics"
  type        = bool
  default     = false
}

################################################################################
# Access Entry
################################################################################

variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Indicates whether or not to add the cluster creator (the identity used by Terraform) as an administrator via access entry"
  type        = bool
  default     = true
}
