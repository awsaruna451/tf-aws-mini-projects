output "app_url" {
  description = "Public URL for the app (via ALB)"
  value       = var.certificate_arn != null ? "https://${module.alb.dns_name}" : "http://${module.alb.dns_name}"
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

output "ecr_repository_urls" {
  value = module.ecr.repository_urls
}
/*
output "rds_endpoint" {
  value = module.rds.endpoint
}*/

output "asg_name" {
  value = module.asg.asg_name
}

output "sns_topic_arn" {
  value = module.monitoring.sns_topic_arn
}

output "aws_iam_role_github_arn" {
  value = aws_iam_role.github_actions.arn
}