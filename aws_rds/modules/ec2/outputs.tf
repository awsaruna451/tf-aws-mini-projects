output "rds_bastion_sg_id" {
  description = "Security group ID of the RDS bastion EC2 instance"
  value       = aws_security_group.rds_bastion_sg.id
}