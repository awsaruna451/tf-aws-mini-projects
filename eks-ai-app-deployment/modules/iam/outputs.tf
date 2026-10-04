output "eso_role_arn" {
  description = "ARN of the External Secrets Operator IAM role"
  value       = aws_iam_role.eso_role.arn
}

output "argocd_role_arn" {
  description = "ARN of the ArgoCD IAM role"
  value       =  aws_iam_role.argocd_role.arn
}


# iam/outputs.tf
output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi_role.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_ci.arn
}

output "lbc_role_arn" {
  value = one(aws_iam_role.lbc_role[*].arn)
}