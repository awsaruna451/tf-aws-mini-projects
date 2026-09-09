variable "name_prefix" {
  type = string
}

variable "repo_names" {
  description = "List of ECR repository names to create, e.g. [\"ai-agent\", \"fastapi\", \"mcp-server\", \"frontend\"]"
  type        = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
