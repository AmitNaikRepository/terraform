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
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  
  common_tags = merge(var.default_tags, {
    Module    = "lifecycle-management"
    Purpose   = "cost-optimization-automation"
    CostSaver = "true"
  })
}

# S3 Bucket for lifecycle demonstration
resource "aws_s3_bucket" "lifecycle_demo" {
  bucket = "${var.project_name}-${var.environment}-lifecycle-demo-${random_string.bucket_suffix.result}"

  tags = merge(local.common_tags, {
    Name               = "${var.project_name}-${var.environment}-lifecycle-bucket"
    LifecycleManaged   = "true"
    CostOptimization   = "automated"
    StorageOptimized   = "true"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Enable versioning for lifecycle demonstration
resource "aws_s3_bucket_versioning" "lifecycle_demo" {
  bucket = aws_s3_bucket.lifecycle_demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Comprehensive S3 lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "comprehensive" {
  bucket = aws_s3_bucket.lifecycle_demo.id

  # Rule for current objects - aggressive cost optimization
  rule {
    id     = "current_objects_cost_optimization"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier Flexible Retrieval after 60 days
    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    # Transition to Glacier Deep Archive after 180 days
    transition {
      days          = 180
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete objects after specified retention period
    dynamic "expiration" {
      for_each = var.enable_object_expiration ? [1] : []
      content {
        days = var.object_expiration_days
      }
    }
  }

  # Rule for log files - faster archiving
  rule {
    id     = "log_files_archiving"
    status = "Enabled"

    filter {
      prefix = "logs/"
    }

    # Logs transition to IA quickly
    transition {
      days          = 7
      storage_class = "STANDARD_IA"
    }

    # Logs to Glacier after 30 days
    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    # Logs to Deep Archive after 90 days
    transition {
      days          = 90
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete log files after 1 year
    expiration {
      days = 365
    }
  }

  # Rule for temporary files - quick deletion
  rule {
    id     = "temp_files_cleanup"
    status = "Enabled"

    filter {
      prefix = "temp/"
    }

    # Delete temporary files after 7 days
    expiration {
      days = 7
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  # Rule for non-current versions - version lifecycle management
  rule {
    id     = "version_management"
    status = "Enabled"

    # Non-current versions transition to IA after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Non-current versions to Glacier after 60 days
    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    # Delete non-current versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # Rule for backup files - long-term archiving
  rule {
    id     = "backup_archiving"
    status = "Enabled"

    filter {
      prefix = "backups/"
    }

    # Backups go straight to IA
    transition {
      days          = 1
      storage_class = "STANDARD_IA"
    }

    # Backups to Glacier after 7 days
    transition {
      days          = 7
      storage_class = "GLACIER"
    }

    # Keep backups for specified retention period
    dynamic "expiration" {
      for_each = var.backup_retention_enabled ? [1] : []
      content {
        days = var.backup_retention_days
      }
    }
  }

  # Clean up incomplete multipart uploads globally
  rule {
    id     = "cleanup_incomplete_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.lifecycle_demo]
}

# EC2 Auto Scaling with lifecycle management
resource "aws_launch_template" "cost_optimized" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  # Cost optimization settings
  monitoring {
    enabled = false  # Disable detailed monitoring to save costs
  }

  # Use spot instances for additional cost savings
  instance_market_options {
    market_type = var.use_spot_instances ? "spot" : null
    dynamic "spot_options" {
      for_each = var.use_spot_instances ? [1] : []
      content {
        spot_instance_type             = "one-time"
        instance_interruption_behavior = "terminate"
        max_price                     = var.spot_max_price
      }
    }
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    bucket_name  = aws_s3_bucket.lifecycle_demo.bucket
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name             = "${var.project_name}-${var.environment}-lifecycle-instance"
      LifecycleManaged = "true"
      AutoShutdown     = "enabled"
      CostOptimized    = "true"
      SpotInstance     = var.use_spot_instances ? "true" : "false"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Data source for latest Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Auto Scaling Group with scheduled scaling
resource "aws_autoscaling_group" "lifecycle_demo" {
  name                = "${var.project_name}-${var.environment}-lifecycle-asg"
  vpc_zone_identifier = [aws_subnet.demo.id]
  target_group_arns   = [aws_lb_target_group.demo.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.cost_optimized.id
    version = "$Latest"
  }

  # Instance refresh for automatic updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-lifecycle-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes       = [desired_capacity]
  }
}

# Scheduled scaling for cost optimization
resource "aws_autoscaling_schedule" "scale_down_evening" {
  count = var.enable_scheduled_scaling ? 1 : 0

  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-down-evening"
  min_size               = 0
  max_size               = var.asg_max_size
  desired_capacity       = 0
  recurrence             = var.scale_down_schedule
  auto_scaling_group_name = aws_autoscaling_group.lifecycle_demo.name
}

resource "aws_autoscaling_schedule" "scale_up_morning" {
  count = var.enable_scheduled_scaling ? 1 : 0

  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-up-morning"
  min_size               = var.asg_min_size
  max_size               = var.asg_max_size
  desired_capacity       = var.asg_desired_capacity
  recurrence             = var.scale_up_schedule
  auto_scaling_group_name = aws_autoscaling_group.lifecycle_demo.name
}

# VPC and networking for the demo
resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

resource "aws_subnet" "demo" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-subnet"
  })
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_route_table" "demo" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rt"
  })
}

resource "aws_route_table_association" "demo" {
  subnet_id      = aws_subnet.demo.id
  route_table_id = aws_route_table.demo.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Load balancer for the demo
resource "aws_lb" "demo" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.demo.id, aws_subnet.demo2.id]

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

# Second subnet for ALB (requires multiple AZs)
resource "aws_subnet" "demo2" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-subnet-2"
  })
}

resource "aws_route_table_association" "demo2" {
  subnet_id      = aws_subnet.demo2.id
  route_table_id = aws_route_table.demo.id
}

resource "aws_lb_target_group" "demo" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-tg"
  })
}

resource "aws_lb_listener" "demo" {
  load_balancer_arn = aws_lb.demo.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.demo.arn
  }
}

# Security groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda function for automated cost optimization
resource "aws_lambda_function" "cost_optimizer" {
  filename         = data.archive_file.cost_optimizer.output_path
  function_name    = "${var.project_name}-${var.environment}-cost-optimizer"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.cost_optimizer.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      BUCKET_NAME  = aws_s3_bucket.lifecycle_demo.bucket
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-cost-optimizer"
  })
}

# Lambda function code
data "archive_file" "cost_optimizer" {
  type        = "zip"
  output_path = "${path.module}/cost_optimizer.zip"
  source {
    content = templatefile("${path.module}/cost_optimizer.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-cost-optimizer"

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

  tags = local.common_tags
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-${var.environment}-lambda-cost-optimizer-policy"
  role = aws_iam_role.lambda_role.id

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
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:UpdateAutoScalingGroup",
          "s3:ListBucket",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule for scheduled cost optimization
resource "aws_cloudwatch_event_rule" "cost_optimization_schedule" {
  count = var.enable_automated_optimization ? 1 : 0

  name                = "${var.project_name}-${var.environment}-cost-optimization"
  description         = "Trigger cost optimization Lambda function"
  schedule_expression = "cron(0 22 * * ? *)"  # Run at 10 PM daily

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.enable_automated_optimization ? 1 : 0

  rule      = aws_cloudwatch_event_rule.cost_optimization_schedule[0].name
  target_id = "CostOptimizerLambdaTarget"
  arn       = aws_lambda_function.cost_optimizer.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  count = var.enable_automated_optimization ? 1 : 0

  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimizer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_optimization_schedule[0].arn
}