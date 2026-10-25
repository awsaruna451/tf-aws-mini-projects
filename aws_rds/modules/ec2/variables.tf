variable "name_prefix" {
    description = "Prefix for resource names"
    type        = string
}

variable "tags" {
  description = "Tags for RDS resources"
  type        = map(string)
  default     = {}
}

variable "vm_types" {
    type = string
    description = "Allowed VM types for EC2 instances"
}

variable "public_subnet_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ami_id" {
    description = "AMI ID for EC2 instances"
    type        = string
}