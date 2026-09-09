output "secret_arn" {
  value = aws_secretsmanager_secret.ai_app_secrets.arn
}
