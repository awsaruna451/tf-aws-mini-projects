
# Custom VPC Module
locals {
  project = "aws-rds"
  env     = "dev"
  region  = "us-east-1"
}


module "vpc" {
  source          = "../modules/vpc"
  name_prefix     = local.project
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  vpc_cidr        = var.vpc_cidr
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = local.project
  }

  azs = var.azs
}

module "ec2" {
  source = "../modules/ec2"

  name_prefix = local.project
  vm_types    = var.vm_types
  ami_id      = var.ami_id

  public_subnet_id = module.vpc.public_subnet_ids[0]
  vpc_id           = module.vpc.vpc_id

  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = local.project
  }
}

module "rds" {
  source             = "../modules/rds"
  name_prefix        = local.project
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_password        = var.db_password
  instance_class     = var.instance_class
  rds_bastion_sg_id  = module.ec2.rds_bastion_sg_id
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = local.project
  }

}