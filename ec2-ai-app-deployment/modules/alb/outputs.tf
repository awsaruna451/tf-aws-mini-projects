output "dns_name" {
  value = aws_lb.ai_app_alb.dns_name
}


output "alb_arn" {
  value = aws_lb.ai_app_alb.arn
}

output "target_group_arns" {
  value = [
    aws_lb_target_group.chat_fe.arn,
    aws_lb_target_group.chat_be.arn,
    aws_lb_target_group.mcp_cal_server.arn
  ]
}
