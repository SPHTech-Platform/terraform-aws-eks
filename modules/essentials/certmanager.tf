resource "helm_release" "cert_manager" {
  name       = var.cert_manager_release_name
  chart      = var.cert_manager_chart_name
  repository = var.cert_manager_chart_repository
  version    = var.cert_manager_chart_version

  create_namespace = true
  namespace        = var.certmanager_namespace

  max_history = var.cert_manager_max_history
  timeout     = var.cert_manager_chart_timeout

  values = [
    templatefile("${path.module}/templates/certmanager.yaml", local.values),
  ]
}

locals {
  values = {
    priority_class_name = var.priority_class_name

    certmanager_namespace = var.certmanager_namespace

    log_level                  = var.log_level
    cluster_resource_namespace = var.cluster_resource_namespace

    leader_election_namespace      = var.leader_election_namespace
    leader_election_lease_duration = var.leader_election_lease_duration
    leader_election_renew_deadline = var.leader_election_renew_deadline
    leader_election_retry_period   = var.leader_election_retry_period

    rbac_create  = var.rbac_create
    psp_enable   = var.psp_enable
    psp_apparmor = var.psp_apparmor

    service_account_create          = var.service_account_create
    service_account_name            = var.service_account_name
    service_account_annotations     = jsonencode(var.service_account_annotations)
    service_account_automount_token = var.service_account_automount_token

    crds_enabled = var.crds_enabled
    crds_keep    = var.crds_keep

    replica_count = var.replica_count
    strategy      = jsonencode(var.strategy)
    feature_gates = join(",", var.feature_gates)

    image_pull_secrets = jsonencode(var.image_pull_secrets)
    image_repository   = var.image_repository
    image_tag          = var.image_tag != null ? var.image_tag : ""

    extra_args = jsonencode(var.extra_args)
    extra_env  = jsonencode(var.extra_env)
    resources  = jsonencode(var.resources)

    volumes       = jsonencode(var.volumes)
    volume_mounts = jsonencode(var.volume_mounts)

    security_context           = jsonencode(var.security_context)
    container_security_context = jsonencode(var.container_security_context)

    deployment_annotations = jsonencode(var.deployment_annotations)
    pod_annotations        = jsonencode(var.pod_annotations)
    pod_labels             = jsonencode(var.pod_labels)

    node_selector = jsonencode(var.node_selector)
    affinity      = jsonencode(var.affinity)
    tolerations   = jsonencode(var.tolerations)

    ingress_shim       = jsonencode(var.ingress_shim)
    prometheus_enabled = var.prometheus_enabled

    #####################################
    # Admission Webhook
    #####################################
    webhook_replica_count   = var.webhook_replica_count
    webhook_timeout_seconds = var.webhook_timeout_seconds

    webook_strategy                   = jsonencode(var.webook_strategy)
    webhook_security_context          = jsonencode(var.webhook_security_context)
    webook_container_security_context = jsonencode(var.webook_container_security_context)

    webhook_deployment_annotations = jsonencode(var.webhook_deployment_annotations)
    webhook_pod_annotations        = jsonencode(var.webhook_pod_annotations)
    webhook_pod_labels             = jsonencode(var.webhook_pod_labels)

    mutating_webhook_configuration_annotations   = jsonencode(var.mutating_webhook_configuration_annotations)
    validating_webhook_configuration_annotations = jsonencode(var.validating_webhook_configuration_annotations)

    validating_webhook_configuration = jsonencode(var.validating_webhook_configuration)
    mutating_webhook_configuration   = jsonencode(var.mutating_webhook_configuration)

    webhook_extra_args = jsonencode(var.webhook_extra_args)
    webhook_resources  = jsonencode(var.webhook_resources)

    webhook_liveness_probe  = jsonencode(var.webhook_liveness_probe)
    webhook_readiness_probe = jsonencode(var.webhook_readiness_probe)

    webhook_node_selector = jsonencode(var.webhook_node_selector)
    webhook_affinity      = jsonencode(var.webhook_affinity)
    webhook_tolerations   = jsonencode(var.webhook_tolerations)

    webhook_image_repository = var.webhook_image_repository
    webhook_image_tag        = var.webhook_image_tag != null ? var.webhook_image_tag : "null"

    webhook_service_account_create      = var.webhook_service_account_create
    webhook_service_account_name        = var.webhook_service_account_name
    webhook_service_account_annotations = jsonencode(var.webhook_service_account_annotations)

    webhook_port         = var.webhook_port
    webhook_host_network = var.webhook_host_network

    #####################################
    # CA Injector
    # See https://cert-manager.io/docs/concepts/ca-injector/
    #####################################
    ca_injector_enabled       = var.ca_injector_enabled
    ca_injector_replica_count = var.ca_injector_replica_count
    ca_injector_strategy      = jsonencode(var.ca_injector_strategy)

    ca_injector_security_context           = jsonencode(var.ca_injector_security_context)
    ca_injector_container_security_context = jsonencode(var.ca_injector_container_security_context)

    ca_injector_deployment_annotations = jsonencode(var.ca_injector_deployment_annotations)
    ca_injector_pod_annotations        = jsonencode(var.ca_injector_pod_annotations)
    ca_injector_pod_labels             = jsonencode(var.ca_injector_pod_labels)

    ca_injector_extra_args = jsonencode(var.ca_injector_extra_args)
    ca_injector_resources  = jsonencode(var.ca_injector_resources)

    ca_injector_node_selector = jsonencode(var.ca_injector_node_selector)
    ca_injector_affinity      = jsonencode(var.ca_injector_affinity)
    ca_injector_tolerations   = jsonencode(var.ca_injector_tolerations)

    ca_injector_image_repository = var.ca_injector_image_repository
    ca_injector_image_tag        = var.ca_injector_image_tag != null ? var.ca_injector_image_tag : "null"

    ca_injector_service_account_create      = var.ca_injector_service_account_create
    ca_injector_service_account_name        = var.ca_injector_service_account_name
    ca_injector_service_account_annotations = jsonencode(var.ca_injector_service_account_annotations)

    startupapicheck_enabled = var.startupapicheck_enabled

    startupapicheck_security_context = jsonencode(var.startupapicheck_security_context)

    startupapicheck_timeout       = var.startupapicheck_timeout
    startupapicheck_backoff_limit = var.startupapicheck_backoff_limit

    startupapicheck_extra_args = jsonencode(var.startupapicheck_extra_args)
    startupapicheck_resources  = jsonencode(var.startupapicheck_resources)

    startupapicheck_node_selector = jsonencode(var.startupapicheck_node_selector)
    startupapicheck_affinity      = jsonencode(var.startupapicheck_affinity)
    startupapicheck_tolerations   = jsonencode(var.startupapicheck_tolerations)

    startupapicheck_pod_labels = jsonencode(var.startupapicheck_pod_labels)

    startupapicheck_image     = var.startupapicheck_image_repository
    startupapicheck_image_tag = var.startupapicheck_image_tag != null ? var.startupapicheck_image_tag : "null"
  }
}
