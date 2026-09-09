resource "aws_secretsmanager_secret" "ai_app_secrets" {
  name = "${var.name_prefix}-secrets"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "ai_app_secret_version" {
  secret_id     = aws_secretsmanager_secret.ai_app_secrets.id
  secret_string = jsonencode(var.secret_values)
}
