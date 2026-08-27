variable "bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
  default     = "cdn-static-website-bucket-451"
}

variable "environment" {
    default     = "dev"
  
}

variable "aws_region" {
    description = "AWS region for the deployment"
    type        = string
    default     = "us-east-1"
}