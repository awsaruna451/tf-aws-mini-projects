variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS. Leave null to serve HTTP only (fine for initial testing, not for production)"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "backend_health_check_path" {
  description = "Health check path for chat-be"
  type        = string
  default     = "/health"  # ← confirm chat-be actually exposes this, else use "/"
}

variable "mcp_health_check_path" {
  description = "Health check path for mcp-cal-server"
  type        = string
  default     = "/health"  # ← confirm mcp-cal-server actually exposes this, else use "/"
}
