variable "kubernetes_annotations" {
  description = "Annotations for Kubernetes resources"
  type        = map(string)
  default = {
    "terraform" = "true"
  }
}

variable "kubernetes_labels" {
  description = "Labels for resources"
  type        = map(string)
  default = {
    "app.kubernetes.io/managed-by" = "Terraform"
  }
}

############################
# K8S Cluster Information
############################
variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "helm_release_max_history" {
  description = "The maximum number of history releases to keep track in each Helm release"
  type        = number
  default     = 20
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for IRSA"
  type        = string
}

variable "worker_iam_role_name" {
  description = "Worker Nodes IAM Role name"
  type        = string
}

############################
# K8S Resources
############################
variable "namespaces" {
  description = "List of namespaces to create"
  type = list(object({
    name        = string
    description = optional(string)
  }))
  default = [{
    name        = "core"
    description = "For core Kubernetes services"
  }]
}

############################
# Cluster Autoscaler
############################
variable "cluster_autoscaler_iam_role" {
  description = "Override name of the IAM role for autoscaler"
  type        = string
  default     = ""
}

variable "cluster_autoscaler_permissions_boundary" {
  description = "Permissions boundary ARN to use for autoscaler's IAM role"
  type        = string
  default     = null
}

variable "cluster_autoscaler_service_account_name" {
  description = "K8S sevice account name for Cluster Autoscaler"
  type        = string
  default     = "cluster-autoscaler"
}

variable "cluster_autoscaler_release_name" {
  description = "Release name for Cluster Autoscaler"
  type        = string
  default     = "cluster-autoscaler"
}

variable "cluster_autoscaler_chart_name" {
  description = "Chart name for Cluster Autoscaler"
  type        = string
  default     = "cluster-autoscaler"
}

variable "cluster_autoscaler_chart_repository" {
  description = "Chart repository for Cluster Autoscaler"
  type        = string
  default     = "https://kubernetes.github.io/autoscaler"
}

variable "cluster_autoscaler_chart_version" {
  description = "Chart version for Cluster Autoscaler"
  type        = string
  default     = "9.15.0"
}

variable "cluster_autoscaler_namespace" {
  description = "Namespace to deploy the cluster autoscaler"
  type        = string
  default     = "kube-system"
}

variable "cluster_autoscaler_image" {
  description = "Docker image for Cluster Autoscaler"
  type        = string
  default     = "asia.gcr.io/k8s-artifacts-prod/autoscaling/cluster-autoscaler"
}

variable "cluster_autoscaler_tag" {
  description = "Docker image tag for Cluster Autoscaler. This should correspond to the Kubernetes version"
  type        = string
  default     = "v1.22.2"
}

variable "cluster_autoscaler_replica" {
  description = "Number of replicas for Cluster Autoscaler"
  type        = number
  default     = 2
}

variable "cluster_autoscaler_tolerations" {
  description = "Tolerations for Cluster Autoscaler"
  type        = any
  default     = []
}

variable "cluster_autoscaler_affinity" {
  description = "Affinity for Cluster Autoscaler"
  type        = any
  default = {
    podAntiAffinity = {
      preferredDuringSchedulingIgnoredDuringExecution = [
        {
          weight = 100
          podAffinityTerm = {
            topologyKey = "kubernetes.io/hostname"
            labelSelector = {
              matchExpressions = [
                {
                  key      = "app.kubernetes.io/instance"
                  operator = "In"
                  values   = ["cluster-autoscaler"]
                }
              ]
            }
          }
        }
      ]
    }
    nodeAffinity = {
      requiredDuringSchedulingIgnoredDuringExecution = {
        nodeSelectorTerms = [
          {
            matchExpressions = [
              {
                key      = "node.kubernetes.io/lifecycle"
                operator = "NotIn"
                values = [
                  "spot"
                ]
              }
            ]
          }
        ]
      }
    }
  }
}

variable "cluster_autoscaler_topology_spread_constraints" {
  description = "Topology spread constraints for Cluster Autoscaler"
  type        = any
  default = [{
    maxSkew           = 1
    topologyKey       = "topology.kubernetes.io/zone"
    whenUnsatisfiable = "DoNotSchedule"
    labelSelector = {
      matchLabels = {
        "app.kubernetes.io/instance" = "cluster-autoscaler"
      }
    }
  }]
}

variable "cluster_autoscaler_expander" {
  description = "Expander to use for Cluster Autoscaler. See https://github.com/kubernetes/autoscaler/blob/master/cluster-autoscaler/FAQ.md#what-are-expanders"
  type        = string
  default     = "least-waste"
}

variable "cluster_autoscaler_pdb" {
  description = "PDB for Cluster AutoScaler"
  type        = any
  default = {
    maxUnavailable = 1
  }
}

variable "cluster_autoscaler_priority_class" {
  description = "Priority class for Cluster Autoscaler"
  type        = string
  default     = "system-cluster-critical"
}

variable "cluster_autoscaler_resources" {
  description = "Resources for Cluster Autoscaler"
  type        = any

  default = {
    requests = {
      cpu    = "100m"
      memory = "700Mi"
    }
    limits = {
      memory = "700Mi"
    }
  }
}

variable "cluster_autoscaler_pod_annotations" {
  description = "Pod annotations for Cluster Autoscaler"
  type        = map(string)

  default = {
    "scheduler.alpha.kubernetes.io/critical-pod" = ""
  }
}

variable "cluster_autoscaler_pod_labels" {
  description = "Pod Labels for Cluster Autoscaler"
  type        = map(string)
  default     = {}
}

variable "cluster_autoscaler_service_annotations" {
  description = "Service annotations for Cluster Autoscaler"
  type        = map(string)
  default = {
    "prometheus.io/scrape" = "true"
  }
}

#####################
# CoreDNS PDB
#####################
variable "coredns_pdb_min_available" {
  description = "PDB min available CoreDNS pods."
  type        = number
  default     = 1
}

#####################
# EBS CSI Storage Class
#####################
variable "csi_storage_class" {
  description = "CSI Storage Class name"
  type        = string
  default     = "ebs-csi"
}

variable "csi_reclaim_policy" {
  description = "Reclaim policy of the StorageClass for CSI. Can be Delete or Retain"
  type        = string
  default     = "Delete"
}

variable "csi_volume_binding_mode" {
  description = "Volume binding mode of the StorageClass for CSI. Can be Immediate or WaitForFirstConsumer"
  type        = string
  default     = "WaitForFirstConsumer"
}

variable "csi_allow_volume_expansion" {
  description = "Allow volume expansion in the StorageClass for CSI. Can be true or false"
  type        = bool
  default     = true
}

variable "csi_parameters_override" {
  description = <<-EOF
    Parameters for the StorageClass for Raft.
    For AWS EBS see https://kubernetes.io/docs/concepts/storage/storage-classes/#aws-ebs
    for AWS EBS CSI driver see https://github.com/kubernetes-sigs/aws-ebs-csi-driver#createvolume-parameters
    EOF
  type        = any
  default = {
    type = "gp3"
  }
}

variable "csi_encryption_enable" {
  description = "Enable encryption for CSI Storage Class"
  type        = bool
  default     = true
}

variable "csi_encryption_key_id" {
  description = "Encryption key for the CSI Storage Class"
  type        = string
  default     = ""
}

variable "csi_default_storage_class" {
  description = "Set the CSI StorageClass as the default storage class"
  type        = bool
  default     = true
}

#####################
# ECR Pull Through Cache
#####################
variable "configure_ecr_pull_through" {
  description = "Configure ECR Pull Through Cache."
  type        = bool
  default     = true
}

variable "ecr_cache_iam_cache_policy" {
  description = "Name of ECR Cache IAM Policy"
  type        = string
  default     = "EcrCachePullThrough"
}

variable "ecr_pull_through_cache_rules" {
  description = "ECR Pull Through Cache Rules"
  type = map(object({
    registry = string
    prefix   = string
  }))
  default = {
    aws_public = {
      prefix   = "public.ecr.aws"
      registry = "public.ecr.aws"
    }
    quay = {
      prefix   = "quay.io"
      registry = "quay.io"
    }
  }
}

###############################
# Node Termination Handler
###############################
variable "node_termination_handler_enable" {
  description = "Enable node_termination_handler creation. Only needed for self managed node groups."
  type        = bool
  default     = false
}

variable "create_node_termination_handler_sqs" {
  description = "Whether to create node_termination_handler_sqs."
  type        = bool
  default     = false
}

variable "node_termination_handler_sqs_name" {
  description = "Override the name for the SQS used in Node Termination Handler"
  type        = string
  default     = ""
}

variable "node_termination_handler_spot_event_name" {
  description = "Override name of the Cloudwatch Event to handle spot termination of nodes"
  type        = string
  default     = ""
}

variable "node_termination_handler_iam_role" {
  description = "Override the name of the Node Termination Handler IAM Role"
  type        = string
  default     = ""
}

variable "node_termination_handler_permissions_boundary" {
  description = "IAM Boundary for the Node Termination Handler IAM Role, if any"
  type        = string
  default     = null
}

variable "node_termination_handler_sqs_arn" {
  description = "ARN of the SQS used in Node Termination Handler"
  type        = string
  default     = null
}

variable "node_termination_handler_release_name" {
  description = "Release name for Node Termination Handler"
  type        = string
  default     = "node-termination-handler"
}

variable "node_termination_handler_chart_name" {
  description = "Chart name for Node Termination Handler. Repo: https://github.com/aws/eks-charts/tree/master/stable/aws-node-termination-handler"
  type        = string
  default     = "aws-node-termination-handler"
}

variable "node_termination_handler_chart_repository_url" {
  description = "Chart Repository URL for Node Termination Handler"
  type        = string
  default     = "https://aws.github.io/eks-charts"
}

variable "node_termination_handler_chart_version" {
  description = "Chart version for Node Termination Handler"
  type        = string
  default     = "0.17.0"
}

variable "node_termination_handler_image" {
  description = "Docker image for Node Termination Handler"
  type        = string
  default     = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
}

variable "node_termination_handler_tag" {
  description = "Docker image tag for Node Termination Handler. This should correspond to the Kubernetes version"
  type        = string
  default     = "v1.16.0"
}

variable "node_termination_handler_priority_class" {
  description = "Priority class for Node Termination Handler"
  type        = string
  default     = "system-cluster-critical"
}

# (NOTE: increasing this may cause duplicate webhooks since NTH pods are stateless)
variable "node_termination_handler_replicas" {
  description = "Number of replicas for Node Termination Handler"
  type        = number
  default     = 1
}

variable "node_termination_handler_pdb_min_available" {
  description = "Pod Disruption Budget Min Available for Node Termination Handler."
  type        = string
  default     = 1
}

variable "node_termination_handler_resources" {
  description = "Resources for Node Termination Handler"
  type        = any
  default = {
    requests = {
      cpu    = "10m"
      memory = "100Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "100Mi"
    }
  }
}

variable "node_termination_handler_spot_interruption_draining_enabled" {
  description = "Drain nodes when the spot interruption termination notice is received"
  type        = bool
  default     = true
}

variable "node_termination_handler_scheduled_event_draining_enabled" {
  description = "Drain nodes before the maintenance window starts for an EC2 instance scheduled event"
  type        = bool
  default     = false
}

variable "node_termination_handler_metadata_tries" {
  description = "Total number of times to try making the metadata request before failing"
  type        = number
  default     = 3
}

variable "node_termination_handler_cordon_only" {
  description = "Cordon but do not drain nodes upon spot interruption termination notice"
  type        = bool
  default     = false
}

variable "node_termination_handler_taint_node" {
  description = "Taint node upon spot interruption termination notice"
  type        = bool
  default     = true
}

variable "node_termination_handler_json_logging" {
  description = "Log messages in JSON format"
  type        = bool
  default     = true
}

variable "node_termination_handler_dry_run" {
  description = "Only log calls to kubernetes control plane"
  type        = bool
  default     = false
}

variable "node_termination_sqs" {
  description = "SQS Queue for node termination handler"
  type = object({
    url = string
    arn = string
  })
  default = null
}

variable "node_termination_iam_role" {
  description = "Name of the IAM Role for Node Termination Handler"
  type        = string
  default     = "bedrock_node_termination_handler"
}

variable "node_termination_iam_role_boundary" {
  description = "IAM Role boundary for Node Termination Handler"
  type        = string
  default     = null
}

variable "node_termination_namespace" {
  description = "Namespace to deploy Node Termination Handler"
  type        = string
  default     = "kube-system"
}

variable "node_termination_service_account" {
  description = "Service account for Node Termination Handler pods"
  type        = string
  default     = "node-termination-handler"
}

###############################
# Bottle Rocket Update Operator
###############################

variable "brupop_namespace" {
  description = "Namespace for all resources under bottlerocket update operator"
  type        = string
  default     = "brupop-bottlerocket-aws"
}

variable "brupop_release_name" {
  description = "Release name for brupop"
  type        = string
  default     = "bottlerocket-brupop"
}

variable "brupop_chart_name" {
  description = "Chart name for brupop"
  type        = string
  default     = "bottlerocket-brupop"
}

variable "brupop_chart_repository" {
  description = "Chart repository for brupop"
  type        = string
  default     = "oci://public.ecr.aws/sphmedia/helm/"
}

variable "brupop_chart_version" {
  description = "Chart version for brupop"
  type        = string
  default     = "1.0.3"
}

variable "brupop_image" {
  description = "Docker image for brupop"
  type        = string
  default     = "public.ecr.aws/bottlerocket/bottlerocket-update-operator"
}

variable "brupop_tag" {
  description = "Docker image tag for brupop. This should correspond to the Kubernetes version"
  type        = string
  default     = "v0.2.2"
}
