resource "aws_vpc" "aws_vpc_primary" {
  cidr_block           = var.primary_vpc_cider
  provider             = aws.primary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Primary-VPC-${var.primary}"
  }
}

resource "aws_vpc" "aws_vpc_secondary" {
  cidr_block           = var.secondary_vpc_cider
  provider             = aws.secondary
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "Secondary-VPC-${var.secondary}"  # Fix: was "Primary-VPC-"
  }
}

resource "aws_subnet" "primary_subnet" {
  provider                = aws.primary
  vpc_id                  = aws_vpc.aws_vpc_primary.id
  cidr_block              = var.primary_vpc_cider
  availability_zone       = data.aws_availability_zones.primary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Primary-subnet-${var.primary}"
  }
}

resource "aws_subnet" "secondary_subnet" {
  provider                = aws.secondary
  vpc_id                  = aws_vpc.aws_vpc_secondary.id
  cidr_block              = var.secondary_vpc_cider
  availability_zone       = data.aws_availability_zones.secondary.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Secondary-subnet-${var.secondary}"
  }
}

resource "aws_internet_gateway" "primary_gw" {
  vpc_id   = aws_vpc.aws_vpc_primary.id
  provider = aws.primary

  tags = {
    Name = "Primary-gw-${var.primary}"
  }
}

resource "aws_internet_gateway" "secondary_gw" {
  vpc_id   = aws_vpc.aws_vpc_secondary.id
  provider = aws.secondary

  tags = {
    Name = "Secondary-gw-${var.secondary}"
  }
}

resource "aws_route_table" "primary_rt" {
  vpc_id   = aws_vpc.aws_vpc_primary.id
  provider = aws.primary

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_gw.id
  }

  tags = {
    Name = "Primary-route-table-${var.primary}"
  }
}

resource "aws_route_table" "secondary_rt" {
  vpc_id   = aws_vpc.aws_vpc_secondary.id
  provider = aws.secondary

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_gw.id
  }

  tags = {
    Name = "Secondary-route-table-${var.secondary}"
  }
}

resource "aws_route_table_association" "primary_rt_association" {
  provider       = aws.primary
  subnet_id      = aws_subnet.primary_subnet.id
  route_table_id = aws_route_table.primary_rt.id
}

resource "aws_route_table_association" "secondary_rt_association" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.secondary_subnet.id
  route_table_id = aws_route_table.secondary_rt.id
}

# Fix: Only ONE peering connection is needed (primary initiates, secondary accepts)
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider    = aws.primary
  peer_region = var.secondary
  peer_vpc_id = aws_vpc.aws_vpc_secondary.id
  vpc_id      = aws_vpc.aws_vpc_primary.id
  auto_accept = false

  tags = {
    Name = "Primary-to-Secondary-peering"
  }
}

# Fix: Only ONE accepter on the secondary side
resource "aws_vpc_peering_connection_accepter" "secondary_accepter" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept               = true

  tags = {
    Side = "Secondary-acceptor"  # Fix: typo
  }
}

# Fix: Both routes reference the SAME single peering connection
resource "aws_route" "primary_to_secondary_r" {
  provider                  = aws.primary
  route_table_id            = aws_route_table.primary_rt.id
  destination_cidr_block    = var.secondary_vpc_cider
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  depends_on                = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

resource "aws_route" "secondary_to_primary_r" {
  provider                  = aws.secondary
  route_table_id            = aws_route_table.secondary_rt.id
  destination_cidr_block    = var.primary_vpc_cider
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id  # Fix: same connection
  depends_on                = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

resource "aws_security_group" "primary_sg" {
  provider    = aws.primary
  name        = "primary-vpc-sg"
  description = "Security group for Primary VPC instance"
  vpc_id      = aws_vpc.aws_vpc_primary.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Secondary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.secondary_vpc_cider]
  }

  ingress {
    description = "All TCP traffic from Secondary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cider]
  }

  egress {
    description = "Allow all outbound traffic"  # Fix: typo
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Primary-VPC-SG"  # Fix: typo
  }
}

resource "aws_security_group" "secondary_sg" {
  provider    = aws.secondary
  name        = "secondary-vpc-sg"  # Fix: was "primary-vpc-sg" (name conflict risk)
  description = "Security group for Secondary VPC instance"
  vpc_id      = aws_vpc.aws_vpc_secondary.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP from Primary VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.primary_vpc_cider]
  }

  ingress {
    description = "All TCP traffic from Primary VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cider]
  }

  egress {
    description = "Allow all outbound traffic"  # Fix: typo
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Secondary-VPC-SG"  # Fix: typo
  }
}

resource "aws_instance" "primary_instance" {
  provider               = aws.primary
  ami                    = data.aws_ami.ami_primary.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.primary_subnet.id
  vpc_security_group_ids = [aws_security_group.primary_sg.id]
  key_name               = var.primary_key_name
  user_data              = local.primary_user_data

  tags = {
    Name   = "HelloWorld"
    Region = var.primary
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}

resource "aws_instance" "secondary_instance" {
  provider               = aws.secondary
  ami                    = data.aws_ami.ami_secondary.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.secondary_subnet.id
  vpc_security_group_ids = [aws_security_group.secondary_sg.id]
  key_name               = var.secondary_key_name
  user_data              = local.secondary_user_data

  tags = {
    Name   = "HelloWorld"
    Region = var.secondary
  }

  depends_on = [aws_vpc_peering_connection_accepter.secondary_accepter]
}