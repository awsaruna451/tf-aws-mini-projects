variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread across"
  type        = number
  default     = 2
}

variable "single_nat_gateway" {
  description = "Use one NAT gateway instead of one-per-AZ to cut cost (tradeoff: less HA for outbound traffic)"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
