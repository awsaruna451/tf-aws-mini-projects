# Custom VPC Module
module "vpc" {
  source = "./modules/vpc"
  name_prefix = var.dep_name
  private_subnets = var.private_subnets
  public_subnets = var.public_subnets
  vpc_cidr = var.vpc_cidr
    tags = {
        Environment = var.environment
        Terraform   = "true"
        Project     = var.dep_name
    }

    azs = var.azs
}

module "ec2" {
  source = "./modules/ec2"
  name_prefix = var.dep_name
  ami_id = var.ami_id
  public_subnet_id  = module.vpc.public_subnet_ids[0]
  private_subnet_id = module.vpc.private_subnet_ids[0]
  bastion_sg_id     = module.sg.bastion_sg_id
  private_sg_id     = module.sg.private_ec2_sg_id

  vm_types = var.vm_types
      tags = {
        Environment = var.environment
        Terraform   = "true"
        Project     = var.dep_name
    }
}

module "sg" {
  source = "./modules/sg"

  vpc_id = module.vpc.vpc_id
  name_prefix = var.dep_name
  tags = {
    Environment = var.environment
    Terraform   = "true"
    Project     = var.dep_name
  }
}