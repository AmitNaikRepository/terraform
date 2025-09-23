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

  # Default tags applied to ALL resources
  default_tags {
    tags = var.default_tags
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

locals {
  # Cost allocation tags for detailed billing
  cost_tags = {
    CostCenter    = var.cost_center
    Project       = var.project_name
    Environment   = var.environment
    Owner         = var.owner
    BusinessUnit  = var.business_unit
    Application   = var.application_name
  }

  # Operational tags for resource management
  operational_tags = {
    Terraform     = "true"
    Repository    = "terraform-fundamentals"
    LastModified  = formatdate("YYYY-MM-DD", timestamp())
    ManagedBy     = "terraform"
  }

  # Combined tags for comprehensive cost tracking
  all_tags = merge(
    var.default_tags,
    local.cost_tags,
    local.operational_tags
  )

  # Resource-specific cost calculations
  monthly_cost_estimate = {
    ec2_instances = var.instance_count * var.estimated_monthly_cost_per_instance
    s3_storage    = var.estimated_s3_monthly_cost
    vpc_resources = var.estimated_vpc_monthly_cost
    total        = var.instance_count * var.estimated_monthly_cost_per_instance + var.estimated_s3_monthly_cost + var.estimated_vpc_monthly_cost
  }
}

# VPC with comprehensive cost tagging
resource "aws_vpc" "cost_demo" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-vpc"
    ResourceType = "networking"
    CostCategory = "infrastructure"
    Service      = "vpc"
    # Cost optimization tags
    AutoShutdown = "false"
    Backup       = "false"
    Monitoring   = "basic"
  })
}

# Subnet with cost allocation tags
resource "aws_subnet" "cost_demo" {
  count = var.instance_count

  vpc_id            = aws_vpc.cost_demo.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-subnet-${count.index + 1}"
    ResourceType = "networking"
    CostCategory = "infrastructure"
    Service      = "vpc"
    AZ           = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  })
}

# Internet Gateway
resource "aws_internet_gateway" "cost_demo" {
  vpc_id = aws_vpc.cost_demo.id

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-igw"
    ResourceType = "networking"
    CostCategory = "infrastructure"
    Service      = "vpc"
    # No additional cost for IGW itself
    MonthlyCost = "0"
  })
}

# Route table
resource "aws_route_table" "cost_demo" {
  vpc_id = aws_vpc.cost_demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cost_demo.id
  }

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-rt"
    ResourceType = "networking"
    CostCategory = "infrastructure"
    Service      = "vpc"
  })
}

# Route table associations
resource "aws_route_table_association" "cost_demo" {
  count = length(aws_subnet.cost_demo)

  subnet_id      = aws_subnet.cost_demo[count.index].id
  route_table_id = aws_route_table.cost_demo.id
}

# Security group with cost tags
resource "aws_security_group" "cost_demo" {
  name_prefix = "${var.project_name}-${var.environment}-"
  description = "Security group for cost optimization demo"
  vpc_id      = aws_vpc.cost_demo.id

  ingress {
    from_port   = 80
    to_port     = 80
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

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-sg"
    ResourceType = "security"
    CostCategory = "infrastructure"
    Service      = "ec2"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# EC2 instances with detailed cost tracking tags
resource "aws_instance" "cost_demo" {
  count = var.instance_count

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.cost_demo[count.index].id
  vpc_security_group_ids = [aws_security_group.cost_demo.id]

  # Cost optimization settings
  monitoring                          = var.detailed_monitoring
  disable_api_termination            = false
  instance_initiated_shutdown_behavior = "terminate"

  # Storage optimization
  root_block_device {
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    encrypted             = true
    delete_on_termination = true

    tags = merge(local.all_tags, {
      Name                = "${var.project_name}-${var.environment}-root-vol-${count.index + 1}"
      ResourceType        = "storage"
      CostCategory        = "compute"
      Service             = "ebs"
      VolumeType          = var.volume_type
      EstimatedMonthlyCost = var.estimated_ebs_monthly_cost
    })
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    instance_number = count.index + 1
    project_name    = var.project_name
    environment     = var.environment
  }))

  tags = merge(local.all_tags, {
    Name                = "${var.project_name}-${var.environment}-instance-${count.index + 1}"
    ResourceType        = "compute"
    CostCategory        = "compute"
    Service             = "ec2"
    InstanceType        = var.instance_type
    # Cost optimization tags
    AutoShutdown        = var.auto_shutdown_enabled ? "enabled" : "disabled"
    ShutdownSchedule    = var.auto_shutdown_enabled ? var.shutdown_schedule : "none"
    BackupRequired      = var.backup_required ? "yes" : "no"
    Monitoring          = var.detailed_monitoring ? "detailed" : "basic"
    # Cost estimation tags
    EstimatedMonthlyCost = var.estimated_monthly_cost_per_instance
    CostOptimized       = "true"
    RightsizingCandidate = var.instance_type == "t3.micro" ? "no" : "review"
  })

  lifecycle {
    # Prevent accidental deletion of production instances
    prevent_destroy = false
    
    # Create before destroy for zero-downtime updates
    create_before_destroy = true
  }
}

# S3 bucket with lifecycle and cost optimization
resource "aws_s3_bucket" "cost_demo" {
  bucket = "${var.project_name}-${var.environment}-cost-demo-${random_string.bucket_suffix.result}"

  tags = merge(local.all_tags, {
    Name                = "${var.project_name}-${var.environment}-bucket"
    ResourceType        = "storage"
    CostCategory        = "storage"
    Service             = "s3"
    StorageClass        = "standard"
    LifecycleManaged    = "true"
    EstimatedMonthlyCost = var.estimated_s3_monthly_cost
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "cost_demo" {
  bucket = aws_s3_bucket.cost_demo.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket lifecycle configuration for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "cost_demo" {
  bucket = aws_s3_bucket.cost_demo.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Manage non-current versions
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    # Delete non-current versions after 1 year
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  depends_on = [aws_s3_bucket_versioning.cost_demo]
}

# CloudWatch for cost monitoring
resource "aws_cloudwatch_dashboard" "cost_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-cost-monitoring"

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
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.cost_demo[0].id],
            ["AWS/EBS", "VolumeReadOps", "VolumeId", aws_instance.cost_demo[0].root_block_device[0].volume_id],
            ["AWS/EBS", "VolumeWriteOps", "VolumeId", aws_instance.cost_demo[0].root_block_device[0].volume_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Resource Utilization - Cost Optimization Monitoring"
          period  = 300
        }
      }
    ]
  })

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-cost-dashboard"
    ResourceType = "monitoring"
    CostCategory = "operations"
    Service      = "cloudwatch"
  })
}

# Budget for cost control
resource "aws_budgets_budget" "cost_demo" {
  name         = "${var.project_name}-${var.environment}-monthly-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters {
    tag {
      key    = "Project"
      values = [var.project_name]
    }
    tag {
      key    = "Environment"
      values = [var.environment]
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  tags = merge(local.all_tags, {
    Name         = "${var.project_name}-${var.environment}-budget"
    ResourceType = "cost-control"
    CostCategory = "governance"
    Service      = "budgets"
  })
}