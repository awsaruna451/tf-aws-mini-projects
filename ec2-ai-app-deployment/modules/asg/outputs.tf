output "asg_name" {
  value = aws_autoscaling_group.ai_app_asg.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.scale_in.arn
}
