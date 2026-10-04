module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project}-${var.env}-cluster"
  kubernetes_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  endpoint_private_access = true #-- This controls whether the EKS Kubernetes API server can be accessed through the private VPC endpoint.
  #-- resources inside your VPC can communicate with the Kubernetes API without going through the public internet endpoint. --
  endpoint_public_access  = true # -- in production do we need to set this to false? check this ---

  enable_irsa                              = true #-- It allows a Kubernetes service account to assume an AWS IAM role.Without IRSA, you might give an entire node an IAM role:
  enable_cluster_creator_admin_permissions = true #-- This gives the IAM principal that creates the EKS cluster administrative Kubernetes permissions.The identity running Terraform gets administrator-level Kubernetes access to the newly created cluster.

  # --- add this block ---
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1" #--All protocols.
      from_port   = 0  #--All ports.
      to_port     = 0 #-- this effectively means all traffic rather than TCP/UDP port 0 specifically.
      type        = "ingress" #-- Traffic coming into the nodes.
      self        = true #-- This means the rule applies to traffic coming from the same security group, which is the node security group itself.
    }
  }
  # -----------------------

    addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = { ENABLE_PREFIX_DELEGATION = "true" }
      })
    }
    kube-proxy             = { most_recent = true }
    coredns                = { most_recent = true }
    eks-pod-identity-agent = { most_recent = true }

    aws-ebs-csi-driver = {
      most_recent                 = true
      service_account_role_arn    = var.ebs_csi_role_arn
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    main = {
      instance_types = var.instance_types
      capacity_type  = var.capacity_type
      min_size       = var.min_size
      max_size       = var.max_size
      desired_size   = var.desired_size
    }
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}