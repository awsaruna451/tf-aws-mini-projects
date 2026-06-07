variable "ecr_name" {
    description = "The name of the ECR repository"
    type        = string
    default     = "my-ex1-repo"
  
}

variable "iam_role_name" {
    description = "The name of the IAM role for ECS task execution"
    type        = string
    default     = "ecsTaskExecutionRole"
  
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24"]
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 1
}

variable "account_id" {
  description = "The AWS account ID"
  type        = string
  default     = "324037296112"
}

variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}
variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
}
