terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for workspace strategy
  backend "s3" {
    # These values should be configured during terraform init
    # terraform init -backend-config="bucket=your-terraform-state-bucket"
    # terraform init -backend-config="key=workspace-strategy/terraform.tfstate"
    # terraform init -backend-config="region=us-west-2"
    # terraform init -backend-config="dynamodb_table=terraform-state-lock"
    
    # Workspace-aware state path using terraform.workspace
    # This will create separate state files for each workspace
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  # Workspace-specific default tags
  default_tags {
    tags = local.workspace_tags
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  # Current workspace (will be 'default', 'dev', 'staging', 'prod', etc.)
  workspace = terraform.workspace

  # Workspace-to-environment mapping
  workspace_environment_map = {
    default = "dev"
    dev     = "dev"
    staging = "staging"
    prod    = "prod"
    test    = "test"
  }

  # Determine environment from workspace
  environment = lookup(local.workspace_environment_map, local.workspace, "dev")

  # Workspace-specific configurations
  workspace_config = {
    dev = {
      instance_type       = "t3.micro"
      min_size           = 1
      max_size           = 2
      desired_capacity   = 1
      volume_size        = 20
      enable_monitoring  = false
      multi_az          = false
      database_size     = "db.t3.micro"
      backup_retention  = 7
      log_retention     = 7
    }
    staging = {
      instance_type       = "t3.small"
      min_size           = 2
      max_size           = 4
      desired_capacity   = 2
      volume_size        = 30
      enable_monitoring  = true
      multi_az          = true
      database_size     = "db.t3.small"
      backup_retention  = 30
      log_retention     = 30
    }
    prod = {
      instance_type       = "t3.medium"
      min_size           = 3
      max_size           = 10
      desired_capacity   = 3
      volume_size        = 50
      enable_monitoring  = true
      multi_az          = true
      database_size     = "db.t3.medium"
      backup_retention  = 90
      log_retention     = 90
    }
    test = {
      instance_type       = "t3.micro"
      min_size           = 1
      max_size           = 1
      desired_capacity   = 1
      volume_size        = 10
      enable_monitoring  = false
      multi_az          = false
      database_size     = "db.t3.micro"
      backup_retention  = 1
      log_retention     = 1
    }
  }

  # Current workspace configuration
  current_config = local.workspace_config[local.environment]

  # Workspace-aware naming
  # This ensures resources are uniquely named per workspace
  name_prefix = "${var.project_name}-${local.workspace}"

  # Workspace-specific tags
  workspace_tags = merge(var.default_tags, {
    Workspace     = local.workspace
    Environment   = local.environment
    Project       = var.project_name
    Terraform     = "true"
    WorkspaceType = local.workspace == "default" ? "development" : local.workspace
    ManagedBy     = "terraform-workspace-${local.workspace}"
  })

  # Workspace-aware CIDR blocks to prevent conflicts
  workspace_cidrs = {
    default = "10.0.0.0/16"   # Default workspace
    dev     = "10.1.0.0/16"   # Development workspace
    staging = "10.2.0.0/16"   # Staging workspace
    prod    = "10.3.0.0/16"   # Production workspace
    test    = "10.4.0.0/16"   # Test workspace
  }

  vpc_cidr = local.workspace_cidrs[local.workspace]

  # Workspace-specific subnet calculations
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

# VPC with workspace-specific configuration
resource "aws_vpc" "workspace_demo" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-vpc"
    CIDR = local.vpc_cidr
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.workspace_demo.id

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# Subnets with workspace-aware configuration
resource "aws_subnet" "public" {
  count = local.current_config.multi_az ? 2 : 1

  vpc_id                  = aws_vpc.workspace_demo.id
  cidr_block              = local.subnet_cidrs.public[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

resource "aws_subnet" "private" {
  count = local.current_config.multi_az ? 2 : 1

  vpc_id            = aws_vpc.workspace_demo.id
  cidr_block        = local.subnet_cidrs.private[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# NAT Gateway (workspace-conditional)
resource "aws_eip" "nat" {
  count = local.workspace == "prod" || local.workspace == "staging" ? (local.current_config.multi_az ? 2 : 1) : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-nat-eip-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "main" {
  count = local.workspace == "prod" || local.workspace == "staging" ? (local.current_config.multi_az ? 2 : 1) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-nat-gateway-${count.index + 1}"
  })
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.workspace_demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.workspace_demo.id

  dynamic "route" {
    for_each = length(aws_nat_gateway.main) > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index % length(aws_nat_gateway.main)].id
    }
  }

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-private-rt-${count.index + 1}"
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

# Security Group with workspace-specific rules
resource "aws_security_group" "web" {
  name_prefix = "${local.name_prefix}-web-"
  description = "Web security group for workspace ${local.workspace}"
  vpc_id      = aws_vpc.workspace_demo.id

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

  # SSH access for non-production workspaces
  dynamic "ingress" {
    for_each = local.workspace != "prod" ? [1] : []
    content {
      description = "SSH for ${local.workspace} workspace"
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

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-web-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# S3 Bucket with workspace-aware naming
resource "aws_s3_bucket" "workspace_demo" {
  bucket = "${local.name_prefix}-demo-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.workspace_tags, {
    Name         = "${local.name_prefix}-demo-bucket"
    WorkspaceKey = "workspace-strategy/${local.workspace}"
  })
}

resource "aws_s3_bucket_versioning" "workspace_demo" {
  bucket = aws_s3_bucket.workspace_demo.id
  versioning_configuration {
    status = local.workspace == "prod" ? "Enabled" : "Suspended"
  }
}

# Launch Template with workspace configuration
resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-web-"
  image_id      = var.ami_id
  instance_type = local.current_config.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  monitoring {
    enabled = local.current_config.enable_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = local.current_config.volume_size
      volume_type           = "gp3"
      encrypted             = local.workspace == "prod"
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    workspace           = local.workspace
    environment         = local.environment
    project_name        = var.project_name
    instance_type       = local.current_config.instance_type
    monitoring_enabled  = local.current_config.enable_monitoring
    vpc_cidr           = local.vpc_cidr
    bucket_name        = aws_s3_bucket.workspace_demo.bucket
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.workspace_tags, {
      Name = "${local.name_prefix}-web-instance"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group with workspace-specific scaling
resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-web-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = local.current_config.min_size
  max_size         = local.current_config.max_size
  desired_capacity = local.current_config.desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Workspace-specific instance protection
  protect_from_scale_in = local.workspace == "prod"

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-web-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.workspace_tags
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

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = local.workspace == "prod"

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${local.name_prefix}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.workspace_demo.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-web-tg"
  })
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# CloudWatch Log Group with workspace-specific retention
resource "aws_cloudwatch_log_group" "workspace_demo" {
  name              = "/aws/workspace/${local.name_prefix}"
  retention_in_days = local.current_config.log_retention

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-log-group"
  })
}

# Workspace-specific SSM Parameters for configuration management
resource "aws_ssm_parameter" "workspace_config" {
  name  = "/${var.project_name}/${local.workspace}/config"
  type  = "String"
  value = jsonencode({
    workspace         = local.workspace
    environment       = local.environment
    vpc_cidr         = local.vpc_cidr
    instance_type    = local.current_config.instance_type
    monitoring       = local.current_config.enable_monitoring
    multi_az         = local.current_config.multi_az
    bucket_name      = aws_s3_bucket.workspace_demo.bucket
    log_group        = aws_cloudwatch_log_group.workspace_demo.name
  })

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-config"
    Type = "workspace-configuration"
  })
}

# Workspace management Lambda function
resource "aws_lambda_function" "workspace_manager" {
  filename         = data.archive_file.workspace_manager.output_path
  function_name    = "${local.name_prefix}-workspace-manager"
  role            = aws_iam_role.workspace_manager.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.workspace_manager.output_base64sha256

  environment {
    variables = {
      WORKSPACE         = local.workspace
      ENVIRONMENT       = local.environment
      PROJECT_NAME      = var.project_name
      VPC_ID           = aws_vpc.workspace_demo.id
      BUCKET_NAME      = aws_s3_bucket.workspace_demo.bucket
      LOG_GROUP        = aws_cloudwatch_log_group.workspace_demo.name
    }
  }

  tags = merge(local.workspace_tags, {
    Name = "${local.name_prefix}-workspace-manager"
  })
}

# Lambda function code for workspace management
data "archive_file" "workspace_manager" {
  type        = "zip"
  output_path = "${path.module}/workspace_manager.zip"
  source {
    content = templatefile("${path.module}/workspace_manager.py", {
      workspace    = local.workspace
      environment  = local.environment
      project_name = var.project_name
    })
    filename = "index.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "workspace_manager" {
  name = "${local.name_prefix}-workspace-manager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.workspace_tags
}

resource "aws_iam_role_policy" "workspace_manager" {
  name = "${local.name_prefix}-workspace-manager-policy"
  role = aws_iam_role.workspace_manager.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeVpcs",
          "autoscaling:DescribeAutoScalingGroups",
          "s3:ListBucket",
          "s3:GetObject",
          "ssm:GetParameter",
          "ssm:PutParameter"
        ]
        Resource = "*"
      }
    ]
  })
}