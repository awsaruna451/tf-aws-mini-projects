variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "db_username" {
  description = "Database username to store in Secrets Manager"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database password to store in Secrets Manager"
  type        = string
  sensitive   = true
}

variable "openweather_api_key" {
  description = "OpenWeather API key to store in Secrets Manager"
  type        = string
  sensitive   = true
}

variable "alpha_vantage_api_key" {
  description = "Alpha Vantage API key to store in Secrets Manager"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "RDS endpoint hostname to store alongside credentials"
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key"
  type        = string
  sensitive   = true
}

variable "google_api_key" {
  description = "Google OAuth2 client secret"
  type        = string
  sensitive   = true
}
