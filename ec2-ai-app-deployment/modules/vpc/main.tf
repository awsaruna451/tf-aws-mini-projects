data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs           = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  nat_count     = var.single_nat_gateway ? 1 : var.az_count
}

resource "aws_vpc" "ai_app" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name_prefix}-vpc" })
}

resource "aws_internet_gateway" "ai_app_igw" {
  vpc_id = aws_vpc.ai_app.id
  tags   = merge(var.tags, { Name = "${var.name_prefix}-igw" })
}

# Public subnets — one per AZ, hosts the ALB and NAT gateways
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.ai_app.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name_prefix}-public-${local.azs[count.index]}" })
}

# Private subnets — one per AZ, hosts the app instances and RDS
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.ai_app.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + var.az_count)
  availability_zone = local.azs[count.index]
  tags              = merge(var.tags, { Name = "${var.name_prefix}-private-${local.azs[count.index]}" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ai_app.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ai_app_igw.id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-public-rt" })
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway(s) — one per AZ by default for full HA, or one shared to cut cost
resource "aws_eip" "nat" {
  count  = local.nat_count
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name_prefix}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "ai_app_nat" {
  count         = local.nat_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.tags, { Name = "${var.name_prefix}-nat-${count.index}" })
  depends_on    = [aws_internet_gateway.ai_app_igw]
}

resource "aws_route_table" "private" {
  count  = var.az_count
  vpc_id = aws_vpc.ai_app.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.ai_app_nat[0].id : aws_nat_gateway.ai_app_nat[count.index].id
  }
  tags = merge(var.tags, { Name = "${var.name_prefix}-private-rt-${count.index}" })
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
