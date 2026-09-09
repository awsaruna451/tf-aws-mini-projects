variable "name_prefix" {
  type = string
}

variable "secret_values" {
  description = "Map of key/value pairs to store as JSON in Secrets Manager"
  type        = map(string)
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
