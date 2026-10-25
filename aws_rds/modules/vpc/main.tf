resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-vpc"
    }
  )
}

resource "aws_internet_gateway" "rds-igw" {
  vpc_id = aws_vpc.main.id
  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-igw"
    }
  )
}

# Public Subnets
resource "aws_subnet" "rds-public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    var.public_subnet_tags,
    {
      Name = "${var.name_prefix}-public-${var.azs[count.index]}"
      Type = "public"
    }
  )
}

# Elastic IP for NAT Gateway
resource "aws_eip" "rds-eip" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.rds-igw]
}

# NAT Gateway
resource "aws_nat_gateway" "rds-nat" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  allocation_id = aws_eip.rds-eip[count.index].id
  subnet_id     = aws_subnet.rds-public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-nat-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.rds-igw]
}


# Public Route Table
resource "aws_route_table" "rds-public-rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-public-rt"
    }
  )
}


# Public Route Table Association
resource "aws_route_table_association" "rds-public-rt-assoc" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.rds-public[count.index].id
  route_table_id = aws_route_table.rds-public-rt.id
}

# Public Route to Internet Gateway
resource "aws_route" "rds-public-route" {
  route_table_id         = aws_route_table.rds-public-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rds-igw.id
}

# Private Subnets
resource "aws_subnet" "rds-private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge(
    var.tags,
    var.private_subnet_tags,
    {
      Name = "${var.name_prefix}-private-${var.azs[count.index]}"
      Type = "private"
    }
  )
}

# Private Route Table
resource "aws_route_table" "rds-private-rt" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-private-rt"
    }
  )
}

# Private Route Table Association
resource "aws_route_table_association" "rds-private-rt-assoc" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.rds-private[count.index].id
  route_table_id = aws_route_table.rds-private-rt.id
}

# Private Route to NAT Gateway
resource "aws_route" "rds-private-route" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  route_table_id         = aws_route_table.rds-private-rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.rds-nat[count.index].id
}