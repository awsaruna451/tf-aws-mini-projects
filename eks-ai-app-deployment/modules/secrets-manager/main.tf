resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "/tf-practice/${var.env}/db-credentials"
  description             = "Database credentials for the pharma ${var.env} environment"
  recovery_window_in_days = 0

  tags = {
    Name    = "/tf-practice/${var.env}/db-credentials"
    Env     = var.env
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = var.db_host
  })
}

resource "aws_secretsmanager_secret" "openweather_api_key" {
  name                    = "/tf-practice/${var.env}/openweather-api-key"
  description             = "OpenWeather API key for the tf-practice ${var.env} environment"
  recovery_window_in_days = 0

  tags = {
    Name    = "/tf-practice/${var.env}/openweather-api-key"
    Env     = var.env
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "openweather_api_key" {
  secret_id = aws_secretsmanager_secret.openweather_api_key.id
  secret_string = jsonencode({
    openweather_api_key = var.openweather_api_key
  })
}

resource "aws_secretsmanager_secret" "alpha_vantage_api_key" {
  name                    = "/tf-practice/${var.env}/alpha-vantage-api-key"
  description             = "Alpha Vantage API key for the tf-practice ${var.env} environment"
  recovery_window_in_days = 0

  tags = {
    Name    = "/tf-practice/${var.env}/alpha-vantage-api-key"
    Env     = var.env
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "alpha_vantage_api_key" {
  secret_id = aws_secretsmanager_secret.alpha_vantage_api_key.id
  secret_string = jsonencode({
    alpha_vantage_api_key = var.alpha_vantage_api_key
  })
}


resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "/tf-practice/${var.env}/openai-api-key"
  description             = "OpenAI API key for the tf-practice ${var.env} environment"
  recovery_window_in_days = 0

  tags = {
    Name    = "/tf-practice/${var.env}/openai-api-key"
    Env     = var.env
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id = aws_secretsmanager_secret.openai_api_key.id
  secret_string = jsonencode({
    openai_api_key = var.openai_api_key
  })
}



resource "aws_secretsmanager_secret" "google_api_key" {
  name                    = "/tf-practice/${var.env}/google-api-key"
  description             = "Google API key for the tf-practice ${var.env} environment"
  recovery_window_in_days = 0

  tags = {
    Name    = "/tf-practice/${var.env}/google-api-key"
    Env     = var.env
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "google_api_key" {
  secret_id = aws_secretsmanager_secret.google_api_key.id
  secret_string = jsonencode({
    google_api_key = var.google_api_key
  })
}