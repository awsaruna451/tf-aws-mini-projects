variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "dep_name" {
    description = "Deployment name for resource naming"
    type        = string
    default     = "baston-host"
  
}

variable "environment" {
    description = "Deployment environment (e.g., dev, staging, prod)"
    type        = string
    default     = "dev"
  
}
variable "azs" {
    description = "List of availability zones"
    type        = list(string)
    default     = ["us-east-1a", "us-east-1b"]
  
}
  
variable "aws_region" {
    description = "AWS region for the deployment"
    type        = string
    default     = "us-east-1"
}

variable "ami_id" {
    description = "AMI ID for EC2 instances"
    type        = string
    default     = "resolve:ssm:/aws/service/ami-amazon-linux-latest" # Amazon Linux 2 AMI (HVM), SSD Volume Type
  
}

variable "vm_types" {
    type = string
    default = "t3.micro"
    description = "Allowed VM types for EC2 instances"  
}
