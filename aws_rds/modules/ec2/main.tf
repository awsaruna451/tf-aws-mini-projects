resource "aws_instance" "rds_ec2_bastion" {
  ami           = var.ami_id
  instance_type = var.vm_types
  subnet_id = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.rds_bastion_sg.id]
  associate_public_ip_address = true
   tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-rds-bastion-instance-ec2"
    }
  )

}

resource "aws_security_group" "rds_bastion_sg" {
  name   = "${var.name_prefix}-bastion-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH from office/home"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

     tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-bastion-sg"
    }
  )
}