variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}


variable "name_prefix" {
    description = "Prefix for resource names"
    type        = string
}

variable "db_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags for RDS resources"
  type        = map(string)
  default     = {}
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "rds_bastion_sg_id" {
  description = "Security group ID of the RDS bastion EC2 instance"
  type        = string
}