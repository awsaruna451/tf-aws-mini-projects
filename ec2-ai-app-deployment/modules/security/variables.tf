variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_allowed_cidr" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
