variable "db_password" {
  description = "Master password for the RDS PostgreSQL database"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Master username for the RDS PostgreSQL database"
  type        = string  
  default     = "postgres"
  
}

variable "openweather_api_key" {
  description = "OpenWeather API key"
  type        = string
  sensitive   = true
}

variable "alpha_vantage_api_key" {
  description = "Alpha Vantage API key"
  type        = string
  sensitive   = true 
}

variable "github_org" {
  description = "GitHub username or organization that "
  type        = string
  default     = "awsaruna451"
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
variable "repositories" {
  description = "Repo names shared by the ECR module and the GitHub Actions trust policy (1:1: ECR repo name == GitHub repo name)."
  type        = list(string)
  default = [
    "chat-be",
    "chat-fe",
    "mcp-server",
  ]
}

variable "github_branch" {
  description = "Branch allowed to assume this role via OIDC."
  type        = string
  default     = "dev.01"
}

variable "github_repo_names" {
  type    = list(string)
  default = ["langgraph-chat-project"]
}