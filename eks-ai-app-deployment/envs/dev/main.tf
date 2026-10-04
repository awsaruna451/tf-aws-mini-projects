locals {
  project = "ai-application"
  env     = "dev"
  region  = "us-east-1"
}
# ai-application-dev-cluster

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  project               = local.project
  env                   = local.env
  region                = local.region
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  database_subnet_cidrs = ["10.0.5.0/24", "10.0.6.0/24"]
}

module "eks" {
  source = "../../modules/eks"

  project            = local.project
  env                = local.env
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  kubernetes_version = "1.34"
  instance_types     = ["t3.medium"]
  capacity_type      = "SPOT"
  min_size           = 2
  max_size           = 3
  desired_size       = 2
 

  ebs_csi_role_arn   = module.iam.ebs_csi_role_arn
}
/*
module "rds" {
  source = "../../modules/rds"

  project                    = local.project
  env                        = local.env
  username                   = var.db_username
  password                   = var.db_password
  vpc_id                     = module.vpc.vpc_id
  db_subnet_group_name       = module.vpc.database_subnet_group_name
  eks_node_security_group_id = module.eks.node_security_group_id
} */

module "ecr" {
  source = "../../modules/ecr"

  project = local.project
  env     = local.env
  repositories = var.repositories
}


module "iam" {
  source = "../../modules/iam"

  project           = local.project
  env               = local.env
  oidc_provider_arn =  module.eks.oidc_provider_arn
  oidc_provider_url =  module.eks.cluster_oidc_issuer_url
  aws_account_id    = data.aws_caller_identity.current.account_id
  github_org        = var.github_org
  
  github_branch     = var.github_branch
  enable_irsa_roles = true #var.enable_irsa_roles need to remove this 
  github_org_id     = "83629626"
  github_repos      = {
    "langgraph-chat-project" = "1305560371"
  }

}

module "secrets_manager" {
  source = "../../modules/secrets-manager"

  project     = local.project
  env         = local.env
  db_username = var.db_username
  db_password = var.db_password
  db_host     =  "" #module.rds.db_instance_address
  openweather_api_key  = var.openweather_api_key
  openai_api_key     = var.openai_api_key
  google_api_key = var.google_api_key
  alpha_vantage_api_key = var.alpha_vantage_api_key
}

resource "helm_release" "lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set = [{
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  ,{
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }
  ,{
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.iam.lbc_role_arn
  }
  , {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
  ]

  depends_on = [module.eks, module.iam]
}


