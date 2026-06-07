variable "vm_types" {
    type = string
    description = "Allowed VM types for EC2 instances"  
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "tags" {
  description = "Tags for VPC"
  type        = map(string)
}

variable "public_subnet_id" {
  type = string
}

variable "private_subnet_id" {
  type = string
}

variable "ami_id" {

    description = "AMI ID for EC2 instances"
    type        = string
  
}

variable "bastion_sg_id" {
  type = string
}

variable "private_sg_id" {
  type = string
}