variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region name."
  }
}

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string
  default     = "lifecycle-mgmt-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
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

# S3 Lifecycle Configuration Variables
variable "enable_object_expiration" {
  description = "Enable automatic deletion of objects after retention period"
  type        = bool
  default     = false
}

variable "object_expiration_days" {
  description = "Number of days after which objects are automatically deleted"
  type        = number
  default     = 365

  validation {
    condition     = var.object_expiration_days >= 1 && var.object_expiration_days <= 3650
    error_message = "Object expiration days must be between 1 and 3650 (10 years)."
  }
}

variable "backup_retention_enabled" {
  description = "Enable automatic deletion of backup objects"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backup objects"
  type        = number
  default     = 2555  # 7 years

  validation {
    condition     = var.backup_retention_days >= 90 && var.backup_retention_days <= 3650
    error_message = "Backup retention days must be between 90 and 3650 days."
  }
}

# EC2 and Auto Scaling Variables
variable "instance_type" {
  description = "EC2 instance type (cost-optimized)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t2.micro", "t2.small"], var.instance_type)
    error_message = "Instance type must be a cost-optimized type."
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (leave empty for latest Amazon Linux)"
  type        = string
  default     = ""
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.volume_size >= 8 && var.volume_size <= 100
    error_message = "Volume size must be between 8 and 100 GB."
  }
}

variable "use_spot_instances" {
  description = "Use Spot Instances for additional cost savings"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum price for Spot Instances (per hour)"
  type        = string
  default     = "0.0116"  # Typical Spot price for t3.micro

  validation {
    condition     = can(tonumber(var.spot_max_price))
    error_message = "Spot max price must be a valid number."
  }
}

# Auto Scaling Group Configuration
variable "asg_min_size" {
  description = "Minimum number of instances in Auto Scaling Group"
  type        = number
  default     = 1

  validation {
    condition     = var.asg_min_size >= 0 && var.asg_min_size <= 10
    error_message = "ASG minimum size must be between 0 and 10."
  }
}

variable "asg_max_size" {
  description = "Maximum number of instances in Auto Scaling Group"
  type        = number
  default     = 3

  validation {
    condition     = var.asg_max_size >= 1 && var.asg_max_size <= 10
    error_message = "ASG maximum size must be between 1 and 10."
  }
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in Auto Scaling Group"
  type        = number
  default     = 2

  validation {
    condition     = var.asg_desired_capacity >= 1 && var.asg_desired_capacity <= 10
    error_message = "ASG desired capacity must be between 1 and 10."
  }
}

# Scheduled Scaling Variables
variable "enable_scheduled_scaling" {
  description = "Enable scheduled scaling for cost optimization"
  type        = bool
  default     = true
}

variable "scale_down_schedule" {
  description = "Cron expression for scaling down (evening)"
  type        = string
  default     = "0 18 * * MON-FRI"  # 6 PM weekdays

  validation {
    condition     = can(regex("^[0-9 */,-]+$", var.scale_down_schedule))
    error_message = "Scale down schedule must be a valid cron expression."
  }
}

variable "scale_up_schedule" {
  description = "Cron expression for scaling up (morning)"
  type        = string
  default     = "0 8 * * MON-FRI"   # 8 AM weekdays

  validation {
    condition     = can(regex("^[0-9 */,-]+$", var.scale_up_schedule))
    error_message = "Scale up schedule must be a valid cron expression."
  }
}

# Automation Variables
variable "enable_automated_optimization" {
  description = "Enable automated cost optimization via Lambda"
  type        = bool
  default     = true
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform     = "true"
    Purpose       = "lifecycle-management-demo"
    CostOptimized = "true"
    AutoManaged   = "true"
    Team          = "DevOps"
  }
}