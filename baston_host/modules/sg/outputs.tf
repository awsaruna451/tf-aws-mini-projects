output "bastion_sg_id" {
  value = aws_security_group.bastion.id
}

output "private_ec2_sg_id" {
  value = aws_security_group.private_ec2.id
}