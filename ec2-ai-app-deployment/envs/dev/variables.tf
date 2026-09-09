variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "app_name" {
  type    = string
  default = "ai-agent-platform"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "az_count" {
  type    = number
  default = 2
}

variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "key_pair_name" {
  description = "Existing EC2 key pair name (optional if using SSM only)"
  type        = string
  default     = null
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH (leave null to disable SSH entirely and rely on SSM)"
  type        = string
  default     = null
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 3
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "cpu_high_threshold" {
  type    = number
  default = 70
}

variable "cpu_low_threshold" {
  type    = number
  default = 20
}

variable "alert_email" {
  type    = string
  default = ""
}

variable "certificate_arn" {
  description = "ACM cert ARN for HTTPS on the ALB (recommended for production)"
  type        = string
  default     = null
}

# --- Database ---
variable "db_password" {
  type      = string
  sensitive = true
}

variable "rds_instance_class" {
  type    = string
  default = "db.t4g.medium"
}

variable "rds_multi_az" {
  type    = bool
  default = true
}

# --- App secrets / images ---
variable "openai_api_key" {
  type      = string
  sensitive = true
}

variable "ai_agent_image_tag" {
  type    = string
  default = "latest"
}

variable "fastapi_image_tag" {
  type    = string
  default = "latest"
}

variable "mcp_server_image_tag" {
  type    = string
  default = "latest"
}

variable "frontend_image_tag" {
  type    = string
  default = "latest"
}

variable "github_org" {
  description = "GitHub org or user that owns the repos allowed to assume the deploy role, e.g. 'your-org'"
  type        = string
  default = "awsaruna451"
}

variable "google_api_key" {
  description = "API key for Google services (e.g. Gemini/Places)."
  type        = string
  sensitive   = true
}

variable "openweather_api_key" {
  description = "API key for OpenWeather (used by the get_weather tool)."
  type        = string
  sensitive   = true
}

variable "alphavantage_api_key" {
  description = "API key for Alpha Vantage (used by the get_stock_quote tool)."
  type        = string
  sensitive   = true
}

