# Module 04: Cost Optimization → Resource Management Skills

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Implement Cost-Aware Architecture**: Design infrastructure with cost optimization as a first-class concern
- **Master Resource Tagging**: Implement comprehensive tagging strategies for cost allocation and tracking
- **Configure Auto-Scaling**: Set up intelligent scaling policies that balance performance and cost
- **Implement Lifecycle Management**: Automate resource lifecycle to minimize waste and optimize costs
- **Monitor and Alert on Costs**: Set up proactive cost monitoring and budget alerts
- **Apply Performance Optimization Principles**: Connect infrastructure cost optimization to software performance optimization

## 🎯 Overview

Cost optimization in infrastructure parallels performance optimization in software development. Just as developers optimize algorithms for efficiency and resource usage, infrastructure engineers must design systems that deliver maximum value while minimizing cost. This module explores how to apply performance optimization principles to infrastructure management.

We'll examine cost optimization strategies, from basic resource right-sizing to advanced techniques like spot instances, reserved capacity, and automated lifecycle management. These skills translate directly to software engineering concepts like algorithmic efficiency, memory management, and resource pooling.

## 📖 Core Concepts

### Software Performance vs Infrastructure Cost Optimization

| Software Performance | Infrastructure Cost | Purpose |
|---------------------|-------------------|---------|
| Algorithm Optimization | Instance Right-sizing | Use appropriate resources for the workload |
| Memory Management | Storage Lifecycle | Automatic cleanup of unused resources |
| Connection Pooling | Reserved Instances | Pre-allocate resources for predictable usage |
| Caching Strategies | Spot Instances | Use lower-cost resources when appropriate |
| Load Balancing | Auto Scaling | Distribute load efficiently |
| Profiling & Monitoring | Cost Analytics | Measure and optimize resource usage |

### Cost Optimization Principles

#### 1. Right-Sizing (Like Algorithm Optimization)
**Software Development:**
```typescript
// Inefficient - O(n²) algorithm
function findDuplicates(arr: number[]): number[] {
  const duplicates = [];
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j]) duplicates.push(arr[i]);
    }
  }
  return duplicates;
}

// Optimized - O(n) algorithm
function findDuplicatesOptimized(arr: number[]): number[] {
  const seen = new Set();
  const duplicates = new Set();
  for (const num of arr) {
    if (seen.has(num)) duplicates.add(num);
    seen.add(num);
  }
  return Array.from(duplicates);
}
```

**Infrastructure Equivalent:**
```hcl
# Inefficient - Oversized instances
resource "aws_instance" "oversized" {
  instance_type = "m5.24xlarge"  # 96 vCPUs for 10% utilization
  # Wastes 90% of capacity
}

# Optimized - Right-sized instances with auto scaling
resource "aws_autoscaling_group" "optimized" {
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    instance_type = "t3.medium"  # Appropriate for actual workload
  }
  
  # Scale based on actual demand
  target_group_arns = [aws_lb_target_group.app.arn]
}
```

#### 2. Resource Pooling (Like Connection Pooling)
**Software Development:**
```typescript
// Without connection pooling - expensive
class DatabaseService {
  async query(sql: string) {
    const connection = await createConnection();  // Expensive operation
    const result = await connection.execute(sql);
    await connection.close();
    return result;
  }
}

// With connection pooling - efficient
class DatabaseServiceOptimized {
  private pool: ConnectionPool;
  
  constructor() {
    this.pool = new ConnectionPool({ max: 10 });  // Reuse connections
  }
  
  async query(sql: string) {
    const connection = await this.pool.acquire();  // Fast operation
    const result = await connection.execute(sql);
    this.pool.release(connection);  // Return to pool
    return result;
  }
}
```

**Infrastructure Equivalent:**
```hcl
# Without reserved capacity - pay on-demand pricing
resource "aws_instance" "on_demand" {
  count         = 10
  instance_type = "m5.large"
  # Pays full on-demand price
}

# With reserved capacity - significant savings
resource "aws_ec2_capacity_reservation" "reserved" {
  instance_type     = "m5.large"
  instance_platform = "Linux/UNIX"
  availability_zone = "us-west-2a"
  instance_count    = 5  # Reserve base capacity
}

resource "aws_autoscaling_group" "mixed" {
  min_size         = 5   # Use reserved instances
  max_size         = 20  # Scale with spot instances
  desired_capacity = 5

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity = 5  # Use reserved capacity first
      spot_allocation_strategy = "diversified"
    }
  }
}
```

#### 3. Automated Cleanup (Like Garbage Collection)
**Software Development:**
```typescript
// Manual memory management - error prone
class ManualMemoryService {
  private cache: Map<string, any> = new Map();
  
  set(key: string, value: any) {
    this.cache.set(key, value);
    // Forgot to clean up old entries - memory leak!
  }
}

// Automatic cleanup - efficient
class AutoCleanupService {
  private cache: Map<string, {value: any, timestamp: number}> = new Map();
  
  constructor() {
    // Automatic cleanup every 5 minutes
    setInterval(() => this.cleanup(), 5 * 60 * 1000);
  }
  
  set(key: string, value: any) {
    this.cache.set(key, {value, timestamp: Date.now()});
  }
  
  private cleanup() {
    const now = Date.now();
    const maxAge = 30 * 60 * 1000; // 30 minutes
    
    for (const [key, entry] of this.cache) {
      if (now - entry.timestamp > maxAge) {
        this.cache.delete(key);  // Automatic cleanup
      }
    }
  }
}
```

**Infrastructure Equivalent:**
```hcl
# Manual cleanup - expensive and error-prone
resource "aws_s3_bucket" "manual" {
  bucket = "manual-cleanup-bucket"
  # No lifecycle rules - objects accumulate forever
}

# Automatic lifecycle management - cost-effective
resource "aws_s3_bucket" "optimized" {
  bucket = "optimized-bucket"
}

resource "aws_s3_bucket_lifecycle_configuration" "optimization" {
  bucket = aws_s3_bucket.optimized.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    # Transition to cheaper storage classes automatically
    transition {
      days          = 30
      storage_class = "STANDARD_INFREQUENT_ACCESS"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Automatic cleanup of old data
    expiration {
      days = 2555  # 7 years retention
    }
  }
}
```

## 🛠️ Terraform Implementation

### 1. Comprehensive Tagging Strategy

```hcl
# examples/01-cost-tagging/main.tf

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
    tags = local.default_tags
  }
}

locals {
  # Comprehensive tagging strategy for cost allocation
  default_tags = {
    Project      = var.project_name
    Environment  = var.environment
    Owner        = var.owner
    CostCenter   = var.cost_center
    Department   = var.department
    Application  = var.application_name
    ManagedBy    = "Terraform"
    Repository   = "terraform-fundamentals"
    
    # Cost optimization tags
    CostOptimization = "enabled"
    BackupPolicy     = var.backup_policy
    Monitoring       = "enabled"
    
    # Compliance tags
    DataClass        = var.data_classification
    Compliance       = var.compliance_requirements
    
    # Operational tags
    MaintenanceWindow = var.maintenance_window
    BusinessHours     = var.business_hours
    AutoShutdown      = var.auto_shutdown_enabled
  }
  
  # Environment-specific cost configurations
  cost_config = {
    dev = {
      auto_shutdown_enabled = true
      backup_retention_days = 7
      monitoring_level     = "basic"
      instance_types       = ["t3.micro", "t3.small"]
      storage_classes      = ["STANDARD"]
    }
    staging = {
      auto_shutdown_enabled = true
      backup_retention_days = 14
      monitoring_level     = "detailed"
      instance_types       = ["t3.small", "t3.medium"]
      storage_classes      = ["STANDARD", "STANDARD_IA"]
    }
    prod = {
      auto_shutdown_enabled = false
      backup_retention_days = 30
      monitoring_level     = "detailed"
      instance_types       = ["t3.medium", "t3.large", "m5.large"]
      storage_classes      = ["STANDARD", "STANDARD_IA", "GLACIER"]
    }
  }
  
  current_config = local.cost_config[var.environment]
}

# Cost allocation tag resource
resource "aws_s3_bucket" "cost_tagged_storage" {
  bucket = "${var.project_name}-${var.environment}-cost-demo-${random_string.suffix.result}"

  tags = merge(local.default_tags, {
    Name         = "${var.project_name}-${var.environment}-cost-demo"
    ResourceType = "storage"
    Purpose      = "cost-optimization-demo"
    
    # Detailed cost allocation tags
    Team            = var.team_name
    ProductOwner    = var.product_owner
    TechnicalOwner  = var.technical_owner
    BillingContact  = var.billing_contact
    
    # Cost tracking tags
    ChargebackCode  = var.chargeback_code
    BudgetCategory  = "infrastructure"
    CostAllocation  = "${var.department}-${var.team_name}"
    
    # Usage tracking
    ExpectedUsage   = var.expected_monthly_usage
    UsagePattern    = var.usage_pattern
    BusinessCriticality = var.business_criticality
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Cost-optimized lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "cost_optimization" {
  bucket = aws_s3_bucket.cost_tagged_storage.id

  rule {
    id     = "cost_optimization_lifecycle"
    status = "Enabled"

    # Intelligent tiering for automatic cost optimization
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    # Environment-specific transitions
    dynamic "transition" {
      for_each = var.environment == "prod" ? [1] : []
      content {
        days          = 30
        storage_class = "STANDARD_INFREQUENT_ACCESS"
      }
    }

    dynamic "transition" {
      for_each = var.environment == "prod" ? [1] : []
      content {
        days          = 90
        storage_class = "GLACIER"
      }
    }

    dynamic "transition" {
      for_each = var.environment == "prod" ? [1] : []
      content {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    }

    # Environment-specific expiration
    expiration {
      days = local.current_config.backup_retention_days
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Clean up expired delete markers
    expiration {
      expired_object_delete_marker = true
    }
  }

  # Rule for cleaning up old versions
  rule {
    id     = "version_cleanup"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_INFREQUENT_ACCESS"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.current_config.backup_retention_days
    }
  }
}

# Intelligent tiering configuration
resource "aws_s3_bucket_intelligent_tiering_configuration" "cost_optimization" {
  bucket = aws_s3_bucket.cost_tagged_storage.id
  name   = "cost-optimization"

  # Apply to all objects
  filter {
    prefix = ""
  }

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# Cost monitoring and alerting
resource "aws_cloudwatch_metric_alarm" "high_cost_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cost-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = var.cost_alert_threshold
  alarm_description   = "This metric monitors AWS estimated charges"
  alarm_actions       = [aws_sns_topic.cost_alerts.arn]

  dimensions = {
    Currency = "USD"
  }

  tags = merge(local.default_tags, {
    Purpose = "cost-monitoring"
    Type    = "alarm"
  })
}

# SNS topic for cost alerts
resource "aws_sns_topic" "cost_alerts" {
  name = "${var.project_name}-${var.environment}-cost-alerts"

  tags = merge(local.default_tags, {
    Purpose = "cost-alerting"
    Type    = "notification"
  })
}

resource "aws_sns_topic_subscription" "cost_email_alerts" {
  count     = length(var.cost_alert_emails)
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.cost_alert_emails[count.index]
}

# Budget for proactive cost management
resource "aws_budgets_budget" "project_budget" {
  name       = "${var.project_name}-${var.environment}-budget"
  budget_type = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Tag = [
      "Project:${var.project_name}",
      "Environment:${var.environment}"
    ]
  }

  notification {
    comparison_operator   = "GREATER_THAN"
    threshold            = 80
    threshold_type       = "PERCENTAGE"
    notification_type    = "ACTUAL"
    subscriber_email_addresses = var.cost_alert_emails
  }

  notification {
    comparison_operator   = "GREATER_THAN"
    threshold            = 100
    threshold_type       = "PERCENTAGE"
    notification_type    = "FORECASTED"
    subscriber_email_addresses = var.cost_alert_emails
  }

  depends_on = [aws_sns_topic.cost_alerts]
}
```

### 2. Auto-Scaling and Spot Instances

```hcl
# examples/02-scaling-optimization/main.tf

# Data sources
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Cost-optimized launch template with mixed instance types
resource "aws_launch_template" "cost_optimized" {
  name_prefix   = "${var.project_name}-${var.environment}-cost-optimized-"
  image_id      = data.aws_ami.amazon_linux.id
  
  # Use smaller instance types for cost optimization
  instance_type = local.current_config.instance_types[0]

  vpc_security_group_ids = var.security_group_ids

  # Instance metadata options for security
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }

  # Cost optimization through instance lifecycle
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type = "one-time"
      max_price         = var.max_spot_price
    }
  }

  # User data for cost monitoring
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    region       = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.default_tags, {
      Name        = "${var.project_name}-${var.environment}-cost-optimized"
      LaunchType  = "spot"
      CostSaving  = "enabled"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.default_tags, {
      Name       = "${var.project_name}-${var.environment}-cost-optimized-volume"
      VolumeType = "gp3"
    })
  }
}

# Auto Scaling Group with mixed instances policy for cost optimization
resource "aws_autoscaling_group" "cost_optimized" {
  name                = "${var.project_name}-${var.environment}-cost-optimized-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns
  health_check_type   = "ELB"
  health_check_grace_period = 300

  # Base configuration
  min_size         = local.current_config.min_size
  max_size         = local.current_config.max_size
  desired_capacity = local.current_config.desired_capacity

  # Mixed instances policy for cost optimization
  mixed_instances_policy {
    instances_distribution {
      # Cost optimization: Prefer spot instances
      on_demand_base_capacity                = local.current_config.on_demand_base
      on_demand_percentage_above_base_capacity = local.current_config.on_demand_percentage
      spot_allocation_strategy               = "diversified"
      spot_instance_pools                    = 4
      spot_max_price                        = var.max_spot_price
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.cost_optimized.id
        version           = "$Latest"
      }

      # Multiple instance types for better spot availability and cost optimization
      dynamic "override" {
        for_each = local.current_config.instance_types
        content {
          instance_type = override.value
          
          # Prefer smaller, cost-effective instances
          weighted_capacity = override.value == "t3.micro" ? "2" : "1"
        }
      }
    }
  }

  # Lifecycle hooks for cost optimization
  initial_lifecycle_hook {
    name                 = "cost-optimization-launch"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
  }

  initial_lifecycle_hook {
    name                 = "cost-optimization-terminate"
    default_result       = "CONTINUE"
    heartbeat_timeout    = 300
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
  }

  # Enable instance protection for cost savings
  protect_from_scale_in = var.environment == "prod"

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-cost-optimized-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = local.default_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "CostOptimization"
    value               = "mixed-instances"
    propagate_at_launch = true
  }
}

# Predictive scaling policy
resource "aws_autoscaling_policy" "predictive_scaling" {
  name                   = "${var.project_name}-${var.environment}-predictive-scaling"
  scaling_adjustment     = 0  # Not used with predictive scaling
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.cost_optimized.name

  predictive_scaling_configuration {
    metric_specification {
      target_value = 50.0
      predefined_metric_specification {
        predefined_metric_type = "ASGAverageCPUUtilization"
      }
    }
    mode = "ForecastAndScale"
    scheduling_buffer_time = 300
  }
}

# Target tracking scaling policy for cost optimization
resource "aws_autoscaling_policy" "target_tracking_cpu" {
  name                   = "${var.project_name}-${var.environment}-target-tracking-cpu"
  scaling_adjustment     = 0  # Not used with target tracking
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.cost_optimized.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0  # Higher target for cost optimization
    
    # Scale down aggressively to save costs
    scale_out_cooldown = 300
    scale_in_cooldown  = 180
  }
}

# Scheduled scaling for predictable cost savings
resource "aws_autoscaling_schedule" "scale_down_evening" {
  count                  = var.enable_scheduled_scaling ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-down-evening"
  min_size               = 1
  max_size               = local.current_config.max_size
  desired_capacity       = 1
  recurrence            = "0 20 * * MON-FRI"  # 8 PM Monday-Friday
  autoscaling_group_name = aws_autoscaling_group.cost_optimized.name
}

resource "aws_autoscaling_schedule" "scale_up_morning" {
  count                  = var.enable_scheduled_scaling ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-up-morning"
  min_size               = local.current_config.min_size
  max_size               = local.current_config.max_size
  desired_capacity       = local.current_config.desired_capacity
  recurrence            = "0 8 * * MON-FRI"  # 8 AM Monday-Friday
  autoscaling_group_name = aws_autoscaling_group.cost_optimized.name
}

# Weekend scale-down for additional cost savings
resource "aws_autoscaling_schedule" "scale_down_weekend" {
  count                  = var.enable_scheduled_scaling ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-down-weekend"
  min_size               = 0
  max_size               = local.current_config.max_size
  desired_capacity       = var.environment == "prod" ? 1 : 0
  recurrence            = "0 22 * * FRI"  # 10 PM Friday
  autoscaling_group_name = aws_autoscaling_group.cost_optimized.name
}

resource "aws_autoscaling_schedule" "scale_up_weekend_end" {
  count                  = var.enable_scheduled_scaling ? 1 : 0
  scheduled_action_name  = "${var.project_name}-${var.environment}-scale-up-weekend-end"
  min_size               = local.current_config.min_size
  max_size               = local.current_config.max_size
  desired_capacity       = local.current_config.desired_capacity
  recurrence            = "0 6 * * MON"  # 6 AM Monday
  autoscaling_group_name = aws_autoscaling_group.cost_optimized.name
}
```

### 3. Reserved Capacity and Savings Plans

```hcl
# examples/03-reserved-capacity/main.tf

# Reserved capacity for predictable workloads
resource "aws_ec2_capacity_reservation" "production_reserved" {
  count = var.environment == "prod" ? 1 : 0
  
  instance_type        = var.reserved_instance_type
  instance_platform    = "Linux/UNIX"
  availability_zone    = data.aws_availability_zones.available.names[0]
  instance_count       = var.reserved_instance_count
  instance_match_criteria = "targeted"

  tags = merge(local.default_tags, {
    Name           = "${var.project_name}-${var.environment}-reserved-capacity"
    Purpose        = "cost-optimization"
    ReservationType = "capacity-reservation"
    SavingsType    = "reserved-capacity"
  })
}

# Launch template for reserved instances
resource "aws_launch_template" "reserved_optimized" {
  count = var.environment == "prod" ? 1 : 0
  
  name_prefix   = "${var.project_name}-${var.environment}-reserved-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.reserved_instance_type

  vpc_security_group_ids = var.security_group_ids

  # Target specific capacity reservation
  capacity_reservation_specification {
    capacity_reservation_preference = "targeted"
    capacity_reservation_target {
      capacity_reservation_id = aws_ec2_capacity_reservation.production_reserved[0].id
    }
  }

  # EBS optimization for cost and performance
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = "gp3"  # Cost-effective GP3
      volume_size = 20
      iops        = 3000   # Baseline IOPS
      throughput  = 125    # Baseline throughput
      encrypted   = true
      
      # Cost optimization: Delete on termination
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.default_tags, {
      Name         = "${var.project_name}-${var.environment}-reserved"
      LaunchType   = "reserved"
      CostSaving   = "reserved-instance"
    })
  }
}

# Cost-optimized EBS volumes
resource "aws_ebs_volume" "cost_optimized" {
  count = var.create_additional_storage ? length(var.subnet_ids) : 0
  
  availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  size              = var.storage_size_gb
  type              = "gp3"  # Most cost-effective for general purpose
  
  # GP3 allows independent IOPS and throughput configuration
  iops       = var.storage_iops
  throughput = var.storage_throughput
  
  encrypted  = true
  kms_key_id = var.kms_key_id

  tags = merge(local.default_tags, {
    Name        = "${var.project_name}-${var.environment}-cost-optimized-${count.index + 1}"
    VolumeType  = "gp3"
    Purpose     = "cost-optimized-storage"
    CostSaving  = "gp3-optimization"
  })
}

# Savings plan simulation (informational)
resource "aws_s3_object" "savings_plan_analysis" {
  bucket  = var.cost_analysis_bucket
  key     = "${var.project_name}/${var.environment}/savings-plan-analysis.json"
  content = jsonencode({
    project     = var.project_name
    environment = var.environment
    analysis_date = timestamp()
    
    current_usage = {
      instance_types = local.current_config.instance_types
      estimated_hours_per_month = 730 * local.current_config.desired_capacity
      on_demand_hourly_cost = var.on_demand_hourly_cost
      estimated_monthly_cost = 730 * local.current_config.desired_capacity * var.on_demand_hourly_cost
    }
    
    savings_recommendations = {
      compute_savings_plan = {
        commitment_term = "1year"
        payment_option = "all_upfront"
        estimated_savings_percentage = 17
        recommended_commitment = 730 * local.current_config.min_size * var.on_demand_hourly_cost * 0.7
      }
      
      ec2_instance_savings_plan = {
        commitment_term = "1year"
        payment_option = "partial_upfront"
        estimated_savings_percentage = 10
        instance_family = "t3"
        recommended_commitment = 730 * local.current_config.min_size * var.on_demand_hourly_cost * 0.8
      }
      
      reserved_instances = {
        commitment_term = "1year"
        payment_option = "partial_upfront"
        estimated_savings_percentage = 8
        instance_type = var.reserved_instance_type
        recommended_quantity = local.current_config.min_size
      }
    }
    
    optimization_recommendations = [
      "Use Compute Savings Plans for workloads with consistent usage patterns",
      "Consider Reserved Instances for stable, long-running workloads",
      "Implement auto-scaling to optimize for variable workloads",
      "Use Spot Instances for fault-tolerant workloads",
      "Enable GP3 volumes for cost-effective storage",
      "Implement lifecycle policies for automated cost optimization"
    ]
  })

  tags = merge(local.default_tags, {
    Purpose = "cost-analysis"
    Type    = "savings-plan-analysis"
  })
}

# Cost optimization report generation
resource "aws_lambda_function" "cost_optimization_report" {
  function_name = "${var.project_name}-${var.environment}-cost-optimization-report"
  role         = aws_iam_role.lambda_cost_report.arn
  handler      = "index.handler"
  runtime      = "python3.9"
  timeout      = 300

  filename = data.archive_file.cost_report_lambda.output_path
  source_code_hash = data.archive_file.cost_report_lambda.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      S3_BUCKET    = var.cost_analysis_bucket
    }
  }

  tags = merge(local.default_tags, {
    Purpose = "cost-reporting"
    Type    = "lambda-function"
  })
}

data "archive_file" "cost_report_lambda" {
  type        = "zip"
  output_path = "${path.module}/cost_report_lambda.zip"
  
  source {
    content = templatefile("${path.module}/cost_report_lambda.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for cost optimization Lambda
resource "aws_iam_role" "lambda_cost_report" {
  name = "${var.project_name}-${var.environment}-lambda-cost-report"

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

  tags = local.default_tags
}

resource "aws_iam_role_policy" "lambda_cost_report" {
  name = "${var.project_name}-${var.environment}-lambda-cost-report-policy"
  role = aws_iam_role.lambda_cost_report.id

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
          "ce:GetCostAndUsage",
          "ce:GetUsageReport",
          "ce:GetRightsizingRecommendation",
          "ce:GetSavingsPlansUtilization",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${aws_s3_bucket.cost_reports.arn}/*"
      }
    ]
  })
}

# S3 bucket for cost reports
resource "aws_s3_bucket" "cost_reports" {
  bucket = "${var.project_name}-${var.environment}-cost-reports-${random_string.suffix.result}"

  tags = merge(local.default_tags, {
    Purpose = "cost-reporting"
    Type    = "reports-storage"
  })
}

# Schedule cost optimization report
resource "aws_cloudwatch_event_rule" "cost_report_schedule" {
  name                = "${var.project_name}-${var.environment}-cost-report-schedule"
  description         = "Schedule for cost optimization report generation"
  schedule_expression = "cron(0 8 1 * ? *)"  # First day of month at 8 AM

  tags = merge(local.default_tags, {
    Purpose = "cost-reporting"
    Type    = "scheduled-event"
  })
}

resource "aws_cloudwatch_event_target" "cost_report_target" {
  rule      = aws_cloudwatch_event_rule.cost_report_schedule.name
  target_id = "CostReportLambdaTarget"
  arn       = aws_lambda_function.cost_optimization_report.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_optimization_report.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.cost_report_schedule.arn
}
```

## 🔗 Software Engineering Connections

### Performance Optimization Patterns

#### 1. Algorithmic Efficiency → Resource Right-Sizing
**Software Development:**
```typescript
// Before: Inefficient nested loops O(n²)
function findIntersection(arr1: number[], arr2: number[]): number[] {
  const result = [];
  for (const item1 of arr1) {
    for (const item2 of arr2) {
      if (item1 === item2) result.push(item1);
    }
  }
  return result;
}

// After: Optimized with Set O(n)
function findIntersectionOptimized(arr1: number[], arr2: number[]): number[] {
  const set1 = new Set(arr1);
  return arr2.filter(item => set1.has(item));
}
```

**Infrastructure Equivalent:**
```hcl
# Before: Oversized, always-on resources
resource "aws_instance" "inefficient" {
  count         = 10
  instance_type = "m5.24xlarge"  # Massive overkill
  # Always running, 90% idle
}

# After: Right-sized with auto-scaling
resource "aws_autoscaling_group" "efficient" {
  min_size         = 2    # Right-sized baseline
  max_size         = 20   # Scale when needed
  desired_capacity = 3
  
  launch_template {
    instance_type = "t3.medium"  # Appropriate size
  }
  
  # Scale based on actual demand
  target_tracking_scaling_policies = [...]
}
```

#### 2. Memory Management → Storage Lifecycle
**Software Development:**
```typescript
// Memory leak - objects never cleaned up
class DataProcessor {
  private cache = new Map<string, ProcessedData>();
  
  process(data: RawData): ProcessedData {
    const key = data.id;
    if (!this.cache.has(key)) {
      this.cache.set(key, this.expensiveOperation(data));
      // Memory leak: never removes old entries
    }
    return this.cache.get(key)!;
  }
}

// Proper memory management with cleanup
class OptimizedDataProcessor {
  private cache = new Map<string, {data: ProcessedData, timestamp: number}>();
  
  constructor() {
    setInterval(() => this.cleanup(), 60000); // Cleanup every minute
  }
  
  process(data: RawData): ProcessedData {
    const key = data.id;
    if (!this.cache.has(key)) {
      this.cache.set(key, {
        data: this.expensiveOperation(data),
        timestamp: Date.now()
      });
    }
    return this.cache.get(key)!.data;
  }
  
  private cleanup() {
    const maxAge = 30 * 60 * 1000; // 30 minutes
    const now = Date.now();
    
    for (const [key, entry] of this.cache) {
      if (now - entry.timestamp > maxAge) {
        this.cache.delete(key); // Automatic cleanup
      }
    }
  }
}
```

**Infrastructure Equivalent:**
```hcl
# No lifecycle management - costs accumulate
resource "aws_s3_bucket" "no_lifecycle" {
  bucket = "data-accumulation-bucket"
  # Objects stay forever, costs grow linearly
}

# Automated lifecycle management
resource "aws_s3_bucket_lifecycle_configuration" "optimized" {
  bucket = aws_s3_bucket.managed.id

  rule {
    id     = "cost_optimization"
    status = "Enabled"

    # Automatic transitions to cheaper storage
    transition {
      days          = 30
      storage_class = "STANDARD_INFREQUENT_ACCESS"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Automatic cleanup
    expiration {
      days = 2555  # 7 years
    }
  }
}
```

#### 3. Resource Pooling → Reserved Capacity
**Software Development:**
```typescript
// Expensive: Create new connections each time
class DatabaseService {
  async query(sql: string) {
    const connection = await createConnection(); // Expensive
    const result = await connection.execute(sql);
    await connection.close();
    return result;
  }
}

// Optimized: Connection pooling
class PooledDatabaseService {
  private pool: ConnectionPool;
  
  constructor() {
    this.pool = new ConnectionPool({
      min: 5,    // Always maintain minimum
      max: 20,   // Scale up when needed
      acquireTimeoutMillis: 30000
    });
  }
  
  async query(sql: string) {
    const connection = await this.pool.acquire(); // Fast
    try {
      return await connection.execute(sql);
    } finally {
      this.pool.release(connection); // Return to pool
    }
  }
}
```

**Infrastructure Equivalent:**
```hcl
# Expensive: Always pay on-demand prices
resource "aws_instance" "on_demand" {
  count         = 10
  instance_type = "m5.large"
  # Pay full on-demand pricing
}

# Optimized: Reserved capacity + scaling
resource "aws_ec2_capacity_reservation" "baseline" {
  instance_type     = "m5.large"
  instance_count    = 5  # Reserve baseline capacity
  instance_platform = "Linux/UNIX"
}

resource "aws_autoscaling_group" "hybrid" {
  min_size         = 5   # Use reserved capacity
  max_size         = 20  # Scale with spot/on-demand
  desired_capacity = 5

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity = 5  # Use reserved first
      spot_allocation_strategy = "diversified"
    }
  }
}
```

## 🎯 Hands-on Examples

### Exercise 1: Implement Comprehensive Cost Tagging

**Objective:** Create a tagging strategy that enables detailed cost allocation and tracking

**Requirements:**
- Tag all resources with cost center, team, and project information
- Implement environment-specific cost optimization settings
- Set up cost alerts and budgets
- Create cost allocation reports

**Steps:**
1. Define comprehensive tagging taxonomy
2. Implement default tags at provider level
3. Add resource-specific cost allocation tags
4. Set up CloudWatch billing alarms
5. Create AWS Budgets with notifications
6. Generate cost allocation reports

### Exercise 2: Build Mixed Instance Auto Scaling

**Objective:** Implement cost-optimized auto scaling using spot instances and multiple instance types

**Requirements:**
- Use spot instances for cost savings
- Implement multiple instance types for availability
- Set up predictive scaling policies
- Configure scheduled scaling for predictable patterns

**Steps:**
1. Create launch template with spot instance configuration
2. Configure mixed instances policy in Auto Scaling Group
3. Set up target tracking scaling policies
4. Implement scheduled scaling rules
5. Test scaling behavior and cost impact

### Exercise 3: Design Storage Lifecycle Optimization

**Objective:** Implement automated storage lifecycle policies for cost optimization

**Requirements:**
- Automatic transition to cheaper storage classes
- Intelligent tiering for access pattern optimization
- Automated cleanup of old data
- Cross-region replication for critical data

**Steps:**
1. Analyze access patterns and requirements
2. Configure S3 lifecycle policies
3. Enable intelligent tiering
4. Set up automated cleanup rules
5. Monitor cost impact and adjust policies

## ✅ Best Practices

### 1. Tagging Strategy

#### Comprehensive Cost Allocation Tags
```hcl
locals {
  cost_allocation_tags = {
    # Financial tracking
    CostCenter     = var.cost_center
    Department     = var.department
    Project        = var.project_name
    Team          = var.team_name
    Owner         = var.owner
    
    # Billing and chargeback
    ChargebackCode = var.chargeback_code
    BudgetCategory = var.budget_category
    BillingContact = var.billing_contact
    
    # Operational
    Environment   = var.environment
    Application   = var.application_name
    Service       = var.service_name
    
    # Cost optimization
    AutoShutdown    = var.auto_shutdown_enabled
    BackupPolicy    = var.backup_policy
    MonitoringLevel = var.monitoring_level
    
    # Compliance
    DataClass    = var.data_classification
    Compliance   = var.compliance_requirements
    RetentionPolicy = var.retention_policy
  }
}
```

#### Tag-Based Cost Controls
```hcl
# Automated shutdown based on tags
resource "aws_lambda_function" "auto_shutdown" {
  environment {
    variables = {
      SHUTDOWN_TAG_KEY   = "AutoShutdown"
      SHUTDOWN_TAG_VALUE = "enabled"
      ENVIRONMENT_TAG    = var.environment
    }
  }
}
```

### 2. Auto-Scaling Optimization

#### Cost-Aware Scaling Policies
```hcl
resource "aws_autoscaling_policy" "cost_optimized_scaling" {
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 70.0  # Higher target = fewer instances
    
    # Aggressive scale-in for cost optimization
    scale_in_cooldown  = 120  # Scale down quickly
    scale_out_cooldown = 300  # Scale up conservatively
  }
}
```

#### Spot Instance Best Practices
```hcl
resource "aws_autoscaling_group" "spot_optimized" {
  mixed_instances_policy {
    instances_distribution {
      spot_allocation_strategy = "diversified"
      spot_instance_pools     = 4
      spot_max_price         = "0.05"  # Set reasonable limit
    }
    
    launch_template {
      # Multiple instance types for better spot availability
      override {
        instance_type = "t3.medium"
      }
      override {
        instance_type = "t3a.medium"  # AMD instances often cheaper
      }
      override {
        instance_type = "t2.medium"   # Previous generation fallback
      }
    }
  }
}
```

### 3. Storage Cost Optimization

#### S3 Lifecycle Optimization
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "comprehensive" {
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "comprehensive_cost_optimization"
    status = "Enabled"

    # Immediate intelligent tiering
    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }

    # Standard-IA for older data
    transition {
      days          = 30
      storage_class = "STANDARD_INFREQUENT_ACCESS"
    }

    # Glacier for archival
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Deep Archive for long-term retention
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Cleanup incomplete uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
```

#### EBS Volume Optimization
```hcl
resource "aws_ebs_volume" "optimized" {
  type       = "gp3"  # Most cost-effective
  size       = var.volume_size
  iops       = 3000   # Baseline, only pay for additional IOPS if needed
  throughput = 125    # Baseline, only pay for additional throughput if needed
  encrypted  = true
}
```

### 4. Reserved Capacity Planning

#### Strategic Reserved Instance Usage
```hcl
# Reserve capacity for baseline, predictable workloads
resource "aws_ec2_capacity_reservation" "strategic" {
  instance_type     = "m5.large"
  instance_count    = local.baseline_capacity
  instance_platform = "Linux/UNIX"
  
  # Target specific workloads
  instance_match_criteria = "targeted"
}
```

## ⚠️ Common Pitfalls

### 1. Over-Optimization
**Problem:** Optimizing costs at the expense of performance or reliability

**Solution:**
- Set minimum performance baselines
- Monitor application metrics during optimization
- Implement gradual rollout of cost optimizations
- Have rollback plans for optimization changes

### 2. Inadequate Monitoring
**Problem:** Making cost optimization decisions without proper visibility

**Solution:**
- Implement comprehensive cost monitoring
- Use Cost Explorer and AWS Budgets
- Set up automated cost anomaly detection
- Regular cost optimization reviews

### 3. Spot Instance Overreliance
**Problem:** Using spot instances for workloads that can't handle interruptions

**Solution:**
- Use spot instances only for fault-tolerant workloads
- Implement proper spot instance interruption handling
- Mix spot with on-demand instances
- Have fallback strategies for spot interruptions

### 4. Ignoring Data Transfer Costs
**Problem:** Focusing only on compute and storage costs while ignoring data transfer

**Solution:**
- Monitor data transfer patterns
- Optimize data transfer between regions
- Use CloudFront for content delivery
- Implement data compression and caching

## 🔍 Troubleshooting

### Cost Spike Investigation

**Problem:** Unexpected increase in AWS costs

**Diagnosis Steps:**
```bash
# Use AWS CLI to investigate cost spikes
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Check for cost anomalies
aws ce get-anomalies \
  --date-interval StartDate=2024-01-01,EndDate=2024-01-31
```

**Common Solutions:**
1. Check for unused resources (idle EC2 instances, unused EBS volumes)
2. Review data transfer costs between regions
3. Investigate unoptimized database queries causing high RDS costs
4. Check for misconfigured auto-scaling policies

### Auto-Scaling Issues

**Problem:** Auto-scaling not optimizing costs effectively

**Diagnosis:**
```bash
# Check auto-scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name my-asg

# Review scaling policies
aws autoscaling describe-policies \
  --auto-scaling-group-name my-asg
```

**Solutions:**
1. Adjust scaling thresholds and cooldowns
2. Review instance types and pricing
3. Check for proper spot instance configuration
4. Verify scheduled scaling policies

### Storage Cost Issues

**Problem:** High S3 storage costs despite lifecycle policies

**Diagnosis:**
```bash
# Check storage class distribution
aws s3api list-objects-v2 \
  --bucket my-bucket \
  --query 'Contents[?StorageClass!=null].[Key,StorageClass,Size]'

# Review lifecycle policy effectiveness
aws s3api get-bucket-lifecycle-configuration \
  --bucket my-bucket
```

**Solutions:**
1. Verify lifecycle policies are working correctly
2. Check for large numbers of small objects (overhead costs)
3. Review incomplete multipart uploads
4. Consider object versioning impact on costs

## 📚 Further Reading

### Official Documentation
- [AWS Cost Optimization](https://aws.amazon.com/aws-cost-management/)
- [EC2 Spot Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
- [S3 Storage Classes](https://aws.amazon.com/s3/storage-classes/)

### Cost Optimization Tools
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [AWS Budgets](https://aws.amazon.com/aws-cost-management/aws-budgets/)
- [AWS Trusted Advisor](https://aws.amazon.com/premiumsupport/technology/trusted-advisor/)

### Advanced Topics
- [Reserved Instance and Savings Plans](https://aws.amazon.com/ec2/pricing/reserved-instances/)
- [Cost Allocation Tags](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/cost-alloc-tags.html)
- [AWS Well-Architected Cost Optimization](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/)

## 🎯 Next Steps

Congratulations! You've mastered cost optimization strategies that parallel software performance optimization principles. You now understand how to:

- Implement comprehensive cost allocation and tracking
- Design auto-scaling policies for cost efficiency
- Manage storage lifecycles for optimal costs
- Apply performance optimization mindset to infrastructure

**Ready for the next challenge?** Proceed to [Module 05: Environment Management](../05-environment-management/) to learn how to manage multiple environments using DevOps pipeline concepts.

### Skills Gained
✅ Cost-aware infrastructure design  
✅ Comprehensive resource tagging strategies  
✅ Auto-scaling and spot instance optimization  
✅ Storage lifecycle management  
✅ Cost monitoring and alerting  
✅ Performance optimization principles application  

### Career Impact
These cost optimization skills are highly valued across roles:
- **Cloud Financial Operations (FinOps)**: Managing cloud costs and optimization
- **DevOps Engineer**: Building cost-efficient deployment pipelines
- **Cloud Architect**: Designing cost-optimized architectures
- **Platform Engineer**: Creating cost-aware infrastructure platforms