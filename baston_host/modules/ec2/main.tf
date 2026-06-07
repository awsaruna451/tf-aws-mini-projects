resource "aws_instance" "bastion_ec2" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.vm_types
  subnet_id = var.public_subnet_id
   vpc_security_group_ids = [var.bastion_sg_id]
  associate_public_ip_address = true
   tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-bastion-instance-ec2"
    }
  )

}

resource "aws_instance" "private_ec2" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = var.vm_types

  subnet_id = var.private_subnet_id
  vpc_security_group_ids = [
    var.private_sg_id
  ]

  associate_public_ip_address = false

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-instance-ec2"
    }
  )
}

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
