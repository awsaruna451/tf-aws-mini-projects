data "aws_ami" "ami_primary" {
  most_recent = true
  provider = aws.primary
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
data "aws_ami" "ami_secondary" {
  most_recent = true
  provider = aws.secondary
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "primary" {
  provider = aws.primary
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
}