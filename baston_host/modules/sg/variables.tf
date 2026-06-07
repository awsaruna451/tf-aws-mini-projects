variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags for VPC"
  type        = map(string)
}

variable "vpc_id" {
  type = string
}