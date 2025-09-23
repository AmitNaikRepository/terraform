terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Security-focused network design
  vpc_cidr = "10.0.0.0/16"
  
  # Network segmentation for security isolation
  network_config = {
    # Public subnets for load balancers only
    public_subnets = [
      "10.0.1.0/24",  # AZ-a Public
      "10.0.2.0/24",  # AZ-b Public
    ]
    
    # Private subnets for application servers
    private_subnets = [
      "10.0.11.0/24", # AZ-a Private
      "10.0.12.0/24", # AZ-b Private
    ]
    
    # Database subnets with additional isolation
    database_subnets = [
      "10.0.21.0/24", # AZ-a Database
      "10.0.22.0/24", # AZ-b Database
    ]
  }
  
  # Security tagging for compliance
  security_tags = merge(var.default_tags, {
    SecurityLevel = "high"
    DataClass     = "sensitive"
  })
}

# VPC with security-focused configuration
resource "aws_vpc" "secure" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-secure-vpc"
    Type = "vpc"
  })
}

# VPC Flow Logs for security monitoring
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.secure.id

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
    Type = "security-monitoring"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-log-group"
    Type = "logging"
  })
}

# IAM role for VPC Flow Logs
resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = local.security_tags
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Internet Gateway (public access point)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.secure.id

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
    Type = "gateway"
  })
}

# Public Subnets (DMZ - only for load balancers)
resource "aws_subnet" "public" {
  count = length(local.network_config.public_subnets)

  vpc_id                  = aws_vpc.secure.id
  cidr_block              = local.network_config.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false  # Security: No automatic public IPs

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    Tier = "dmz"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Private Subnets (Application Tier)
resource "aws_subnet" "private" {
  count = length(local.network_config.private_subnets)

  vpc_id            = aws_vpc.secure.id
  cidr_block        = local.network_config.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    Tier = "application"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Database Subnets (Data Tier)
resource "aws_subnet" "database" {
  count = length(local.network_config.database_subnets)

  vpc_id            = aws_vpc.secure.id
  cidr_block        = local.network_config.database_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-database-subnet-${count.index + 1}"
    Type = "database-subnet"
    Tier = "data"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# NAT Gateways for secure outbound access
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables with security-focused routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.secure.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.secure.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Database route table (no internet access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.secure.id

  # No default route - database tier is isolated

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-database-rt"
    Type = "route-table"
    Tier = "database"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}