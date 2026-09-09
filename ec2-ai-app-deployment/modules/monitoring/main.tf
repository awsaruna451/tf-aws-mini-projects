resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_high_threshold
  alarm_description   = "Scale out + alert when average CPU > ${var.cpu_high_threshold}% for 4 min"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [var.scale_out_policy_arn, aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.name_prefix}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = var.cpu_low_threshold
  alarm_description   = "Scale in when average CPU < ${var.cpu_low_threshold}% for 4 min"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [var.scale_in_policy_arn]
  tags          = var.tags
}

# Alert if in-service instance count drops below the desired minimum
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name_prefix}-unhealthy-hosts"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Minimum"
  threshold           = var.min_healthy_instances
  alarm_description   = "Fires if in-service instance count drops below ${var.min_healthy_instances}"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions      = [aws_sns_topic.alerts.arn]
  treat_missing_data = "breaching"
  tags                = var.tags
}
