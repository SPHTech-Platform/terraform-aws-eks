locals {

  cwlog_group         = "/aws/eks/${var.cluster_name}/fargate-fluentbit-logs"
  cwlog_stream_prefix = "fargate-logs-"

  default_config = {
    output_conf  = <<-EOF
    [OUTPUT]
      Name cloudwatch_logs
      Match   kube.*
      region ${data.aws_region.current.name}
      log_group_name ${local.cwlog_group}
      log_stream_prefix ${local.cwlog_stream_prefix}
      log_stream_template $kubernetes['pod_name'].$kubernetes['container_name']
      log_retention_days 60
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

########################
### K8s resources ######
########################

resource "kubernetes_namespace_v1" "aws_observability" {

  count = var.fargate_logging_enabled && var.create_aws_observability_ns ? 1 : 0

  metadata {
    name = "aws-observability"

    labels = {
      aws-observability = "enabled"
    }
  }
}

# fluent-bit-cloudwatch value as the name of the CloudWatch log group that is automatically created as soon as your apps start logging
resource "kubernetes_config_map_v1" "aws_logging" {

  count = var.fargate_logging_enabled ? 1 : 0

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
