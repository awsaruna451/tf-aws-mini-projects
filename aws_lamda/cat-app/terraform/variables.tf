variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app_name" {
  description = "Base name of the application, combined with environment for resource naming"
  type        = string
  default     = "cat-app"
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "lambda_zip_path" {
  description = "Path to the zipped Lambda deployment package (e.g. ../lambda.zip)"
  type        = string
  default     = "../lambda.zip"
}

variable "handler" {
  description = "Lambda handler in file.export form"
  type        = string
  default     = "dist/lambda.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs20.x"
}

variable "memory_size" {
  description = "Memory allocated to the function (MB)"
  type        = number
  default     = 512
}

variable "timeout" {
  description = "Function timeout in seconds"
  type        = number
  default     = 30
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function at runtime"
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Extra tags applied to all resources (merged with defaults)"
  type        = map(string)
  default     = {}
}
