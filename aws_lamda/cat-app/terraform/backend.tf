terraform {
  backend "s3" {
    bucket       = "my-terraform-state-bucket-aruna451"  # Replace with your S3 bucket name
    key          = "envs/dev/cat-app/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true   # S3 native locking
  }
}