variable "project" {
  description = "Project name"
  type        = string
}

variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for EKS nodes"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}


variable "capacity_type" {
  description = "Node group capacity type: ON_DEMAND or SPOT"
  type        = string
  default     = "SPOT"
}

variable "ebs_csi_role_arn" {
  type    = string
  default = null
}
