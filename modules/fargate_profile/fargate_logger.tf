locals {

  cwlog_group         = "/aws/eks/${var.cluster_name}/fargate-fluentbit-logs"
  cwlog_stream_prefix = var.fargate_log_stream_prefix

  default_config = {
    output_conf  = <<-EOF
    [OUTPUT]
        Name cloudwatch
        Match   kube.*
        region ${data.aws_region.current.name}
        log_group_name ${local.cwlog_group}
        %{if local.cwlog_stream_prefix != ""}log_stream_prefix ${local.cwlog_stream_prefix}%{endif}
        log_stream_template $kubernetes['pod_name'].$kubernetes['container_name']
    EOF
    filters_conf = <<-EOF
    [FILTER]
        Name parser
        Match *
        Key_name log
        Parser crio
    [FILTER]
        Name kubernetes
        Match kube.*
        Merge_Log On
        Keep_Log Off
        Buffer_Size 0
        Kube_Meta_Cache_TTL 300s
    EOF
    parsers_conf = <<-EOF
    [PARSER]
        Name crio
        Format Regex
        Regex ^(?<time>[^ ]+) (?<stream>stdout|stderr) (?<logtag>P|F) (?<log>.*)$
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z
    EOF
  }

  config = merge(
    local.default_config,
    var.addon_config
  )
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key Not using CMK to save cost
resource "aws_cloudwatch_log_group" "fargate" {
  #checkov:skip=CKV_AWS_158:Not using CMK to save cost
  #checkov:skip=CKV_AWS_338:"Ensure CloudWatch log groups retains logs for at least 1 year"

  count = var.create_fargate_log_group ? 1 : 0

  name              = local.cwlog_group
  retention_in_days = var.fargate_log_group_retention_days
}

########################
### K8s resources ######
########################

resource "kubernetes_namespace_v1" "aws_observability" {

  count = var.create_aws_observability_ns ? 1 : 0

  metadata {
    name = "aws-observability"

    labels = {
      aws-observability = "enabled"
    }
  }
}

# fluent-bit-cloudwatch value as the name of the CloudWatch log group that is automatically created as soon as your apps start logging
resource "kubernetes_config_map_v1" "aws_logging" {

  count = var.create_fargate_logger_configmap ? 1 : 0

  metadata {
    name      = "aws-logging"
    namespace = "aws-observability"
  }

  data = {
    "parsers.conf" = local.config["parsers_conf"]
    "filters.conf" = local.config["filters_conf"]
    "output.conf"  = local.config["output_conf"]
  }

}
