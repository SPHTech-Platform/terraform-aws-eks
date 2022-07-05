locals {
  default_group = {
    use_name_prefix = true
    name            = var.default_group_name

    launch_template_use_name_prefix = true
    launch_template_name            = var.default_group_launch_template_name

    platform      = "bottlerocket"
    ami_id        = data.aws_ami.eks_default_bottlerocket.id
    instance_type = var.default_group_instance_type

    min_size = var.default_group_min_size
    max_size = var.default_group_max_size

    subnet_ids = coalescelist(var.default_group_subnet_ids, var.subnet_ids)

    only_critical_addons_enabled = var.only_critical_addons_enabled

    # See https://github.com/bottlerocket-os/bottlerocket#settings
    bootstrap_extra_args = <<-EOT
      # The admin host container provides SSH access and runs with "superpowers".
      # It is disabled by default, but can be disabled explicitly.
      [settings.host-containers.admin]
      enabled = false
      # The control host container provides out-of-band access via SSM.
      # It is enabled by default, and can be disabled if you do not expect to use SSM.
      # This could leave you with no way to access the API and change settings on an existing node!
      [settings.host-containers.control]
      enabled = true
      [settings.kubernetes.node-labels]
      ingress = "allowed"
      %{if var.only_critical_addons_enabled}
      [settings.kubernetes.node-taints]
      CriticalAddonsOnly=true:NoSchedule
      %{endif}
      EOT

    # See https://github.com/bottlerocket-os/bottlerocket#default-volumes
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 5
          volume_type           = "gp3"
          encrypted             = true
          kms_key_id            = module.kms_ebs.key_arn
          delete_on_termination = true
        }
      }
      xvdb = {
        device_name = "/dev/xvdb"
        ebs = {
          volume_size           = var.default_group_volume_size
          volume_type           = "gp3"
          encrypted             = true
          kms_key_id            = module.kms_ebs.key_arn
          delete_on_termination = true
        }
      }
    }
  }

  self_managed_node_groups = merge(
    { default = local.default_group },
    var.self_managed_node_groups,
  )
}
module "node_groups" {
  source = "./modules/self_managed_nodes"

  cluster_name = module.eks.cluster_id

  worker_iam_instance_profile_arn = aws_iam_instance_profile.workers.arn

  cluster_security_group_id = module.eks.cluster_security_group_id
  worker_security_group_id  = module.eks.node_security_group_id

  self_managed_node_groups         = local.self_managed_node_groups
  self_managed_node_group_defaults = var.self_managed_node_group_defaults

  node_termination_handler_sqs_arn = module.node_termination_handler_sqs.sqs_queue_arn

  force_imdsv2 = var.force_imdsv2
  force_irsa   = var.force_irsa
}

################################################
# Instance Refresh supporting resources
# See example at https://github.com/terraform-aws-modules/terraform-aws-eks/tree/v18.7.2/examples/irsa_autoscale_refresh
################################################
locals {
  nth_sqs_name = coalesce(var.node_termination_handler_sqs_name, "${var.cluster_name}-nth")
}

data "aws_iam_policy_document" "node_termination_handler_sqs" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.nth_sqs_name}"]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com",
        "sqs.amazonaws.com",
      ]
    }
  }
}

module "node_termination_handler_sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "~> 3.0"

  name                      = local.nth_sqs_name
  message_retention_seconds = 300
  policy                    = data.aws_iam_policy_document.node_termination_handler_sqs.json
}

# Handler Spot Instances termination
resource "aws_cloudwatch_event_rule" "node_termination_handler_spot" {
  name        = coalesce(var.node_termination_handler_spot_event_name, "${var.cluster_name}-spot-termination")
  description = "Node termination event rule for EKS Cluster ${var.cluster_name}"
  event_pattern = jsonencode({
    source      = ["aws.ec2"],
    detail-type = ["EC2 Spot Instance Interruption Warning"]
  })
}

resource "aws_cloudwatch_event_target" "node_termination_handler_spot" {
  target_id = coalesce(var.node_termination_handler_spot_event_name, "${var.cluster_name}-spot-termination")
  rule      = aws_cloudwatch_event_rule.node_termination_handler_spot.name
  arn       = module.node_termination_handler_sqs.sqs_queue_arn
}

################################################
# Resources below are to enable Windows Support for Cluster. 
################################################

locals {
  aws_vpc_cni_configmap_data = {
    enable-windows-ipam = "true"
  }
}

resource "kubernetes_config_map" "amazon_vpc_cni" {
  count = var.enable_cluster_windows_support ? 1 : 0

  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = local.aws_vpc_cni_configmap_data
}
