locals {
  # Calculate subnet CIDRs automatically
  public_subnet_cidrs = [
    for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  private_subnet_cidrs = [
    for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  # Common tags for all VPC resources
  vpc_tags = merge(var.tags, {
    Component = "networking"
    Module    = "vpc"
  })
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-vpc"
    Type = "vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-igw"
    Type = "internet-gateway"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    AZ   = var.availability_zones[count.index]
    Tier = "public"
  })
}

# Private Subnets (if enabled)
resource "aws_subnet" "private" {
  count = var.enable_private_subnets ? length(var.availability_zones) : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    AZ   = var.availability_zones[count.index]
    Tier = "private"
  })
}

# Elastic IPs for NAT Gateways (if private subnets enabled)
resource "aws_eip" "nat" {
  count = var.enable_private_subnets && var.enable_nat_gateway ? length(var.availability_zones) : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
    AZ   = var.availability_zones[count.index]
  })
}

# NAT Gateways (if private subnets enabled)
resource "aws_nat_gateway" "main" {
  count = var.enable_private_subnets && var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
    AZ   = var.availability_zones[count.index]
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for high availability)
resource "aws_route_table" "private" {
  count = var.enable_private_subnets ? length(var.availability_zones) : 0

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
    AZ   = var.availability_zones[count.index]
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.enable_private_subnets ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}