variable "bucket_name" {
  description = "The name of the S3 bucket to create"
  type        = string
  default     = "my-static-website-bucket-451"
}

variable "environment" {
    default     = "dev"
  
}