output "repository_urls" {
  value = { for name, repo in aws_ecr_repository.ai_app_ecr : name => repo.repository_url }
}
