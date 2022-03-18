########################################
# Instance Refresh related resources
########################################
resource "aws_cloudwatch_event_rule" "node_termination_handler_asg" {
  name_prefix = coalesce(var.node_termination_handler_event_name, "${var.cluster_name}-asg-termination")
  description = "Node termination event rule for cluster ${var.cluster_name}"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"],
    detail-type = ["EC2 Instance-terminate Lifecycle Action"]
    resources   = [for group in module.self_managed_group : group.autoscaling_group_arn]
  })
}

resource "aws_cloudwatch_event_target" "node_termination_handler_asg" {
  target_id = coalesce(var.node_termination_handler_event_name, "${var.cluster_name}-asg-termination-${time_static.creation.unix}")
  rule      = aws_cloudwatch_event_rule.node_termination_handler_asg.name
  arn       = var.node_termination_handler_sqs_arn
}

resource "time_static" "creation" {
  triggers = {}
}

# Creating the lifecycle-hook outside of the ASG resource's `initial_lifecycle_hook`
# ensures that node termination does not require the lifecycle action to be completed,
# and thus allows the ASG to be destroyed cleanly.
resource "aws_autoscaling_lifecycle_hook" "node_termination_handler" {
  for_each = module.self_managed_group

  name                   = "node-termination-handler-${each.value.autoscaling_group_name}"
  autoscaling_group_name = each.value.autoscaling_group_name
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
  heartbeat_timeout      = 300
  default_result         = "CONTINUE"
}
