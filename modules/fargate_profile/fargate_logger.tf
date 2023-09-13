locals {
  cwlog_group = "/aws/eks/${var.cluster_name}/fargate-fluentbit-logs"

  # https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit
  default_config = {
    output_conf  = <<-EOF
    [OUTPUT]
        Name cloudwatch_logs
        Match   kube.*
        region ${data.aws_region.current.name}
        log_group_name ${local.cwlog_group}
        log_stream_name $(kubernetes['namespace_name'])/$(kubernetes['container_name'])/$(kubernetes['pod_name'])
        auto_create_group false
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

resource "aws_iam_policy" "fargate_logging" {
  count = var.create_fargate_logging_policy ? 1 : 0

  name        = "${var.cluster_name}-${var.fargate_logging_policy_suffix}"
  path        = "/"
  description = "Fargate Cloudwatch Logging"
  policy      = data.aws_iam_policy_document.fargate_logging.json
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "fargate_logging" {
  #checkov:skip=CKV_AWS_111:Restricted to Cloudwatch Actions only
  #checkov:skip=CKV_AWS_356: Only logs actions
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy", # for overriding alr created log groups
    ]
  }
}
