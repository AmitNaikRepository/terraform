# Module 06: Scalability → System Design Patterns

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Design Auto-Scaling Architectures**: Implement horizontal and vertical scaling strategies using AWS Auto Scaling Groups and Application Load Balancers
- **Configure Load Balancing Patterns**: Deploy advanced load balancing strategies including sticky sessions, health checks, and traffic distribution algorithms
- **Implement Database Scaling**: Design and implement read replicas, connection pooling, and database clustering patterns for high availability
- **Deploy Caching Strategies**: Implement multi-tier caching with ElastiCache, CloudFront, and application-level caching patterns
- **Build Distributed System Patterns**: Apply microservices architecture principles using service mesh, API gateways, and distributed communication patterns
- **Optimize Performance at Scale**: Implement monitoring, alerting, and automated scaling policies that respond to real-world traffic patterns
- **Apply System Design Principles**: Connect infrastructure scaling patterns to software engineering concepts like loose coupling, fault tolerance, and eventual consistency
- **Design for Global Scale**: Implement multi-region architectures with content delivery networks and edge computing patterns

## 🎯 Overview

Scalability in infrastructure is fundamentally about designing systems that can handle increasing load gracefully, much like designing software applications that can process more users, data, or requests without degrading performance. This module explores how infrastructure scaling patterns mirror software architecture principles and how proper scaling design enables robust, high-performance applications.

Just as software engineers design applications with scalability in mind through patterns like microservices, caching, and asynchronous processing, infrastructure engineers must architect systems that can scale horizontally and vertically while maintaining performance, reliability, and cost-effectiveness. Understanding these patterns is essential for building modern, cloud-native applications that can serve millions of users globally.

## 📖 Core Concepts

### Scaling Strategies Overview

#### Horizontal vs Vertical Scaling
- **Horizontal Scaling (Scale Out)**: Adding more instances/nodes to handle increased load
- **Vertical Scaling (Scale Up)**: Increasing the capacity of existing instances/nodes
- **Elastic Scaling**: Combining both strategies with automated decision-making

#### Software Engineering Parallels

| Infrastructure Pattern | Software Engineering Pattern | Purpose |
|------------------------|------------------------------|---------|
| Auto Scaling Groups | Microservices Horizontal Scaling | Distribute load across multiple instances |
| Load Balancers | API Gateway/Reverse Proxy | Route requests to healthy backend services |
| Database Read Replicas | CQRS (Command Query Responsibility Segregation) | Separate read and write operations |
| Caching Layers | Application-Level Caching | Reduce expensive operations and improve response times |
| Service Mesh | Inter-Service Communication | Handle service discovery, load balancing, and fault tolerance |
| Circuit Breakers | Resilience Patterns | Prevent cascade failures and improve system stability |

### Scaling Dimensions

#### 1. Compute Scaling
- **Instance-level**: CPU, memory, network optimization
- **Service-level**: Container orchestration and pod scaling
- **Application-level**: Thread pools, connection pools, worker processes

#### 2. Storage Scaling
- **Capacity scaling**: Elastic file systems and block storage
- **Performance scaling**: IOPS optimization and storage tiering
- **Geographic scaling**: Multi-region data replication

#### 3. Network Scaling
- **Bandwidth scaling**: Content delivery networks and edge locations
- **Latency optimization**: Regional deployments and edge computing
- **Connection scaling**: Load balancer capacity and connection pooling

### Performance Metrics and Scaling Triggers

#### Key Performance Indicators (KPIs)
- **Response Time**: 95th and 99th percentile latencies
- **Throughput**: Requests per second and data transfer rates
- **Resource Utilization**: CPU, memory, network, and storage usage
- **Error Rates**: Application errors, timeouts, and failed requests
- **Availability**: Uptime percentage and service level objectives (SLOs)

#### Scaling Decision Matrix

| Metric | Scale Out Trigger | Scale Up Trigger | Scale In Trigger |
|--------|------------------|------------------|------------------|
| CPU Utilization | > 70% for 5 minutes | > 90% for 2 minutes | < 30% for 15 minutes |
| Memory Usage | > 80% for 5 minutes | > 95% for 2 minutes | < 40% for 15 minutes |
| Request Latency | > 500ms P95 | > 1000ms P95 | < 100ms P95 for 10 minutes |
| Queue Depth | > 100 messages | > 500 messages | < 10 messages for 10 minutes |

## 🛠️ Terraform Implementation

### 1. Advanced Auto Scaling with Application Load Balancer

This implementation demonstrates a production-ready auto-scaling architecture with sophisticated health checks and scaling policies:

```hcl
# examples/01-advanced-autoscaling/main.tf

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
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Scalability"
    }
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

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Public subnets across multiple AZs for high availability
resource "aws_subnet" "public" {
  count = min(length(data.aws_availability_zones.available.names), 3)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "public"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Private subnets for database and internal services
resource "aws_subnet" "private" {
  count = min(length(data.aws_availability_zones.available.names), 3)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 101)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "private"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateways for private subnet internet access
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)
  
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)
  
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-gateway-${count.index + 1}"
  }
}

# Route tables for private subnets
resource "aws_route_table" "private" {
  count = length(aws_subnet.private)
  
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)
  
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description     = "Health Check"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection       = var.environment == "prod" ? true : false
  enable_cross_zone_load_balancing = true
  enable_http2                     = true
  idle_timeout                     = 60

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# S3 bucket for ALB access logs
resource "aws_s3_bucket" "alb_logs" {
  bucket        = "${var.project_name}-${var.environment}-alb-logs-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name    = "ALB Access Logs"
    Purpose = "Load Balancer Logging"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# Target Groups with advanced health checks
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    path                = "/health"
    matcher             = "200,204"
    port                = "8080"
    protocol            = "HTTP"
  }

  # Advanced target group attributes
  deregistration_delay          = 30
  slow_start                   = 30
  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = var.enable_session_stickiness
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-tg"
  }
}

# ALB Listener with advanced routing
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action with response headers
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-log-group"
    Environment = var.environment
  }
}

# IAM role for EC2 instances
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# Launch Template with advanced configuration
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.web.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment       = var.environment
    project          = var.project_name
    cloudwatch_group = aws_cloudwatch_log_group.app.name
    aws_region       = var.aws_region
  }))

  # Enable detailed monitoring
  monitoring {
    enabled = true
  }

  # Instance metadata service configuration
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    hop_limit     = 1
  }

  # EBS optimization
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type          = "gp3"
      iops                 = 3000
      throughput           = 125
      encrypted            = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-web-instance"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.project_name}-${var.environment}-web-volume"
    }
  }
}

# Auto Scaling Group with advanced scaling policies
resource "aws_autoscaling_group" "web" {
  name               = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns  = [aws_lb_target_group.web.arn]
  health_check_type  = "ELB"
  health_check_grace_period = 300

  min_size                  = var.scaling_config.min_size
  max_size                  = var.scaling_config.max_size
  desired_capacity          = var.scaling_config.desired_size
  default_cooldown          = 300
  wait_for_capacity_timeout = "10m"

  # Advanced ASG configuration
  capacity_rebalance        = true
  max_instance_lifetime     = 604800  # 7 days
  termination_policies      = ["OldestLaunchTemplate", "Default"]
  
  # Launch template configuration
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Instance refresh configuration
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup       = 300
      checkpoint_delay      = 600
      checkpoint_percentages = [20, 50, 100]
    }
    triggers = ["tag"]
  }

  # Auto Scaling Group tags
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  # Lifecycle hook for graceful shutdown
  initial_lifecycle_hook {
    name                 = "web-instance-terminating"
    default_result       = "ABANDON"
    heartbeat_timeout    = 300
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }
}

# CloudWatch Alarms and Scaling Policies
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  scaling_adjustment     = 2
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type           = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 600
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type           = "SimpleScaling"
}

# Target tracking scaling policy for CPU utilization
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name               = "${var.project_name}-${var.environment}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
    scale_out_cooldown = 300
    scale_in_cooldown  = 600
  }
}

# Target tracking scaling policy for ALB request count
resource "aws_autoscaling_policy" "request_count_target_tracking" {
  name               = "${var.project_name}-${var.environment}-request-count-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.main.arn_suffix}/${aws_lb_target_group.web.arn_suffix}"
    }
    target_value = var.request_count_target_value
    scale_out_cooldown = 300
    scale_in_cooldown  = 600
  }
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-high-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "20"
  alarm_description   = "This metric monitors ec2 cpu utilization for scale down"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-low-cpu-alarm"
  }
}
```

```hcl
# examples/01-advanced-autoscaling/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region name."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "scalable-web-app"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
  
  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t3.xlarge", "t3.2xlarge", "m5.large", "m5.xlarge",
      "m5.2xlarge", "m5.4xlarge", "c5.large", "c5.xlarge"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "scaling_config" {
  description = "Auto scaling configuration"
  type = object({
    min_size     = number
    max_size     = number
    desired_size = number
  })
  default = {
    min_size     = 1
    max_size     = 10
    desired_size = 2
  }
  
  validation {
    condition = (
      var.scaling_config.min_size >= 1 &&
      var.scaling_config.max_size >= var.scaling_config.min_size &&
      var.scaling_config.desired_size >= var.scaling_config.min_size &&
      var.scaling_config.desired_size <= var.scaling_config.max_size
    )
    error_message = "Scaling configuration must have valid min/max/desired values."
  }
}

variable "cpu_target_value" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 70
  
  validation {
    condition     = var.cpu_target_value > 0 && var.cpu_target_value <= 100
    error_message = "CPU target value must be between 1 and 100."
  }
}

variable "request_count_target_value" {
  description = "Target request count per target for auto scaling"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.request_count_target_value > 0
    error_message = "Request count target value must be greater than 0."
  }
}

variable "enable_session_stickiness" {
  description = "Enable session stickiness on load balancer"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}
```

```bash
# examples/01-advanced-autoscaling/user_data.sh

#!/bin/bash
# Advanced user data script with monitoring and performance optimization

# Update system and install packages
yum update -y
yum install -y httpd htop iotop amazon-cloudwatch-agent
yum install -y amazon-ssm-agent

# Configure CloudWatch Agent
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "${cloudwatch_group}",
                        "log_stream_name": "{instance_id}/httpd/access_log"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "${cloudwatch_group}",
                        "log_stream_name": "{instance_id}/httpd/error_log"
                    },
                    {
                        "file_path": "/var/log/app.log",
                        "log_group_name": "${cloudwatch_group}",
                        "log_stream_name": "{instance_id}/application/app.log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "Custom/${project}",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            },
            "swap": {
                "measurement": [
                    "swap_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    }
}
EOF

# Start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Configure Apache with performance optimizations
cat <<EOF > /etc/httpd/conf.d/performance.conf
# Performance optimizations
ServerTokens Prod
ServerSignature Off

# Worker configuration for better performance
<IfModule mpm_prefork_module>
    StartServers          8
    MinSpareServers       5
    MaxSpareServers       20
    MaxRequestWorkers     256
    MaxConnectionsPerChild 1000
</IfModule>

# Compression
LoadModule deflate_module modules/mod_deflate.so
<Location />
    SetOutputFilter DEFLATE
    SetEnvIfNoCase Request_URI \
        \.(?:gif|jpe?g|png)$ no-gzip dont-vary
    SetEnvIfNoCase Request_URI \
        \.(?:exe|t?gz|zip|bz2|sit|rar)$ no-gzip dont-vary
</Location>

# Caching headers
LoadModule expires_module modules/mod_expires.so
ExpiresActive On
ExpiresByType image/jpg "access plus 1 month"
ExpiresByType image/jpeg "access plus 1 month"
ExpiresByType image/gif "access plus 1 month"
ExpiresByType image/png "access plus 1 month"
ExpiresByType text/css "access plus 1 month"
ExpiresByType application/pdf "access plus 1 month"
ExpiresByType text/javascript "access plus 1 month"
ExpiresByType application/javascript "access plus 1 month"
EOF

# Create application structure
mkdir -p /var/www/html/{app,health,api}

# Health check endpoint
cat <<EOF > /var/www/html/health/index.php
<?php
header('Content-Type: application/json');
http_response_code(200);

// Health check with system metrics
\$health = [
    'status' => 'healthy',
    'timestamp' => date('c'),
    'environment' => '${environment}',
    'instance_id' => file_get_contents('http://169.254.169.254/latest/meta-data/instance-id'),
    'availability_zone' => file_get_contents('http://169.254.169.254/latest/meta-data/placement/availability-zone'),
    'uptime' => sys_getloadavg()[0],
    'memory_usage' => round(memory_get_usage(true) / 1024 / 1024, 2) . 'MB'
];

echo json_encode(\$health, JSON_PRETTY_PRINT);
?>
EOF

# Main application with performance metrics
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${project} - ${environment}</title>
    <style>
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            margin: 0; 
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            border-radius: 15px;
            padding: 30px;
            backdrop-filter: blur(10px);
        }
        .header { text-align: center; margin-bottom: 30px; }
        .header h1 { font-size: 2.5em; margin: 0; }
        .header h2 { font-size: 1.5em; margin: 10px 0 0 0; opacity: 0.9; }
        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .metric-card {
            background: rgba(255,255,255,0.1);
            border-radius: 10px;
            padding: 20px;
            border: 1px solid rgba(255,255,255,0.2);
        }
        .metric-title { font-size: 1.2em; font-weight: bold; margin-bottom: 10px; }
        .metric-value { font-size: 2em; color: #ffd700; }
        .load-test { margin-top: 30px; text-align: center; }
        .load-button {
            background: #ff6b6b;
            color: white;
            border: none;
            padding: 15px 30px;
            font-size: 1.1em;
            border-radius: 25px;
            cursor: pointer;
            margin: 0 10px;
            transition: background 0.3s;
        }
        .load-button:hover { background: #ff5252; }
        .progress-bar {
            width: 100%;
            height: 20px;
            background: rgba(255,255,255,0.2);
            border-radius: 10px;
            overflow: hidden;
            margin: 10px 0;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #4CAF50, #8BC34A);
            width: 0%;
            transition: width 0.3s;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${project}</h1>
            <h2>Environment: ${environment}</h2>
            <p>Auto-Scaling Architecture Demo</p>
        </div>
        
        <div class="metrics-grid">
            <div class="metric-card">
                <div class="metric-title">Instance ID</div>
                <div class="metric-value" id="instance-id">Loading...</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Availability Zone</div>
                <div class="metric-value" id="az">Loading...</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Requests Processed</div>
                <div class="metric-value" id="request-count">0</div>
            </div>
            <div class="metric-card">
                <div class="metric-title">Current Load</div>
                <div class="metric-value" id="cpu-load">0%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpu-progress"></div>
                </div>
            </div>
        </div>
        
        <div class="load-test">
            <h3>Load Testing Controls</h3>
            <button class="load-button" onclick="generateLoad('light')">Light Load</button>
            <button class="load-button" onclick="generateLoad('medium')">Medium Load</button>
            <button class="load-button" onclick="generateLoad('heavy')">Heavy Load</button>
        </div>
        
        <div id="status-messages" style="margin-top: 20px; text-align: center;"></div>
    </div>
    
    <script>
        let requestCount = 0;
        let currentLoad = 0;
        
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => {
                document.getElementById('instance-id').textContent = data;
            })
            .catch(() => {
                document.getElementById('instance-id').textContent = 'N/A';
            });
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => {
                document.getElementById('az').textContent = data;
            })
            .catch(() => {
                document.getElementById('az').textContent = 'N/A';
            });
        
        // Simulate load generation
        function generateLoad(intensity) {
            const loads = {
                light: { duration: 30000, interval: 1000, cpuLoad: 30 },
                medium: { duration: 60000, interval: 500, cpuLoad: 60 },
                heavy: { duration: 120000, interval: 100, cpuLoad: 90 }
            };
            
            const config = loads[intensity];
            const statusDiv = document.getElementById('status-messages');
            statusDiv.innerHTML = \`<div style="background: rgba(255,255,255,0.1); padding: 10px; border-radius: 5px;">
                Generating \${intensity} load for \${config.duration/1000} seconds...
            </div>\`;
            
            const startTime = Date.now();
            const loadInterval = setInterval(() => {
                requestCount++;
                currentLoad = Math.min(config.cpuLoad + Math.random() * 20, 100);
                
                document.getElementById('request-count').textContent = requestCount;
                document.getElementById('cpu-load').textContent = Math.round(currentLoad) + '%';
                document.getElementById('cpu-progress').style.width = currentLoad + '%';
                
                // Stop load generation after duration
                if (Date.now() - startTime > config.duration) {
                    clearInterval(loadInterval);
                    currentLoad = 10 + Math.random() * 10;
                    document.getElementById('cpu-load').textContent = Math.round(currentLoad) + '%';
                    document.getElementById('cpu-progress').style.width = currentLoad + '%';
                    statusDiv.innerHTML = '<div style="background: rgba(76, 175, 80, 0.3); padding: 10px; border-radius: 5px;">Load test completed</div>';
                }
            }, config.interval);
        }
        
        // Update metrics periodically
        setInterval(() => {
            if (currentLoad > 10) {
                currentLoad -= 0.5;
                document.getElementById('cpu-load').textContent = Math.round(currentLoad) + '%';
                document.getElementById('cpu-progress').style.width = currentLoad + '%';
            }
        }, 2000);
    </script>
</body>
</html>
EOF

# Configure health check listener on port 8080
echo "Listen 8080" >> /etc/httpd/conf/httpd.conf
cat <<EOF >> /etc/httpd/conf/httpd.conf

<VirtualHost *:8080>
    DocumentRoot /var/www/html/health
    ErrorLog logs/health_error.log
    CustomLog logs/health_access.log combined
</VirtualHost>
EOF

# Start and enable services
systemctl start httpd
systemctl enable httpd
systemctl start amazon-ssm-agent
systemctl enable amazon-ssm-agent

# Create application log file
touch /var/log/app.log
chmod 644 /var/log/app.log

# Log instance startup
echo "$(date): Instance started - Environment: ${environment}, Project: ${project}" >> /var/log/app.log
```

```hcl
# examples/01-advanced-autoscaling/outputs.tf

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.main.zone_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.web.id
}

output "security_group_alb_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "security_group_web_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web.id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.app.name
}

output "s3_alb_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

# Scaling policy outputs for monitoring
output "scaling_policies" {
  description = "Auto Scaling policy ARNs"
  value = {
    scale_up                    = aws_autoscaling_policy.scale_up.arn
    scale_down                 = aws_autoscaling_policy.scale_down.arn
    cpu_target_tracking        = aws_autoscaling_policy.cpu_target_tracking.arn
    request_count_target_tracking = aws_autoscaling_policy.request_count_target_tracking.arn
  }
}

# CloudWatch alarm outputs
output "cloudwatch_alarms" {
  description = "CloudWatch alarm ARNs"
  value = {
    high_cpu = aws_cloudwatch_metric_alarm.high_cpu.arn
    low_cpu  = aws_cloudwatch_metric_alarm.low_cpu.arn
  }
}

# Application URL for testing
output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "health_check_url" {
  description = "URL for health check endpoint"
  value       = "http://${aws_lb.main.dns_name}/health/"
}
```

### 2. Database Scaling with Read Replicas and Connection Pooling

```hcl
# examples/02-database-scaling/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Database-Scaling"
    }
  }
}

# Random password for RDS
resource "random_password" "master" {
  length  = 16
  special = true
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-${var.environment}-db-password"
  description = "Master password for RDS cluster"

  tags = {
    Name = "${var.project_name}-${var.environment}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.master.result
  })
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC and networking (simplified - would typically use VPC module)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# Database subnets across multiple AZs
resource "aws_subnet" "database" {
  count = min(length(data.aws_availability_zones.available.names), 3)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 201)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-${count.index + 1}"
    Type = "database"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Application subnets
resource "aws_subnet" "application" {
  count = min(length(data.aws_availability_zones.available.names), 3)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-app-subnet-${count.index + 1}"
    Type = "application"
    AZ   = data.aws_availability_zones.available.names[count.index]
  }
}

# Route table for application subnets
resource "aws_route_table" "application" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-rt"
  }
}

resource "aws_route_table_association" "application" {
  count = length(aws_subnet.application)
  
  subnet_id      = aws_subnet.application[count.index].id
  route_table_id = aws_route_table.application.id
}

# Database subnet group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# Security groups
resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL/Aurora"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg"
  }
}

resource "aws_security_group" "application" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
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

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-sg"
  }
}

# Parameter group for performance optimization
resource "aws_rds_cluster_parameter_group" "main" {
  family      = "aurora-mysql8.0"
  name        = "${var.project_name}-${var.environment}-cluster-params"
  description = "RDS cluster parameter group for ${var.project_name}"

  # Connection and query optimization parameters
  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "1000"
  }

  parameter {
    name  = "query_cache_type"
    value = "1"
  }

  parameter {
    name  = "query_cache_size"
    value = "134217728"  # 128MB
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "binlog_format"
    value = "ROW"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cluster-params"
  }
}

resource "aws_db_parameter_group" "main" {
  family = "aurora-mysql8.0"
  name   = "${var.project_name}-${var.environment}-db-params"

  # Performance optimization parameters
  parameter {
    name  = "innodb_file_per_table"
    value = "1"
  }

  parameter {
    name  = "innodb_flush_log_at_trx_commit"
    value = "2"
  }

  parameter {
    name  = "sync_binlog"
    value = "0"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-params"
  }
}

# Aurora MySQL cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-cluster"
  engine                 = "aurora-mysql"
  engine_version         = var.aurora_engine_version
  availability_zones     = data.aws_availability_zones.available.names
  
  database_name          = var.database_name
  master_username        = var.db_username
  master_password        = random_password.master.result
  
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  db_subnet_group_name           = aws_db_subnet_group.main.name
  vpc_security_group_ids         = [aws_security_group.database.id]
  
  storage_encrypted               = true
  kms_key_id                     = aws_kms_key.rds.arn
  
  # Performance and scaling settings
  copy_tags_to_snapshot          = true
  deletion_protection            = var.environment == "prod" ? true : false
  skip_final_snapshot           = var.environment != "prod" ? true : false
  final_snapshot_identifier     = var.environment == "prod" ? "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}" : null
  
  # Enhanced monitoring
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  
  tags = {
    Name = "${var.project_name}-${var.environment}-cluster"
  }

  lifecycle {
    ignore_changes = [
      master_password,
      final_snapshot_identifier
    ]
  }
}

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-kms"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# Primary (writer) instance
resource "aws_rds_cluster_instance" "writer" {
  identifier           = "${var.project_name}-${var.environment}-writer"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = var.writer_instance_class
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  
  db_parameter_group_name = aws_db_parameter_group.main.name
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  
  auto_minor_version_upgrade = false
  
  tags = {
    Name = "${var.project_name}-${var.environment}-writer"
    Role = "writer"
  }
}

# Read replica instances for scaling read operations
resource "aws_rds_cluster_instance" "reader" {
  count = var.reader_instance_count
  
  identifier           = "${var.project_name}-${var.environment}-reader-${count.index + 1}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = var.reader_instance_class
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  
  db_parameter_group_name = aws_db_parameter_group.main.name
  
  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_monitoring.arn
  
  auto_minor_version_upgrade = false
  
  tags = {
    Name = "${var.project_name}-${var.environment}-reader-${count.index + 1}"
    Role = "reader"
  }
}

# IAM role for RDS enhanced monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring"

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
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ElastiCache for Redis (application-level caching)
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-cache-subnet"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-cache-subnet"
  }
}

resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-${var.environment}-cache-"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cache-sg"
  }
}

resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7.x"
  name   = "${var.project_name}-${var.environment}-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-params"
  }
}

# Redis cluster for caching
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.project_name}-${var.environment}-redis"
  description                = "Redis cluster for ${var.project_name}"
  
  node_type                 = var.redis_node_type
  port                      = 6379
  parameter_group_name      = aws_elasticache_parameter_group.redis.name
  
  num_cache_clusters        = var.redis_num_cache_nodes
  automatic_failover_enabled = var.redis_num_cache_nodes > 1 ? true : false
  multi_az_enabled          = var.redis_num_cache_nodes > 1 ? true : false
  
  subnet_group_name = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.elasticache.id]
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  # Backup configuration
  snapshot_retention_limit = 3
  snapshot_window         = "03:00-05:00"
  
  # Maintenance window
  maintenance_window = "sun:05:00-sun:07:00"
  
  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }
}

# Application Auto Scaling for Aurora read replicas
resource "aws_appautoscaling_target" "read_replica" {
  max_capacity       = var.max_reader_instances
  min_capacity       = var.min_reader_instances
  resource_id        = "cluster:${aws_rds_cluster.main.cluster_identifier}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  service_namespace  = "rds"
}

resource "aws_appautoscaling_policy" "read_replica_cpu" {
  name               = "${var.project_name}-${var.environment}-read-replica-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_replica.resource_id
  scalable_dimension = aws_appautoscaling_target.read_replica.scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_replica.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value = var.read_replica_cpu_target
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
  }
}

resource "aws_appautoscaling_policy" "read_replica_connections" {
  name               = "${var.project_name}-${var.environment}-read-replica-connections"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read_replica.resource_id
  scalable_dimension = aws_appautoscaling_target.read_replica.scalable_dimension
  service_namespace  = aws_appautoscaling_target.read_replica.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageDatabaseConnections"
    }
    target_value = var.read_replica_connections_target
    scale_out_cooldown = 300
    scale_in_cooldown  = 300
  }
}

# CloudWatch Dashboard for database monitoring
resource "aws_cloudwatch_dashboard" "database" {
  dashboard_name = "${var.project_name}-${var.environment}-database"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", aws_rds_cluster.main.cluster_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "RDS Cluster Metrics"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ElastiCache", "CPUUtilization", "CacheClusterId", aws_elasticache_replication_group.main.replication_group_id],
            [".", "CacheHits", ".", "."],
            [".", "CacheMisses", ".", "."],
            [".", "NetworkBytesIn", ".", "."],
            [".", "NetworkBytesOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ElastiCache Metrics"
        }
      }
    ]
  })
}
```

```hcl
# examples/02-database-scaling/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "scalable-database"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  default     = "admin"
}

variable "aurora_engine_version" {
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.02.0"
}

variable "writer_instance_class" {
  description = "Instance class for the writer instance"
  type        = string
  default     = "db.r6g.large"
}

variable "reader_instance_class" {
  description = "Instance class for reader instances"
  type        = string
  default     = "db.r6g.large"
}

variable "reader_instance_count" {
  description = "Number of reader instances to create initially"
  type        = number
  default     = 1
  
  validation {
    condition     = var.reader_instance_count >= 0 && var.reader_instance_count <= 15
    error_message = "Reader instance count must be between 0 and 15."
  }
}

variable "min_reader_instances" {
  description = "Minimum number of reader instances for auto scaling"
  type        = number
  default     = 1
}

variable "max_reader_instances" {
  description = "Maximum number of reader instances for auto scaling"
  type        = number
  default     = 5
}

variable "read_replica_cpu_target" {
  description = "Target CPU utilization for read replica auto scaling"
  type        = number
  default     = 70
}

variable "read_replica_connections_target" {
  description = "Target connection count for read replica auto scaling"
  type        = number
  default     = 700
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
  
  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "redis_node_type" {
  description = "Node type for Redis cluster"
  type        = string
  default     = "cache.r6g.large"
}

variable "redis_num_cache_nodes" {
  description = "Number of cache nodes in Redis cluster"
  type        = number
  default     = 2
  
  validation {
    condition     = var.redis_num_cache_nodes >= 1 && var.redis_num_cache_nodes <= 6
    error_message = "Number of Redis cache nodes must be between 1 and 6."
  }
}
```

### 3. Multi-Tier Caching with CloudFront and ElastiCache

```hcl
# examples/03-multi-tier-caching/main.tf

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
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Multi-Tier-Caching"
    }
  }
}

# S3 bucket for static content
resource "aws_s3_bucket" "static_content" {
  bucket = "${var.project_name}-${var.environment}-static-content-${random_string.bucket_suffix.result}"

  tags = {
    Name    = "Static Content Bucket"
    Purpose = "CloudFront Origin"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "static_content" {
  bucket = aws_s3_bucket.static_content.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name} static content"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  origin {
    domain_name              = aws_s3_bucket.static_content.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
    origin_id                = "S3-${aws_s3_bucket.static_content.bucket}"
  }

  # API Gateway origin for dynamic content
  dynamic "origin" {
    for_each = var.api_gateway_domain != "" ? [1] : []
    content {
      domain_name = var.api_gateway_domain
      origin_id   = "API-Gateway"
      
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CloudFront distribution for ${var.project_name}"
  default_root_object = "index.html"

  # Caching behavior for static content
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_content.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true

    # Response headers policy
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  # Caching behavior for API endpoints (dynamic content)
  dynamic "ordered_cache_behavior" {
    for_each = var.api_gateway_domain != "" ? [1] : []
    content {
      path_pattern     = "/api/*"
      allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods   = ["GET", "HEAD", "OPTIONS"]
      target_origin_id = "API-Gateway"

      forwarded_values {
        query_string = true
        headers      = ["Authorization", "CloudFront-Forwarded-Proto"]
        cookies {
          forward = "all"
        }
      }

      viewer_protocol_policy = "redirect-to-https"
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 300
      compress               = true

      # Cache key and origin requests policy
      cache_policy_id          = aws_cloudfront_cache_policy.api_caching.id
      origin_request_policy_id = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    }
  }

  # Caching behavior for images and assets
  ordered_cache_behavior {
    path_pattern     = "/assets/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_content.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000  # 1 year
    default_ttl            = 31536000  # 1 year
    max_ttl                = 31536000  # 1 year
    compress               = true
  }

  # Geographic restrictions
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # SSL/TLS certificate
  viewer_certificate {
    cloudfront_default_certificate = var.custom_domain == "" ? true : false
    acm_certificate_arn            = var.custom_domain != "" ? var.ssl_certificate_arn : null
    ssl_support_method             = var.custom_domain != "" ? "sni-only" : null
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  # Custom domain configuration
  dynamic "aliases" {
    for_each = var.custom_domain != "" ? [var.custom_domain] : []
    content {
      aliases = [aliases.value]
    }
  }

  # Logging configuration
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  # Price class
  price_class = var.cloudfront_price_class

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront"
  }
}

# S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${var.project_name}-${var.environment}-cloudfront-logs-${random_string.logs_suffix.result}"

  tags = {
    Name    = "CloudFront Logs"
    Purpose = "Access Logging"
  }
}

resource "random_string" "logs_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Response headers policy for security
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name    = "${var.project_name}-${var.environment}-security-headers"
  comment = "Security headers for ${var.project_name}"

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
    }
    content_type_options {
      override = true
    }
    frame_options {
      frame_option = "DENY"
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
    }
  }

  custom_headers_config {
    items {
      header   = "X-Custom-Header"
      value    = "${var.project_name}-${var.environment}"
      override = false
    }
  }
}

# Cache policy for API endpoints
resource "aws_cloudfront_cache_policy" "api_caching" {
  name        = "${var.project_name}-${var.environment}-api-cache-policy"
  comment     = "Cache policy for API endpoints"
  default_ttl = 0
  max_ttl     = 300
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    query_strings_config {
      query_string_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Authorization", "CloudFront-Forwarded-Proto"]
      }
    }

    cookies_config {
      cookie_behavior = "all"
    }
  }
}

# Data source for origin request policy
data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "CORS-S3Origin"
}

# S3 bucket policy for CloudFront OAC
resource "aws_s3_bucket_policy" "static_content" {
  bucket = aws_s3_bucket.static_content.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_content.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# Sample static content
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.static_content.bucket
  key          = "index.html"
  content_type = "text/html"
  
  content = templatefile("${path.module}/static/index.html", {
    project_name = var.project_name
    environment  = var.environment
  })

  etag = md5(templatefile("${path.module}/static/index.html", {
    project_name = var.project_name
    environment  = var.environment
  }))
}

resource "aws_s3_object" "css" {
  bucket       = aws_s3_bucket.static_content.bucket
  key          = "assets/style.css"
  content_type = "text/css"
  
  content = file("${path.module}/static/assets/style.css")
  etag    = filemd5("${path.module}/static/assets/style.css")
  
  cache_control = "public, max-age=31536000"
}

resource "aws_s3_object" "js" {
  bucket       = aws_s3_bucket.static_content.bucket
  key          = "assets/app.js"
  content_type = "application/javascript"
  
  content = file("${path.module}/static/assets/app.js")
  etag    = filemd5("${path.module}/static/assets/app.js")
  
  cache_control = "public, max-age=31536000"
}

# CloudWatch alarms for CloudFront monitoring
resource "aws_cloudwatch_metric_alarm" "cloudfront_4xx_error_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors CloudFront 4xx error rate"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-4xx-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudfront_cache_hit_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-cloudfront-cache-hit-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CloudFront cache hit rate"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudfront-cache-hit-alarm"
  }
}
```

## 🔗 Software Engineering Connections

### Microservices and Distributed Systems Patterns

#### Service Mesh Architecture
Infrastructure scaling parallels microservices architecture principles:

```hcl
# Service discovery and load balancing pattern
resource "aws_service_discovery_service" "app" {
  name = "web-service"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
    
    routing_policy = "MULTIVALUE"
  }

  health_check_grace_period_seconds = 30
}
```

#### Circuit Breaker Pattern Implementation
```python
# Application-level circuit breaker (matches infrastructure redundancy)
class DatabaseCircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = 'CLOSED'  # CLOSED, OPEN, HALF_OPEN
    
    def call_database(self, operation):
        if self.state == 'OPEN':
            if time.time() - self.last_failure_time > self.recovery_timeout:
                self.state = 'HALF_OPEN'
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = operation()
            if self.state == 'HALF_OPEN':
                self.state = 'CLOSED'
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            
            if self.failure_count >= self.failure_threshold:
                self.state = 'OPEN'
            
            raise e
```

#### CQRS Pattern with Read Replicas
```python
# Command Query Responsibility Segregation
class DatabaseManager:
    def __init__(self, writer_endpoint, reader_endpoints):
        self.writer = create_connection(writer_endpoint)
        self.readers = [create_connection(endpoint) for endpoint in reader_endpoints]
        self.reader_index = 0
    
    def execute_command(self, sql, params=None):
        """Write operations go to the primary instance"""
        return self.writer.execute(sql, params)
    
    def execute_query(self, sql, params=None):
        """Read operations are distributed across read replicas"""
        reader = self.readers[self.reader_index % len(self.readers)]
        self.reader_index += 1
        return reader.execute(sql, params)
    
    def execute_read_heavy_query(self, sql, params=None):
        """Heavy analytical queries can target specific read replicas"""
        # Use least loaded reader or dedicated analytics replica
        return self.get_least_loaded_reader().execute(sql, params)
```

### Caching Strategies and Patterns

#### Multi-Level Caching Architecture

| Layer | Technology | TTL | Use Case | Software Pattern |
|-------|-----------|-----|----------|-----------------|
| CDN | CloudFront | 1 year | Static assets | Browser caching |
| Application | ElastiCache | 1 hour | Session data, API responses | In-memory caching |
| Database | Query cache | 15 minutes | Frequent queries | Query result caching |
| Object | Application memory | 5 minutes | Configuration, metadata | Object caching |

#### Cache-Aside Pattern Implementation
```python
class CacheManager:
    def __init__(self, redis_client, database):
        self.cache = redis_client
        self.db = database
    
    def get_user(self, user_id):
        cache_key = f"user:{user_id}"
        
        # Try cache first
        cached_user = self.cache.get(cache_key)
        if cached_user:
            return json.loads(cached_user)
        
        # Cache miss - fetch from database
        user = self.db.get_user(user_id)
        if user:
            # Store in cache with TTL
            self.cache.setex(
                cache_key, 
                3600,  # 1 hour TTL
                json.dumps(user)
            )
        
        return user
    
    def update_user(self, user_id, user_data):
        # Update database first
        self.db.update_user(user_id, user_data)
        
        # Invalidate cache
        cache_key = f"user:{user_id}"
        self.cache.delete(cache_key)
```

### Performance Monitoring and Observability

#### Application Performance Monitoring (APM) Integration
```python
# Custom metrics that align with infrastructure scaling decisions
import time
import boto3

class ApplicationMetrics:
    def __init__(self):
        self.cloudwatch = boto3.client('cloudwatch')
    
    def record_request_duration(self, duration, endpoint):
        self.cloudwatch.put_metric_data(
            Namespace='Application/Performance',
            MetricData=[
                {
                    'MetricName': 'RequestDuration',
                    'Dimensions': [
                        {'Name': 'Endpoint', 'Value': endpoint}
                    ],
                    'Value': duration,
                    'Unit': 'Milliseconds'
                }
            ]
        )
    
    def record_database_query_time(self, query_time, query_type):
        self.cloudwatch.put_metric_data(
            Namespace='Application/Database',
            MetricData=[
                {
                    'MetricName': 'QueryDuration',
                    'Dimensions': [
                        {'Name': 'QueryType', 'Value': query_type}
                    ],
                    'Value': query_time,
                    'Unit': 'Milliseconds'
                }
            ]
        )
```

## 🎯 Hands-on Examples

### Exercise 1: Implementing Auto-Scaling Architecture

**Objective:** Deploy a complete auto-scaling web application with load balancing and monitoring

**Steps:**

1. **Deploy the Infrastructure**
   ```bash
   cd examples/01-advanced-autoscaling
   terraform init
   terraform plan -var="environment=dev"
   terraform apply -var="environment=dev"
   ```

2. **Access the Application**
   ```bash
   # Get the load balancer DNS name
   terraform output application_url
   
   # Open in browser and test the load generation features
   curl -I $(terraform output -raw application_url)
   ```

3. **Monitor Scaling Events**
   ```bash
   # Watch Auto Scaling Group activity
   aws autoscaling describe-scaling-activities \
     --auto-scaling-group-name $(terraform output -raw auto_scaling_group_name) \
     --max-items 10
   
   # Monitor CloudWatch metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ApplicationELB \
     --metric-name RequestCount \
     --dimensions Name=LoadBalancer,Value=$(terraform output -raw load_balancer_dns | cut -d'.' -f1) \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

4. **Trigger Scaling Events**
   ```bash
   # Generate load to trigger scale-out
   for i in {1..100}; do
     curl -s $(terraform output -raw application_url) > /dev/null &
   done
   
   # Wait and observe scaling
   watch "aws autoscaling describe-auto-scaling-groups \
     --auto-scaling-group-names $(terraform output -raw auto_scaling_group_name) \
     --query 'AutoScalingGroups[0].{Desired:DesiredCapacity,Running:Instances[?LifecycleState==\`InService\`]|length(@)}'"
   ```

### Exercise 2: Database Scaling with Read Replicas

**Objective:** Implement a scalable database architecture with automatic read replica scaling

**Steps:**

1. **Deploy Database Infrastructure**
   ```bash
   cd examples/02-database-scaling
   terraform init
   terraform plan -var="environment=dev" -var="reader_instance_count=2"
   terraform apply -var="environment=dev" -var="reader_instance_count=2"
   ```

2. **Test Database Connectivity**
   ```bash
   # Get database endpoints
   terraform output cluster_endpoint
   terraform output reader_endpoint
   
   # Test connection (requires MySQL client)
   mysql -h $(terraform output -raw cluster_endpoint) -u admin -p appdb
   mysql -h $(terraform output -raw reader_endpoint) -u admin -p appdb
   ```

3. **Simulate Read Load**
   ```python
   # create_read_load.py
   import mysql.connector
   import threading
   import time
   import random
   
   def create_read_load(endpoint, duration=300):
       """Generate read load for specified duration"""
       start_time = time.time()
       
       while time.time() - start_time < duration:
           try:
               conn = mysql.connector.connect(
                   host=endpoint,
                   user='admin',
                   password='your_password',
                   database='appdb'
               )
               cursor = conn.cursor()
               
               # Simulate various read queries
               cursor.execute("SELECT COUNT(*) FROM information_schema.tables")
               cursor.execute("SELECT @@version")
               cursor.execute("SHOW STATUS LIKE 'Threads_connected'")
               
               cursor.close()
               conn.close()
               
               time.sleep(random.uniform(0.1, 0.5))
           except Exception as e:
               print(f"Error: {e}")
               time.sleep(1)
   
   # Run load test
   threads = []
   for i in range(10):  # 10 concurrent connections
       t = threading.Thread(target=create_read_load, args=("your-reader-endpoint",))
       threads.append(t)
       t.start()
   
   for t in threads:
       t.join()
   ```

4. **Monitor Auto Scaling**
   ```bash
   # Watch read replica scaling
   aws application-autoscaling describe-scalable-targets \
     --service-namespace rds \
     --resource-ids cluster:$(terraform output -raw cluster_identifier)
   
   # Monitor scaling activities
   aws application-autoscaling describe-scaling-activities \
     --service-namespace rds
   ```

### Exercise 3: Multi-Tier Caching Implementation

**Objective:** Deploy a comprehensive caching strategy with CloudFront, ElastiCache, and application-level caching

**Steps:**

1. **Deploy Caching Infrastructure**
   ```bash
   cd examples/03-multi-tier-caching
   terraform init
   terraform plan
   terraform apply
   ```

2. **Test Cache Performance**
   ```bash
   # Get CloudFront distribution domain
   CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)
   
   # Test static content caching
   curl -I https://$CLOUDFRONT_DOMAIN/index.html
   curl -I https://$CLOUDFRONT_DOMAIN/assets/style.css
   
   # Check cache headers
   curl -H "Cache-Control: no-cache" -I https://$CLOUDFRONT_DOMAIN/index.html
   ```

3. **Measure Cache Performance**
   ```bash
   # Performance testing script
   #!/bin/bash
   DOMAIN="your-cloudfront-domain"
   
   echo "Testing cache performance..."
   
   # First request (cache miss)
   echo "First request (cache miss):"
   time curl -s -o /dev/null -w "Time: %{time_total}s, Size: %{size_download} bytes\n" \
     https://$DOMAIN/assets/style.css
   
   # Second request (cache hit)
   echo "Second request (cache hit):"
   time curl -s -o /dev/null -w "Time: %{time_total}s, Size: %{size_download} bytes\n" \
     https://$DOMAIN/assets/style.css
   
   # Test from different edge location
   echo "Test from different region..."
   curl -H "CloudFront-Viewer-Country: GB" -s -o /dev/null \
     -w "Time: %{time_total}s\n" https://$DOMAIN/assets/style.css
   ```

4. **Monitor Cache Metrics**
   ```bash
   # CloudFront cache hit rate
   aws cloudwatch get-metric-statistics \
     --namespace AWS/CloudFront \
     --metric-name CacheHitRate \
     --dimensions Name=DistributionId,Value=$(terraform output -raw cloudfront_distribution_id) \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Average
   ```

## ✅ Best Practices

### 1. Auto Scaling Configuration
- **Implement predictive scaling** for workloads with known patterns
- **Use multiple scaling metrics** (CPU, memory, request count) for robust decisions
- **Set appropriate cooldown periods** to prevent thrashing
- **Test scaling policies** in non-production environments first
- **Monitor scaling events** and adjust thresholds based on actual performance

### 2. Load Balancer Optimization
- **Enable connection draining** for graceful instance termination
- **Configure health checks** with appropriate timeouts and intervals
- **Use sticky sessions judiciously** - prefer stateless design when possible
- **Implement proper SSL/TLS termination** with modern cipher suites
- **Monitor target group health** and response times continuously

### 3. Database Scaling Strategies
- **Separate read and write workloads** using Aurora read replicas
- **Implement connection pooling** to manage database connections efficiently
- **Use query optimization** and proper indexing before scaling hardware
- **Monitor replication lag** and adjust read routing accordingly
- **Plan for backup and restore** procedures that scale with your data

### 4. Caching Implementation
- **Layer caching strategies** from CDN to application to database
- **Set appropriate TTL values** based on data change frequency
- **Implement cache invalidation** strategies for dynamic content
- **Monitor cache hit rates** and optimize cache keys
- **Plan for cache warming** during deployment and scaling events

### 5. Performance Monitoring
- **Define clear SLAs and SLOs** for response time and availability
- **Implement distributed tracing** for complex request flows
- **Set up proactive alerting** before performance degradation affects users
- **Use synthetic monitoring** to detect issues before real users
- **Regularly review and adjust** scaling thresholds based on growth patterns

## ⚠️ Common Pitfalls

### 1. Over-Aggressive Scaling
**Problem:** Scaling policies that respond too quickly to temporary spikes
**Solution:**
- Implement longer evaluation periods for scale-out decisions
- Use composite alarms with multiple metrics
- Set minimum time between scaling actions
- Test with realistic load patterns

### 2. Database Connection Limits
**Problem:** Running out of database connections during traffic spikes
**Solution:**
- Implement proper connection pooling at the application level
- Monitor connection usage and set appropriate limits
- Use read replicas to distribute connection load
- Configure timeout and retry logic

### 3. Cache Stampede
**Problem:** Multiple requests trying to populate the same cache entry simultaneously
**Solution:**
```python
# Implement cache locking to prevent stampede
import redis
import time

class CacheWithLock:
    def __init__(self, redis_client):
        self.redis = redis_client
    
    def get_with_lock(self, key, fetch_function, ttl=3600):
        # Try to get from cache
        value = self.redis.get(key)
        if value:
            return json.loads(value)
        
        # Try to acquire lock
        lock_key = f"lock:{key}"
        if self.redis.set(lock_key, "1", nx=True, ex=60):  # 60 second lock
            try:
                # Fetch data
                data = fetch_function()
                # Store in cache
                self.redis.setex(key, ttl, json.dumps(data))
                return data
            finally:
                # Release lock
                self.redis.delete(lock_key)
        else:
            # Wait for lock to be released and try cache again
            time.sleep(0.1)
            return self.get_with_lock(key, fetch_function, ttl)
```

### 4. Uneven Load Distribution
**Problem:** Some instances receiving disproportionate load
**Solution:**
- Use consistent hashing for session affinity when needed
- Implement proper health checks to remove unhealthy instances
- Monitor per-instance metrics and adjust load balancer settings
- Consider using application-level load balancing

### 5. Cost Optimization Oversights
**Problem:** Scaling costs grow faster than expected
**Solution:**
- Implement cost monitoring and budgets
- Use scheduled scaling for predictable patterns
- Right-size instances based on actual usage patterns
- Consider spot instances for non-critical workloads
- Regular review and optimization of resource allocation

## 🔍 Troubleshooting

### Scaling Issues

**Problem:** Auto Scaling Group not scaling as expected

**Diagnosis:**
```bash
# Check scaling policies and alarms
aws autoscaling describe-policies \
  --auto-scaling-group-name your-asg-name

# Check CloudWatch alarm states
aws cloudwatch describe-alarms \
  --alarm-names your-alarm-name

# Review scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name your-asg-name \
  --max-items 20
```

**Solutions:**
1. Verify alarm thresholds match actual workload patterns
2. Check if cooldown periods are preventing scaling
3. Ensure launch template is valid and instances can start
4. Review IAM permissions for scaling actions

### Load Balancer Health Issues

**Problem:** Instances marked unhealthy by load balancer

**Diagnosis:**
```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn your-target-group-arn

# Review load balancer logs
aws s3 cp s3://your-alb-logs-bucket/AWSLogs/ . --recursive

# Check security group rules
aws ec2 describe-security-groups \
  --group-ids your-security-group-id
```

**Solutions:**
1. Verify health check path returns 200 status
2. Adjust health check timeout and interval settings
3. Check security group allows health check traffic
4. Review application startup time vs health check grace period

### Database Performance Issues

**Problem:** Database becoming a bottleneck despite read replicas

**Diagnosis:**
```bash
# Check Aurora metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBClusterIdentifier,Value=your-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# Review slow query logs
aws rds describe-db-log-files \
  --db-instance-identifier your-instance

# Check connection counts
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBInstanceIdentifier,Value=your-instance \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum
```

**Solutions:**
1. Optimize slow queries identified in logs
2. Implement query result caching
3. Review connection pooling configuration
4. Consider upgrading instance classes
5. Analyze query patterns for read/write distribution

## 📚 Further Reading

### Official Documentation
- [AWS Auto Scaling User Guide](https://docs.aws.amazon.com/autoscaling/ec2/userguide/)
- [Application Load Balancer Guide](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/)
- [Amazon Aurora User Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/)
- [Amazon CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)

### Advanced Scaling Topics
- [Predictive Scaling for Amazon EC2 Auto Scaling](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-predictive-scaling.html)
- [Aurora Auto Scaling](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/Aurora.Integrating.AutoScaling.html)
- [CloudFront Caching Behaviors](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesCacheBehavior)

### Software Engineering Patterns
- [Microservices Patterns: With examples in Java](https://microservices.io/patterns/)
- [Building Microservices by Sam Newman](https://samnewman.io/books/building_microservices/)
- [Site Reliability Engineering by Google](https://sre.google/books/)
- [Designing Data-Intensive Applications by Martin Kleppmann](https://dataintensive.net/)

### Performance and Observability
- [High Performance Browser Networking](https://hpbn.co/)
- [Systems Performance by Brendan Gregg](http://www.brendangregg.com/systems-performance-2nd-edition-book.html)
- [Observability Engineering by Charity Majors](https://www.oreilly.com/library/view/observability-engineering/9781492076438/)

### Community Resources
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Samples on GitHub](https://github.com/aws-samples)

## 🎯 Next Steps

Congratulations! You've mastered scalability patterns and system design principles in infrastructure. You now understand how to:

- Design and implement auto-scaling architectures that respond to real-world traffic patterns
- Configure advanced load balancing with health checks and intelligent routing
- Implement database scaling strategies with read replicas and connection pooling
- Deploy multi-tier caching solutions for optimal performance
- Apply software engineering patterns to infrastructure design
- Monitor and troubleshoot performance issues at scale

**Ready for the next challenge?** Proceed to [Module 07: Monitoring](../07-monitoring/) to learn how to implement comprehensive observability and monitoring strategies that provide deep insights into your scalable infrastructure.

### Skills Gained
✅ Auto-scaling architecture design and implementation  
✅ Advanced load balancing and traffic distribution  
✅ Database scaling with read replicas and clustering  
✅ Multi-tier caching strategies and optimization  
✅ Performance monitoring and alerting  
✅ Software engineering pattern application to infrastructure  
✅ Troubleshooting performance bottlenecks  
✅ Cost optimization for scalable systems  

### Career Impact
These scalability skills are essential for senior infrastructure roles and directly translate to:
- **Senior DevOps Engineer**: Architecting enterprise-scale infrastructure
- **Cloud Solutions Architect**: Designing scalable, fault-tolerant systems
- **Site Reliability Engineer**: Ensuring system performance under varying loads
- **Platform Engineer**: Building self-scaling infrastructure platforms
- **Principal Engineer**: Leading architectural decisions for high-growth companies