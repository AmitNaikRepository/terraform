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

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

locals {
  common_tags = merge(var.default_tags, {
    Module  = "security-groups"
    Purpose = "security-best-practices"
  })
}

# VPC for demonstration
resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Public subnet for web tier
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet"
    Tier = "web"
  })
}

# Private subnet for application tier
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.demo.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet"
    Tier = "application"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.demo.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Route table for public subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group 1: Web Tier (Public-facing)
resource "aws_security_group" "web_tier" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  description = "Security group for web tier (public-facing)"
  vpc_id      = aws_vpc.demo.id

  # Inbound rules - only allow necessary traffic
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from specific IP range (replace with your IP)
  ingress {
    description = "SSH from management network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  # Outbound rules - explicit allow
  egress {
    description     = "To application tier"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  egress {
    description = "HTTPS for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
    Tier = "web"
    Type = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group 2: Application Tier (Private)
resource "aws_security_group" "app_tier" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.demo.id

  # Inbound rules - only from web tier
  ingress {
    description     = "Application port from web tier"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  ingress {
    description     = "SSH from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # Outbound rules
  egress {
    description     = "To database tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.database_tier.id]
  }

  egress {
    description = "HTTPS for external APIs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for updates"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
    Tier = "application"
    Type = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group 3: Database Tier (Most Restricted)
resource "aws_security_group" "database_tier" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  description = "Security group for database tier - most restrictive"
  vpc_id      = aws_vpc.demo.id

  # Inbound rules - only from application tier
  ingress {
    description     = "MySQL/Aurora from application tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  # No outbound rules defined - default deny all egress
  # This is the most secure approach for databases

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
    Tier = "database"
    Type = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group 4: Bastion Host (Secure Access)
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-${var.environment}-bastion-"
  description = "Security group for bastion host - secure remote access"
  vpc_id      = aws_vpc.demo.id

  # Inbound rules - SSH from specific IP range only
  ingress {
    description = "SSH from management network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  # Outbound rules - SSH to private subnets only
  egress {
    description = "SSH to private subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.private.cidr_block]
  }

  egress {
    description = "HTTPS for updates"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-bastion-sg"
    Type = "bastion-security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group 5: Load Balancer (Application Load Balancer)
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.demo.id

  # Inbound rules - HTTP/HTTPS from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound rules - to web tier only
  egress {
    description     = "To web tier targets"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
    Type = "load-balancer-security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Demo instances to show security groups in action
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_tier.id]

  user_data = base64encode(templatefile("${path.module}/user_data_web.sh", {
    app_port = var.app_port
  }))

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-server"
    Tier = "web"
  })
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app_tier.id]

  user_data = base64encode(templatefile("${path.module}/user_data_app.sh", {
    app_port = var.app_port
  }))

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-server"
    Tier = "application"
  })
}