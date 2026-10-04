variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC provider"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username that owns zen-pharma-frontend and zen-pharma-backend"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch allowed to assume this role via OIDC"
  type        = string
}

variable "enable_irsa_roles" {
  type    = bool
  default = false
}

variable "github_org_id" {
  type    = string
  default = "83629626"
}

variable "github_repos" {
  description = "Map of repo name => numeric repo ID"
  type        = map(string)
  default = {
    "langgraph-chat-project" = "1305560371"
  }
}
