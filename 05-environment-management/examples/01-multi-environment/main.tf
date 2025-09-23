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
  # Environment-specific configurations
  environment_config = {
    dev = {
      instance_type         = "t3.micro"
      min_size             = 1
      max_size             = 2
      desired_capacity     = 1
      volume_size          = 20
      enable_monitoring    = false
      enable_backup        = false
      retention_days       = 7
      multi_az             = false
      database_size        = "db.t3.micro"
      cache_node_type      = "cache.t3.micro"
      ssl_policy           = "ELBSecurityPolicy-2016-08"
    }
    staging = {
      instance_type         = "t3.small"
      min_size             = 2
      max_size             = 4
      desired_capacity     = 2
      volume_size          = 30
      enable_monitoring    = true
      enable_backup        = true
      retention_days       = 30
      multi_az             = true
      database_size        = "db.t3.small"
      cache_node_type      = "cache.t3.small"
      ssl_policy           = "ELBSecurityPolicy-TLS-1-2-2017-01"
    }
    prod = {
      instance_type         = "t3.medium"
      min_size             = 3
      max_size             = 10
      desired_capacity     = 3
      volume_size          = 50
      enable_monitoring    = true
      enable_backup        = true
      retention_days       = 90
      multi_az             = true
      database_size        = "db.t3.medium"
      cache_node_type      = "cache.t3.small"
      ssl_policy           = "ELBSecurityPolicy-TLS-1-2-2017-01"
    }
  }

  # Current environment configuration
  env_config = local.environment_config[var.environment]

  # Environment-specific tags
  environment_tags = merge(var.default_tags, {
    Environment   = var.environment
    Project       = var.project_name
    Terraform     = "true"
    Module        = "multi-environment"
    CostCenter    = var.environment == "prod" ? "production" : "development"
    Backup        = local.env_config.enable_backup ? "enabled" : "disabled"
    Monitoring    = local.env_config.enable_monitoring ? "enabled" : "basic"
  })

  # Environment-specific naming
  name_prefix = "${var.project_name}-${var.environment}"

  # Network configuration
  vpc_cidr = var.environment == "prod" ? "10.0.0.0/16" : 
             var.environment == "staging" ? "10.1.0.0/16" : "10.2.0.0/16"
  
  subnet_cidrs = {
    public = [
      cidrsubnet(local.vpc_cidr, 8, 1),
      cidrsubnet(local.vpc_cidr, 8, 2)
    ]
    private = [
      cidrsubnet(local.vpc_cidr, 8, 11),
      cidrsubnet(local.vpc_cidr, 8, 12)
    ]
    database = [
      cidrsubnet(local.vpc_cidr, 8, 21),
      cidrsubnet(local.vpc_cidr, 8, 22)
    ]
  }
}

# VPC with environment-specific configuration
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-vpc"
    Type = "networking"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-igw"
    Type = "networking"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = local.env_config.multi_az ? 2 : 1

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidrs.public[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    Tier = "public"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = local.env_config.multi_az ? 2 : 1

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidrs.private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    Tier = "private"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Database Subnets
resource "aws_subnet" "database" {
  count = local.env_config.multi_az ? 2 : 1

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.subnet_cidrs.database[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-database-subnet-${count.index + 1}"
    Type = "database-subnet"
    Tier = "database"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# NAT Gateway (only for staging and production)
resource "aws_eip" "nat" {
  count = var.environment != "dev" ? (local.env_config.multi_az ? 2 : 1) : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
  })
}

resource "aws_nat_gateway" "main" {
  count = var.environment != "dev" ? (local.env_config.multi_az ? 2 : 1) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

resource "aws_route_table" "private" {
  count = var.environment != "dev" ? (local.env_config.multi_az ? 2 : 1) : 1

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.environment != "dev" ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
    }
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
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
  route_table_id = aws_route_table.private[count.index % length(aws_route_table.private)].id
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web-"
  description = "Security group for web tier - ${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Environment-specific SSH access
  dynamic "ingress" {
    for_each = var.environment == "prod" ? [] : [1]
    content {
      description = "SSH for ${var.environment}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.management_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-web-sg"
    Type = "security-group"
    Tier = "web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${local.name_prefix}-app-"
  description = "Security group for app tier - ${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from web tier"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  # Environment-specific SSH access
  dynamic "ingress" {
    for_each = var.environment == "prod" ? [] : [1]
    content {
      description = "SSH for ${var.environment}"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [var.management_cidr]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-app-sg"
    Type = "security-group"
    Tier = "app"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${local.name_prefix}-db-"
  description = "Security group for database tier - ${var.environment}"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL/Aurora from app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-db-sg"
    Type = "security-group"
    Tier = "database"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Launch Template with environment-specific configuration
resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.env_config.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  monitoring {
    enabled = local.env_config.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = local.env_config.volume_size
      volume_type           = "gp3"
      encrypted             = var.environment == "prod" ? true : false
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment         = var.environment
    project_name        = var.project_name
    app_port           = var.app_port
    instance_type      = local.env_config.instance_type
    monitoring_enabled = local.env_config.enable_monitoring
    backup_enabled     = local.env_config.enable_backup
    retention_days     = local.env_config.retention_days
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.environment_tags, {
      Name = "${local.name_prefix}-web-instance"
      Type = "web-server"
      Tier = "web"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group with environment-specific scaling
resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-web-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = local.env_config.min_size
  max_size         = local.env_config.max_size
  desired_capacity = local.env_config.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Environment-specific scaling policies
  enabled_metrics = local.env_config.enable_monitoring ? [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ] : []

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.environment_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Load Balancer with environment-specific configuration
resource "aws_lb" "web" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.environment == "prod" ? true : false

  # Environment-specific access logging
  dynamic "access_logs" {
    for_each = local.env_config.enable_monitoring ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].bucket
      prefix  = "alb-logs"
      enabled = true
    }
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-alb"
    Type = "load-balancer"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${local.name_prefix}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = var.environment == "prod" ? 3 : 2
    interval            = var.environment == "prod" ? 15 : 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = var.environment == "prod" ? 10 : 5
    unhealthy_threshold = var.environment == "prod" ? 2 : 3
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-web-tg"
    Type = "target-group"
  })
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = local.env_config.ssl_policy
  certificate_arn   = aws_acm_certificate_validation.web[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }

  depends_on = [aws_acm_certificate_validation.web]
}

# HTTP to HTTPS redirect
resource "aws_lb_listener" "web_redirect" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# S3 bucket for ALB logs (staging and prod only)
resource "aws_s3_bucket" "alb_logs" {
  count = local.env_config.enable_monitoring ? 1 : 0

  bucket        = "${local.name_prefix}-alb-logs-${random_string.bucket_suffix.result}"
  force_destroy = var.environment != "prod"

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-alb-logs"
    Type = "logging"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  count = local.env_config.enable_monitoring ? 1 : 0

  bucket = aws_s3_bucket.alb_logs[0].id
  versioning_configuration {
    status = var.environment == "prod" ? "Enabled" : "Suspended"
  }
}

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-db-subnet-group"
    Type = "database"
  })
}

# RDS Instance with environment-specific configuration
resource "aws_db_instance" "main" {
  count = var.create_database ? 1 : 0

  identifier     = "${local.name_prefix}-database"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = local.env_config.database_size

  allocated_storage     = var.environment == "prod" ? 100 : (var.environment == "staging" ? 50 : 20)
  max_allocated_storage = var.environment == "prod" ? 1000 : (var.environment == "staging" ? 200 : 100)

  db_name  = "${var.project_name}_${var.environment}"
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  # Environment-specific settings
  backup_retention_period = local.env_config.retention_days
  backup_window          = var.environment == "prod" ? "03:00-04:00" : "07:00-08:00"
  maintenance_window     = var.environment == "prod" ? "sun:04:00-sun:05:00" : "sun:08:00-sun:09:00"

  multi_az               = local.env_config.multi_az
  publicly_accessible    = false
  storage_encrypted      = var.environment == "prod" ? true : false

  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${local.name_prefix}-final-snapshot" : null

  # Environment-specific monitoring and logging
  monitoring_interval = local.env_config.enable_monitoring ? 60 : 0
  monitoring_role_arn = local.env_config.enable_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null

  enabled_cloudwatch_logs_exports = local.env_config.enable_monitoring ? ["error", "general", "slow-query"] : []

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-database"
    Type = "database"
  })
}

# RDS Enhanced Monitoring IAM Role (for staging and prod)
resource "aws_iam_role" "rds_enhanced_monitoring" {
  count = local.env_config.enable_monitoring ? 1 : 0

  name = "${local.name_prefix}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = local.environment_tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count = local.env_config.enable_monitoring ? 1 : 0

  role       = aws_iam_role.rds_enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# SSL Certificate for HTTPS
resource "aws_acm_certificate" "web" {
  domain_name       = "${var.environment}.${var.domain_name}"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${var.environment}.${var.domain_name}"
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-certificate"
    Type = "ssl-certificate"
  })
}

resource "aws_acm_certificate_validation" "web" {
  certificate_arn = aws_acm_certificate.web.arn
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/application/${local.name_prefix}"
  retention_in_days = local.env_config.retention_days

  tags = merge(local.environment_tags, {
    Name = "${local.name_prefix}-app-logs"
    Type = "logging"
  })
}