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

variable "fargate_mix_node_groups" {
  description = "Deploying mix workloads as in EKS Manage Node Groups and Fragate Node Groups, set this to TRUE"
  type        = bool
  default     = false
}

variable "fargate_cluster" {
  description = "Deploying workloads on Fargate, set this to TRUE"
  type        = bool
  default     = false
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

########
# ADOT
########
variable "adot_addon" {
  description = "value of the adot addon"
  type        = any
  default     = {}
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
variable "autoscaling_mode" {
  description = "Autoscaling mode: cluster_autoscaler or karpenter"
  type        = string
  default     = "cluster_autoscaler"
}

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
  default     = "9.40.0"
}

variable "cluster_autoscaler_namespace" {
  description = "Namespace to deploy the cluster autoscaler"
  type        = string
  default     = "kube-system"
}

variable "cluster_autoscaler_image" {
  description = "Docker image for Cluster Autoscaler"
  type        = string
  default     = "registry.k8s.io/autoscaling/cluster-autoscaler"
}

variable "cluster_autoscaler_tag" {
  description = "Docker image tag for Cluster Autoscaler. This should correspond to the Kubernetes version"
  type        = string
  default     = "v1.31.0"
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

variable "cluster_autoscaler_vpa" {
  description = "VPA for Cluster AutoScaler"
  type        = any
  default = {
    enabled         = false
    updateMode      = "Auto"
    containerPolicy = {}
  }
}

variable "cluster_autoscaler_secret_key_ref_name_override" {
  description = "Override the name of the secret key ref for Cluster Autoscaler"
  type        = string
  default     = ""
}

variable "create_pdb_for_coredns" {
  description = "Create PDB for CoreDNS"
  type        = bool
  default     = false
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
variable "coredns_pdb_max_unavailable" {
  description = "PDB max unavailable CoreDNS pods."
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
    kubernetes = {
      prefix   = "registry.k8s.io"
      registry = "registry.k8s.io"
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
  default     = "0.21.0"
}

variable "node_termination_handler_image" {
  description = "Docker image for Node Termination Handler"
  type        = string
  default     = "public.ecr.aws/aws-ec2/aws-node-termination-handler"
}

variable "node_termination_handler_tag" {
  description = "Docker image tag for Node Termination Handler. This should correspond to the Kubernetes version"
  type        = string
  default     = "v1.22.1"
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
variable "brupop_enabled" {
  description = "Enable Bottle Rocket Update Operator"
  type        = bool
  default     = false
}

variable "brupop_namespace" {
  description = "Namespace for all resources under bottlerocket update operator"
  type        = string
  default     = "brupop-bottlerocket-aws"
}

variable "brupop_crd_release_name" {
  description = "Release name for brupop CRD"
  type        = string
  default     = "brupop-crd"
}

variable "brupop_crd_chart_name" {
  description = "Chart name for brupop CRD"
  type        = string
  default     = "bottlerocket-shadow"
}

variable "brupop_crd_chart_repository" {
  description = "Chart repository for brupop"
  type        = string
  default     = "https://bottlerocket-os.github.io/bottlerocket-update-operator"
}

variable "brupop_crd_chart_version" {
  description = "Chart version for brupop CRD"
  type        = string
  default     = "1.0.0"
}

variable "brupop_crd_apiserver_service_port" {
  description = "API server service port for brupop CRD"
  type        = number
  default     = 443
}

variable "brupop_release_name" {
  description = "Release name for brupop"
  type        = string
  default     = "brupop-operator"
}

variable "brupop_chart_name" {
  description = "Chart name for brupop"
  type        = string
  default     = "bottlerocket-update-operator"
}

variable "brupop_chart_repository" {
  description = "Chart repository for brupop"
  type        = string
  default     = "https://bottlerocket-os.github.io/bottlerocket-update-operator"
}

variable "brupop_chart_version" {
  description = "Chart version for brupop"
  type        = string
  default     = "1.4.0"
}

variable "brupop_image" {
  description = "Docker image for brupop"
  type        = string
  default     = "public.ecr.aws/bottlerocket/bottlerocket-update-operator"
}

variable "brupop_tag" {
  description = "Docker image tag for brupop. This should correspond to the Kubernetes version"
  type        = string
  default     = "v1.4.0"
}

##############
# Cert Manager
##############
variable "cert_manager_release_name" {
  description = "Helm release name"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_name" {
  description = "Helm chart name to provision"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_repository" {
  description = "Helm repository for the chart"
  type        = string
  default     = "https://charts.jetstack.io"
}

variable "cert_manager_chart_version" {
  description = "Version of Chart to install. Set to empty to install the latest version"
  type        = string
  default     = "1.15.3"
}

variable "certmanager_namespace" {
  description = "Namespace to install the chart into"
  type        = string
  default     = "cert-manager"
}

variable "cert_manager_chart_timeout" {
  description = "Timeout to wait for the Chart to be deployed."
  type        = number
  default     = 300
}

variable "cert_manager_max_history" {
  description = "Max History for Helm"
  type        = number
  default     = 20
}

#######################
# Chart Values
#######################
variable "priority_class_name" {
  description = "Priority class for all cert-manager pods"
  type        = string
  default     = ""
}

variable "rbac_create" {
  description = "Create RBAC resources"
  type        = bool
  default     = true
}

variable "psp_enable" {
  description = "Create PodSecurityPolicy"
  type        = bool
  default     = false
}

variable "psp_apparmor" {
  description = "Use AppArmor with PSP."
  type        = bool
  default     = true
}

variable "service_account_create" {
  description = "Create service account"
  type        = bool
  default     = true
}

variable "service_account_name" {
  description = "Override the default service account name"
  type        = string
  default     = ""
}

variable "service_account_annotations" {
  description = "Service acocunt annotations"
  type        = map(string)
  default     = {}
}

variable "service_account_automount_token" {
  description = "Automount API credentials for a Service Account"
  type        = bool
  default     = true
}

variable "log_level" {
  description = "Set the verbosity of cert-manager. Range of 0 - 6 with 6 being the most verbose."
  type        = number
  default     = 2
}

variable "leader_election_namespace" {
  description = "Namespace used for Leader Election ConfigMap"
  type        = string
  default     = "kube-system"
}

variable "leader_election_lease_duration" {
  description = "Duration that non-leader candidates will wait after observing a leadership renewal"
  type        = string
  default     = "60s"
}

variable "leader_election_renew_deadline" {
  description = "Interval between attempts by the acting master to renew a leadership slot before it stops leading"
  type        = string
  default     = "40s"
}

variable "leader_election_retry_period" {
  description = "Duration the clients should wait between attempting acquisition and renewal of a leadership."
  type        = string
  default     = "15s"
}

variable "cluster_resource_namespace" {
  description = "Override the namespace used to store DNS provider credentials etc. for ClusterIssuer resources. By default, the same namespace as cert-manager is deployed within is used. This namespace will not be automatically created by the Helm chart."
  type        = string
  default     = ""
}

variable "crds_enabled" {
  description = "Install CRDs with chart"
  type        = bool
  default     = true
}

variable "crds_keep" {
  description = "Keep cert-manager custom resources"
  type        = bool
  default     = true
}

variable "replica_count" {
  description = "Number of controller replicas"
  type        = number
  default     = 1
}

variable "strategy" {
  description = "Update strategy of deployment"
  type        = any
  default = {
    type = "RollingUpdate"
    rollingUpdate = {
      maxSurge       = 1
      maxUnavailable = "50%"
    }
  }
}

variable "feature_gates" {
  description = "Feature gates to enable on the pod"
  type        = list(any)
  default     = []
}

variable "image_pull_secrets" {
  description = "Secrets for image pulling"
  type        = list(any)
  default     = []
}

variable "image_repository" {
  description = "Image repository"
  type        = string
  default     = "quay.io/jetstack/cert-manager-controller"
}

variable "image_tag" {
  description = "Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used."
  type        = string
  default     = null
}

variable "extra_args" {
  description = "Extra arguments"
  type        = list(any)
  default     = []
}

variable "extra_env" {
  description = "Extra environment variables"
  type        = list(any)
  default     = []
}

variable "resources" {
  description = "Resources for pods"
  type        = any
  default = {
    requests = {
      cpu    = "100m"
      memory = "300Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "300Mi"
    }
  }
}

variable "volumes" {
  description = "Extra volumes for the pod"
  type        = any
  default     = []
}

variable "volume_mounts" {
  description = "Extra volume mounts for the container"
  type        = any
  default     = []
}

variable "security_context" {
  description = "Configure pod security context"
  type        = map(string)
  default     = {}
}

variable "container_security_context" {
  description = "Configure container security context"
  type        = map(string)
  default     = {}
}

variable "deployment_annotations" {
  description = "Extra annotations for the deployment"
  type        = map(string)
  default     = {}
}

variable "pod_annotations" {
  description = "Extra annotations for pods"
  type        = map(string)
  default     = {}
}

variable "pod_labels" {
  description = "Extra labels for pods"
  type        = map(string)
  default     = {}
}

variable "ingress_shim" {
  description = "Configure Ingess Shim. See https://cert-manager.io/docs/usage/ingress/"
  type        = map(any)
  default     = {}
}

variable "prometheus_enabled" {
  description = "Enable Prometheus metrics"
  type        = bool
  default     = true
}

variable "node_selector" {
  description = "Node selector for cert-manager-controller pods"
  type        = map(string)
  default     = {}
}

variable "affinity" {
  description = "Pod affinity"
  type        = map(string)
  default     = {}
}

variable "tolerations" {
  description = "Pod tolerations"
  type        = list(any)
  default     = []
}

#####################################
# Admission Webhook
#####################################
variable "webhook_replica_count" {
  description = "Number of replicas for webhook"
  type        = number
  default     = 1
}

variable "webhook_timeout_seconds" {
  description = "Timeout in seconds for webook"
  type        = number
  default     = 10
}

variable "webook_strategy" {
  description = "Update strategy for admission webhook"
  type        = any
  default = {
    type = "RollingUpdate"
    rollingUpdate = {
      maxSurge       = 1
      maxUnavailable = "50%"
    }
  }
}

variable "webhook_security_context" {
  description = "Security context for webhook pod"
  type        = map(any)
  default     = {}
}

variable "webook_container_security_context" {
  description = "Security context for webhook containers"
  type        = map(any)
  default     = {}
}

variable "webhook_deployment_annotations" {
  description = "Extra annotations for webhook deployment"
  type        = map(string)
  default     = {}
}

variable "webhook_pod_annotations" {
  description = "Extra annotations for webhook pods"
  type        = map(string)
  default     = {}
}

variable "webhook_pod_labels" {
  description = "Extra labels for webhook pods"
  type        = map(string)
  default     = {}
}

variable "mutating_webhook_configuration_annotations" {
  description = "Optional additional annotations to add to the webhook MutatingWebhookConfiguration"
  type        = map(string)
  default     = {}
}

variable "validating_webhook_configuration_annotations" {
  description = "Optional additional annotations to add to the webhook ValidatingWebhookConfiguration"
  type        = map(string)
  default     = {}
}

variable "validating_webhook_configuration" {
  description = "Validating webhook configuration"
  type        = any
  default = {
    namespcaceSelector = {
      matchExpressions = [
        {
          key      = "cert-manager.io/disable-validation"
          operator = "NotIn"
          values   = ["true"]
        }
      ]
    }
  }
}

variable "mutating_webhook_configuration" {
  description = "Mutating webhook configuration"
  type        = any
  default = {
    namespcaceSelector = {}
  }
}

variable "webhook_extra_args" {
  description = "Extra args for webhook"
  type        = any
  default     = []
}

variable "webhook_resources" {
  description = "Webhook pod resources"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "300Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "300Mi"
    }
  }
}

variable "webhook_liveness_probe" {
  description = "Liveness probe for webhook"
  type        = map(any)
  default = {
    failureThreshold    = 3
    initialDelaySeconds = 60
    periodSeconds       = 10
    successThreshold    = 1
    timeoutSeconds      = 5
  }
}

variable "webhook_readiness_probe" {
  description = "Readiness probe for webhook"
  type        = map(any)
  default = {
    failureThreshold    = 3
    initialDelaySeconds = 5
    periodSeconds       = 5
    successThreshold    = 1
    timeoutSeconds      = 5
  }
}

variable "webhook_node_selector" {
  description = "Node selector for webhook"
  type        = map(string)
  default     = {}
}


variable "webhook_affinity" {
  description = "Affinity for webhook"
  type        = map(string)
  default     = {}
}

variable "webhook_tolerations" {
  description = "Tolerations for webhook"
  type        = list(any)
  default     = []
}

variable "webhook_image_repository" {
  description = "Image repository for webhook"
  type        = string
  default     = "quay.io/jetstack/cert-manager-webhook"
}

variable "webhook_image_tag" {
  description = "Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used."
  type        = any
  default     = null
}

variable "webhook_service_account_create" {
  description = "Create Webhook service account"
  type        = bool
  default     = true
}

variable "webhook_service_account_name" {
  description = "Name for webhook service account. If not set and create is true, a name is generated using the fullname template"
  type        = string
  default     = ""
}

variable "webhook_service_account_annotations" {
  description = "Annotations for webhook service account"
  type        = map(string)
  default     = {}
}

# Using non default port of 10260 instead of 10250 to avoid conflict with kubelet
variable "webhook_port" {
  description = "Port used by webhook to listen for request from Kubernetes Master"
  type        = number
  default     = 10260
}

variable "webhook_host_network" {
  description = "Whether webhook should use host network"
  type        = bool
  default     = false
}

#####################################
# CA Injector
# See https://cert-manager.io/docs/concepts/ca-injector/
#####################################
variable "ca_injector_enabled" {
  description = "Enable CA Injector."
  type        = bool
  default     = true
}

variable "ca_injector_replica_count" {
  description = "Number of replica for injector"
  type        = number
  default     = 1
}

variable "ca_injector_strategy" {
  description = "CA Injector deployment update strategy"
  type        = any
  default = {
    type = "RollingUpdate"
    rollingUpdate = {
      maxSurge       = 1
      maxUnavailable = "50%"
    }
  }
}

variable "ca_injector_security_context" {
  description = "CA Injector Pod Security Context"
  type        = map(any)
  default     = {}
}

variable "ca_injector_container_security_context" {
  description = "CA Injector Container Security Context"
  type        = map(any)
  default     = {}
}

variable "ca_injector_deployment_annotations" {
  description = "Extra annotations for ca_injector deployment"
  type        = map(string)
  default     = {}
}

variable "ca_injector_pod_annotations" {
  description = "Extra annotations for ca_injector pods"
  type        = map(string)
  default     = {}
}

variable "ca_injector_pod_labels" {
  description = "Extra labels for ca_injector pods"
  type        = map(string)
  default     = {}
}

variable "ca_injector_extra_args" {
  description = "Extra args for ca_injector"
  type        = any
  default     = []
}

variable "ca_injector_resources" {
  description = "ca_injector pod resources"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "300Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "300Mi"
    }
  }
}

variable "ca_injector_node_selector" {
  description = "Node selector for ca_injector"
  type        = map(string)
  default     = {}
}

variable "ca_injector_affinity" {
  description = "Affinity for ca_injector"
  type        = map(string)
  default     = {}
}

variable "ca_injector_tolerations" {
  description = "Tolerations for ca_injector"
  type        = list(any)
  default     = []
}

variable "ca_injector_image_repository" {
  description = "Image repository for ca_injector"
  type        = string
  default     = "quay.io/jetstack/cert-manager-cainjector"
}

variable "ca_injector_image_tag" {
  description = "Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used."
  type        = any
  default     = null
}

variable "ca_injector_service_account_create" {
  description = "Create ca_injector service account"
  type        = bool
  default     = true
}

variable "ca_injector_service_account_name" {
  description = "Name for ca_injector service account. If not set and create is true, a name is generated using the fullname template"
  type        = string
  default     = ""
}

variable "ca_injector_service_account_annotations" {
  description = "Annotations for ca_injector service account"
  type        = map(string)
  default     = {}
}

###############################################
# startupapicheck is a Helm post-install hook
###############################################

variable "startupapicheck_enabled" {
  description = "Enable startupapicheck"
  type        = bool
  default     = true
}

variable "startupapicheck_security_context" {
  description = "startupapicheck security context"
  type        = map(any)
  default = {
    runAsNonRoot = true
  }
}

variable "startupapicheck_timeout" {
  description = "startupapicheck timeout"
  type        = string
  default     = "1m"
}

variable "startupapicheck_backoff_limit" {
  description = "startupapicheck backoff limit"
  type        = number
  default     = 4
}

variable "startupapicheck_pod_labels" {
  description = "Extra labels for startupapicheck pods"
  type        = map(string)
  default     = {}
}

variable "startupapicheck_extra_args" {
  description = "Extra args for startupapicheck"
  type        = list(any)
  default     = []
}

variable "startupapicheck_resources" {
  description = "startupapicheck pod resources"
  type        = map(any)
  default = {
    requests = {
      cpu    = "10m"
      memory = "32Mi"
    }
    limits = {
      cpu    = "10m"
      memory = "32Mi"
    }
  }
}

variable "startupapicheck_node_selector" {
  description = "Node selector for startupapicheck"
  type        = map(string)
  default     = {}
}

variable "startupapicheck_affinity" {
  description = "Affinity for startupapicheck"
  type        = map(string)
  default     = {}
}

variable "startupapicheck_tolerations" {
  description = "Tolerations for startupapicheck"
  type        = any
  default     = []
}

variable "startupapicheck_image_repository" {
  description = "Image repository for startupapicheck"
  type        = string
  default     = "quay.io/jetstack/cert-manager-startupapicheck"
}

variable "startupapicheck_image_tag" {
  description = "Override the image tag to deploy by setting this variable. If no value is set, the chart's appVersion will be used."
  type        = any
  default     = null
}

#################
# metrics-server
#################
variable "metrics_server_enabled" {
  description = "Enable metrics-server helm charts installation."
  type        = bool
  default     = true
}

variable "metrics_server_helm_config_defaults" {
  description = "Helm provider default config for Metrics Server."
  type        = any
  default = {
    name        = "metrics-server"
    chart       = "metrics-server"
    repository  = "https://kubernetes-sigs.github.io/metrics-server/"
    version     = "3.12.1"
    description = "Metric server helm Chart deployment configuration"
  }
}

variable "metrics_server_helm_config" {
  description = "Helm provider config for Metrics Server."
  type        = any
  default     = {}
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

#####################
# kube-state-metrics
#####################
variable "kube_state_metrics_enabled" {
  description = "Enable kube-state-metrics helm charts installation."
  type        = bool
  default     = true
}

variable "kube_state_metrics_helm_config_defaults" {
  description = "Helm provider default config for kube-state-metrics."
  type        = any
  default = {
    name        = "kube-state-metrics"
    chart       = "kube-state-metrics"
    repository  = "https://prometheus-community.github.io/helm-charts"
    version     = "5.25.1"
    namespace   = "kube-system"
    description = "kube-state-metrics helm Chart deployment configuration"
  }
}

variable "kube_state_metrics_helm_config" {
  description = "Helm provider config for kube-state-metrics."
  type        = any
  default     = {}
}

#####################
# node-exporter
#####################
variable "node_exporter_enabled" {
  description = "Enable prometheus-node-exporters helm charts installation."
  type        = bool
  default     = true
}

variable "node_exporter_helm_config_defaults" {
  description = "Helm provider default config for prometheus-node-exporter."
  type        = any
  default = {
    name        = "prometheus-node-exporter"
    chart       = "prometheus-node-exporter"
    repository  = "https://prometheus-community.github.io/helm-charts"
    version     = "4.39.0"
    namespace   = "kube-system"
    description = "prometheus-node-exporter helm Chart deployment configuration"
  }
}

variable "node_exporter_helm_config" {
  description = "Helm provider config for prometheus-node-exporter."
  type        = any
  default     = {}
}

#############
# fluent-bit
#############
variable "fluent_bit_enabled" {
  description = "Enable fluent-bit helm charts installation."
  type        = bool
  default     = true
}

variable "fluent_bit_helm_config_defaults" {
  description = "Helm provider default config for Fluent Bit."
  type        = any
  default = {
    name        = "fluent-bit"
    chart       = "fluent-bit"
    repository  = "https://fluent.github.io/helm-charts"
    version     = "0.47.9"
    namespace   = "logging"
    description = "Fluent Bit helm Chart deployment configuration"
  }
}

# Use aws fluentbit image which has firehose/cloudwatch plugins
variable "fluent_bit_image_repository" {
  description = "Fluent Bit Image repo"
  type        = string
  default     = "public.ecr.aws/aws-observability/aws-for-fluent-bit"
}

variable "fluent_bit_image_tag" {
  description = "Fluent Bit Image tag"
  type        = string
  default     = "2.32.0"
}

variable "fluent_bit_helm_config" {
  description = "Helm provider config for AWS for Fluent Bit."
  type        = any
  default     = {}
}

variable "fluent_bit_role_policy_arns" {
  description = "ARNs of any policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}

variable "fluent_bit_log_group_retention" {
  description = "Number of days to retain the cloudwatch logs"
  type        = number
  default     = 30
}

variable "fluent_bit_custom_parser" {
  description = "Custom parser for Fluent Bit"
  type = object({
    name        = string
    format      = string
    regex       = optional(string)
    time_key    = string
    time_format = string
  })
  default = {
    name        = "custom_apache"
    format      = "regex"
    regex       = "^(?<client_ip>[^ ]*) \\<(?<x_forwarded_for>[^\\\"]*)\\> (?<host>[^ ]*) [^ ]* (?<user>[^ ]*) \\[(?<time>[^\\]]*)\\] \"(?<latency>[^\\\"]*)\" \"(?<method>\\S+)(?: +(?<path>[^ ]*) +\\S*)?\" (?<code>[^ ]*) (?<size>[^ ]*)(?: \"(?<referer>[^\\\"]*)\" \"(?<agent>[^\\\"]*)\")?$"
    time_key    = "time"
    time_format = "%d/%b/%Y:%H:%M:%S %z"
  }
}

variable "resolve_conflicts_on_update" {
  description = "value for resolve_conflicts_on_update for aws_eks_addon resource"
  type        = string
  default     = "PRESERVE"
}

variable "resolve_conflicts_on_create" {
  description = "value for resolve_conflicts_on_create for aws_eks_addon resource"
  type        = string
  default     = "OVERWRITE"
}

variable "fluent_bit_overwrite_helm_values" {
  description = "helm values for overwrite configuration"
  type        = string
  default     = ""
}

variable "fluent_bit_liveness_probe" {
  description = "Liveness probe for fluent-bit"
  type        = map(any)
  default = {
    httpGet = {
      path = "/"
      port = 2020
    }
  }
}

variable "fluent_bit_readiness_probe" {
  description = "Readiness probe for fluent-bit"
  type        = map(any)
  default = {
    httpGet = {
      path = "/api/v1/health"
      port = 2020
    }
  }
}

variable "fluent_bit_resources" {
  description = "Resources for fluent-bit"
  type        = map(any)
  default = {
    requests = {
      cpu    = "100m"
      memory = "128Mi"
    }
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
  }
}

variable "fluent_bit_tolerations" {
  description = "Tolerations for fluent-bit"
  type        = list(any)
  default = [
    {
      operator = "Exists"
      effect   = "NoSchedule"
    }
  ]
}

variable "fluent_bit_kube_api_endpoint" {
  description = "Kube API endpoint for fluent-bit"
  type        = string
  default     = "https://kubernetes.default.svc.cluster.local:443"
}

variable "ip_dual_stack_enabled" {
  description = "Enable essentials to support EKS dual stack cluster"
  type        = bool
  default     = false
}

variable "fluent_bit_excluded_namespaces" {
  description = "Namespaces to exclude from fluent-bit"
  type        = list(string)
  default     = []
}

variable "fluent_bit_enable_s3_output" {
  description = "Enable S3 output logging"
  type        = bool
  default     = false
}

variable "fluent_bit_enable_cw_output" {
  description = "Enable cloudwatch logging"
  type        = bool
  default     = true
}

########################
# Node Local DNS Cache #
########################
variable "nodelocaldns_enabled" {
  description = "Enable Node Local DNS Cache"
  type        = bool
  default     = false
}

variable "nodelocaldns_release_name" {
  description = "Release name for Node Local DNS Cache"
  type        = string
  default     = "node-local-dns"
}

variable "nodelocaldns_chart_name" {
  description = "Chart name for Node Local DNS Cache"
  type        = string
  default     = "node-local-dns"
}

variable "nodelocaldns_chart_repository" {
  description = "Chart Repository URL for Node Local DNS Cache"
  type        = string
  default     = "oci://ghcr.io/deliveryhero/helm-charts"
}

variable "nodelocaldns_chart_version" {
  description = "Chart version for Node Local DNS Cache"
  type        = string
  default     = "2.1.5"
}

variable "nodelocaldns_namespace" {
  description = "Namespace to deploy Node Local DNS Cache"
  type        = string
  default     = "kube-system"
}

variable "nodelocaldns_image_repository" {
  description = "Node Local DNS Cache image repository"
  type        = string
  default     = "k8s.gcr.io/dns/k8s-dns-node-cache"
}

variable "nodelocaldns_image_tag" {
  description = "Node Local DNS Cache image tag, Refer https://github.com/kubernetes/dns/releases to get tag "
  type        = string
  default     = "1.25.0"
}

variable "nodelocaldns_internal_domain_name" {
  description = "Node Local DNS Cache internal domain name"
  type        = string
  default     = "cluster.local"
}

variable "nodelocaldns_kube_dns_svc_ip" {
  description = "Kube DNS service IP, This required Only kube-proxy mode is `iptables` mostprobably values would be '172.20.0.10' or 'fd74:1124:c4cd::a'"
  type        = string
  default     = "172.20.0.10"
}

variable "nodelocaldns_localdns_ip" {
  description = "Node Local DNS Cache IP, Range '169.254.0.0/16' for IPv4 and 'fd00::/8' for IPv6"
  type        = string
  default     = "169.254.20.10"
}

variable "nodelocaldns_custom_upstream_svc_name" {
  description = "Custom upstream service name"
  type        = string
  default     = ""
}

variable "nodelocaldns_enable_logging" {
  description = "Enable logging for Node Local DNS Cache"
  type        = bool
  default     = false
}

variable "nodelocaldns_no_ipv6_lookups" {
  description = "Disable IPv6 lookups, If true, return NOERROR when attempting to resolve an IPv6 address"
  type        = bool
  default     = false
}

variable "nodelocaldns_cache_prefetch_enabled" {
  description = "Enable cache prefetching"
  type        = bool
  default     = false
}

variable "nodelocaldns_setup_interface" {
  description = "Setup interface for Node Local DNS Cache"
  type        = bool
  default     = true
}

variable "nodelocaldns_setup_iptables" {
  description = "Setup iptables for Node Local DNS Cache"
  type        = bool
  default     = true
}

variable "nodelocaldns_skip_teardown" {
  description = "Skip teardown for Node Local DNS Cache"
  type        = bool
  default     = false
}

variable "nodelocaldns_pod_resources" {
  description = "Node Local DNS Cache pod resources"
  type        = map(any)
  default = {
    requests = {
      cpu    = "25m"
      memory = "128Mi"
    }
    limits = {
      memory = "128Mi"
    }
  }
}

variable "nodelocaldns_affinity" {
  description = "Node Local DNS Cache affinity"
  type        = map(any)
  default = {
    "nodeAffinity" = {
      "requiredDuringSchedulingIgnoredDuringExecution" = {
        "nodeSelectorTerms" = [
          {
            "matchExpressions" = [
              {
                "key"      = "kubernetes.io/os"
                "operator" = "In"
                "values"   = ["linux"]
              },
              {
                "key"      = "kubernetes.io/arch"
                "operator" = "In"
                "values" = [
                  "amd64",
                  "arm64"
                ]
              },
              {
                "key"      = "eks.amazonaws.com/compute-type"
                "operator" = "NotIn"
                "values" = [
                  "fargate",
                  "auto"
                ]
              }
            ]
          }
        ]
      }
    }
  }
}

variable "nodelocaldns_image_pull_secrets" {
  description = "Image pull secrets for Node Local DNS Cache"
  type        = list(any)
  default     = []
}
