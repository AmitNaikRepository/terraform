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
    Module  = "right-sizing"
    Purpose = "cost-optimization-rightsizing"
  })
  
  # Instance type cost mapping (approximate monthly costs in USD)
  instance_costs = {
    "t3.nano"   = 3.80
    "t3.micro"  = 7.59
    "t3.small"  = 15.18
    "t3.medium" = 30.37
    "t3.large"  = 60.74
    "t3.xlarge" = 121.47
  }
  
  # Calculate total monthly cost estimate
  total_monthly_cost = (
    local.instance_costs[var.web_tier_instance_type] * var.web_tier_count +
    local.instance_costs[var.app_tier_instance_type] * var.app_tier_count +
    local.instance_costs[var.worker_tier_instance_type] * var.worker_tier_count
  )
}

# VPC for right-sizing demonstration
resource "aws_vpc" "rightsizing_demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Public subnet for web tier
resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.rightsizing_demo.id
  cidr_block              = "10.0.${count.index + 1}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Tier = "web"
  })
}

# Private subnet for app tier
resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.rightsizing_demo.id
  cidr_block        = "10.0.${count.index + 10}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Tier = "application"
  })
}

# Internet Gateway and routing
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.rightsizing_demo.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.rightsizing_demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-nat-gateway"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.rightsizing_demo.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "web_tier" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  description = "Security group for web tier"
  vpc_id      = aws_vpc.rightsizing_demo.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
    Tier = "web"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app_tier" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.rightsizing_demo.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_tier.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
    Tier = "application"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "worker_tier" {
  name_prefix = "${var.project_name}-${var.environment}-worker-"
  description = "Security group for worker tier"
  vpc_id      = aws_vpc.rightsizing_demo.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.app_tier.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.management_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-worker-sg"
    Tier = "worker"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Launch templates for different tiers with right-sized instances

# Web Tier - Right-sized for web serving workload
resource "aws_launch_template" "web_tier" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.web_tier_instance_type

  vpc_security_group_ids = [aws_security_group.web_tier.id]

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.web_tier_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data_web.sh", {
    tier                = "web"
    instance_type       = var.web_tier_instance_type
    estimated_cost      = local.instance_costs[var.web_tier_instance_type]
    workload_type       = "HTTP/HTTPS requests, static content serving"
    optimization_notes  = "Right-sized for web traffic patterns"
    cpu_target          = "15-25%"
    memory_target       = "40-60%"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name              = "${var.project_name}-${var.environment}-web-instance"
      Tier              = "web"
      InstanceType      = var.web_tier_instance_type
      WorkloadPattern   = "web-serving"
      RightSized        = "true"
      EstimatedMonthlyCost = local.instance_costs[var.web_tier_instance_type]
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Application Tier - Right-sized for business logic processing
resource "aws_launch_template" "app_tier" {
  name_prefix   = "${var.project_name}-${var.environment}-app-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.app_tier_instance_type

  vpc_security_group_ids = [aws_security_group.app_tier.id]

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.app_tier_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data_app.sh", {
    tier                = "application"
    instance_type       = var.app_tier_instance_type
    estimated_cost      = local.instance_costs[var.app_tier_instance_type]
    workload_type       = "Business logic, API processing, database queries"
    optimization_notes  = "Right-sized for application processing workloads"
    cpu_target          = "30-50%"
    memory_target       = "50-70%"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name              = "${var.project_name}-${var.environment}-app-instance"
      Tier              = "application"
      InstanceType      = var.app_tier_instance_type
      WorkloadPattern   = "application-processing"
      RightSized        = "true"
      EstimatedMonthlyCost = local.instance_costs[var.app_tier_instance_type]
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Worker Tier - Right-sized for background processing
resource "aws_launch_template" "worker_tier" {
  name_prefix   = "${var.project_name}-${var.environment}-worker-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.worker_tier_instance_type

  vpc_security_group_ids = [aws_security_group.worker_tier.id]

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.worker_tier_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  user_data = base64encode(templatefile("${path.module}/user_data_worker.sh", {
    tier                = "worker"
    instance_type       = var.worker_tier_instance_type
    estimated_cost      = local.instance_costs[var.worker_tier_instance_type]
    workload_type       = "Background processing, batch jobs, queue processing"
    optimization_notes  = "Right-sized for CPU-intensive background tasks"
    cpu_target          = "60-80%"
    memory_target       = "40-60%"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name              = "${var.project_name}-${var.environment}-worker-instance"
      Tier              = "worker"
      InstanceType      = var.worker_tier_instance_type
      WorkloadPattern   = "background-processing"
      RightSized        = "true"
      EstimatedMonthlyCost = local.instance_costs[var.worker_tier_instance_type]
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Groups for each tier

# Web Tier ASG
resource "aws_autoscaling_group" "web_tier" {
  name                = "${var.project_name}-${var.environment}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300

  min_size         = var.web_tier_min_size
  max_size         = var.web_tier_max_size
  desired_capacity = var.web_tier_count

  launch_template {
    id      = aws_launch_template.web_tier.id
    version = "$Latest"
  }

  # Target tracking scaling policy
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg"
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
  }
}

# Application Tier ASG
resource "aws_autoscaling_group" "app_tier" {
  name                = "${var.project_name}-${var.environment}-app-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.app_tier_min_size
  max_size         = var.app_tier_max_size
  desired_capacity = var.app_tier_count

  launch_template {
    id      = aws_launch_template.app_tier.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app-asg"
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
  }
}

# Worker Tier ASG
resource "aws_autoscaling_group" "worker_tier" {
  name                = "${var.project_name}-${var.environment}-worker-asg"
  vpc_zone_identifier = aws_subnet.private[*].id
  health_check_type   = "EC2"
  health_check_grace_period = 300

  min_size         = var.worker_tier_min_size
  max_size         = var.worker_tier_max_size
  desired_capacity = var.worker_tier_count

  launch_template {
    id      = aws_launch_template.worker_tier.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-worker-asg"
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
  }
}

# Auto Scaling Policies

# Web tier CPU-based scaling
resource "aws_autoscaling_policy" "web_tier_scale_up" {
  name                   = "${var.project_name}-${var.environment}-web-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_tier.name
}

resource "aws_autoscaling_policy" "web_tier_scale_down" {
  name                   = "${var.project_name}-${var.environment}-web-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown              = 300
  autoscaling_group_name = aws_autoscaling_group.web_tier.name
}

# CloudWatch alarms for web tier
resource "aws_cloudwatch_metric_alarm" "web_tier_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "This metric monitors web tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.web_tier_scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_tier.name
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "web_tier_cpu_low" {
  alarm_name          = "${var.project_name}-${var.environment}-web-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors web tier cpu utilization"
  alarm_actions       = [aws_autoscaling_policy.web_tier_scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_tier.name
  }

  tags = local.common_tags
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_tier.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.rightsizing_demo.id

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
    Name = "${var.project_name}-${var.environment}-web-tg"
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

# CloudWatch Dashboard for right-sizing monitoring
resource "aws_cloudwatch_dashboard" "rightsizing_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-rightsizing"

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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.web_tier.name],
            [".", ".", ".", aws_autoscaling_group.app_tier.name],
            [".", ".", ".", aws_autoscaling_group.worker_tier.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "CPU Utilization by Tier - Right-sizing Analysis"
          period  = 300
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
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.web.arn_suffix],
            [".", "TargetResponseTime", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Load Balancer Metrics - Performance vs Cost"
          period  = 300
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-rightsizing-dashboard"
  })
}