data "aws_ami" "ai_app" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "ai_app_launch_template" {
  name_prefix   = "${var.name_prefix}-lt-"
  image_id      = data.aws_ami.ai_app.id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false # private subnet; reached via ALB only
    security_groups              = [var.app_sg_id]
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.root_volume_size
      volume_type            = "gp3"
      delete_on_termination  = true
      encrypted               = true
    }
  }

  metadata_options {
    http_tokens = "required" # enforce IMDSv2
  }

  user_data = base64encode(var.user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name_prefix}-instance" })
  }

  lifecycle {
    create_before_destroy = true

    # `data.aws_ami.ai_app` re-resolves to whatever Canonical's newest
    # matching AMI is on EVERY plan/apply. Without this, an unrelated
    # change (e.g. resizing the ASG, updating a security group) can pick
    # up a new AMI ID as a side effect, which changes this launch
    # template, which — combined with the instance_refresh block below —
    # silently triggers a full rolling replacement of every instance.
    # That replacement is only safe now because user_data actually
    # deploys the app on boot; before that fix, it meant total app loss.
    #
    # AMI upgrades should be a deliberate, reviewed action, not a side
    # effect. To intentionally roll to the latest AMI when you actually
    # want to (e.g. monthly patching), run:
    #   terraform apply -replace=module.<x>.aws_launch_template.ai_app_launch_template
    ignore_changes = [image_id]
  }
}

resource "aws_autoscaling_group" "ai_app_asg" {
  name                = "${var.name_prefix}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids # spans all AZs passed in -> multi-AZ
  target_group_arns   = var.target_group_arns
  health_check_type         = "ELB"
  health_check_grace_period = 1200

  launch_template {
    id      = aws_launch_template.ai_app_launch_template.id
    version = "$Latest"
  }

  # Spread instances evenly across AZs
  availability_zone_distribution {
    capacity_distribution_strategy = "balanced-best-effort"
  }

  # Roll instances gradually when the launch template changes (new AMI
  # via an explicit -replace, or a genuine user_data/instance_type change).
  # New-image application deploys are triggered explicitly by CI calling
  # `aws autoscaling start-instance-refresh` after a successful ECR push —
  # see .github/workflows/_build-push-ecr.yml — rather than relying on
  # this block firing from a Terraform apply.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 600
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "${var.name_prefix}-scale-out"
  autoscaling_group_name = aws_autoscaling_group.ai_app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment      = 1
  cooldown                = 300
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "${var.name_prefix}-scale-in"
  autoscaling_group_name = aws_autoscaling_group.ai_app_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment      = -1
  cooldown                = 300
}
