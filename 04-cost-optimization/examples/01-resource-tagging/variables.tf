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
  description = "Name of the project (used in resource naming and cost allocation)"
  type        = string
  default     = "cost-optimization-demo"

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

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
  default     = "engineering"

  validation {
    condition     = length(var.cost_center) > 0
    error_message = "Cost center cannot be empty."
  }
}

variable "business_unit" {
  description = "Business unit responsible for costs"
  type        = string
  default     = "technology"

  validation {
    condition     = length(var.business_unit) > 0
    error_message = "Business unit cannot be empty."
  }
}

variable "owner" {
  description = "Owner of the resources (for cost responsibility)"
  type        = string
  default     = "devops-team"

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner cannot be empty."
  }
}

variable "application_name" {
  description = "Name of the application using these resources"
  type        = string
  default     = "terraform-fundamentals"

  validation {
    condition     = length(var.application_name) > 0
    error_message = "Application name cannot be empty."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "instance_type" {
  description = "EC2 instance type (affects cost)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t2.micro", "t2.small"], var.instance_type)
    error_message = "Instance type must be a valid cost-optimized type."
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (leave empty for latest Amazon Linux)"
  type        = string
  default     = ""
}

variable "volume_type" {
  description = "EBS volume type (affects cost)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.volume_type)
    error_message = "Volume type must be one of: gp2, gp3, io1, io2."
  }
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

variable "detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (additional cost)"
  type        = bool
  default     = false
}

variable "auto_shutdown_enabled" {
  description = "Enable automatic shutdown for cost savings"
  type        = bool
  default     = true
}

variable "shutdown_schedule" {
  description = "Shutdown schedule for cost optimization"
  type        = string
  default     = "weekdays-after-6pm"

  validation {
    condition     = contains(["none", "weekdays-after-6pm", "weekends", "daily-after-8pm"], var.shutdown_schedule)
    error_message = "Shutdown schedule must be a valid option."
  }
}

variable "backup_required" {
  description = "Whether backup is required (affects cost)"
  type        = bool
  default     = false
}

variable "management_cidr" {
  description = "CIDR block for management access"
  type        = string
  default     = "203.0.113.0/32"  # Example IP - replace with your actual IP

  validation {
    condition     = can(cidrhost(var.management_cidr, 0))
    error_message = "Management CIDR must be a valid CIDR block."
  }
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "50"

  validation {
    condition     = can(tonumber(var.monthly_budget_limit))
    error_message = "Monthly budget limit must be a valid number."
  }
}

variable "budget_notification_email" {
  description = "Email address for budget notifications"
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.budget_notification_email))
    error_message = "Budget notification email must be a valid email address."
  }
}

# Cost estimation variables
variable "estimated_monthly_cost_per_instance" {
  description = "Estimated monthly cost per EC2 instance in USD"
  type        = number
  default     = 8.50  # Approximate cost for t3.micro

  validation {
    condition     = var.estimated_monthly_cost_per_instance >= 0
    error_message = "Estimated monthly cost must be non-negative."
  }
}

variable "estimated_s3_monthly_cost" {
  description = "Estimated monthly S3 cost in USD"
  type        = number
  default     = 5.00

  validation {
    condition     = var.estimated_s3_monthly_cost >= 0
    error_message = "Estimated S3 monthly cost must be non-negative."
  }
}

variable "estimated_vpc_monthly_cost" {
  description = "Estimated monthly VPC cost in USD"
  type        = number
  default     = 2.00

  validation {
    condition     = var.estimated_vpc_monthly_cost >= 0
    error_message = "Estimated VPC monthly cost must be non-negative."
  }
}

variable "estimated_ebs_monthly_cost" {
  description = "Estimated monthly EBS cost in USD"
  type        = number
  default     = 2.00

  validation {
    condition     = var.estimated_ebs_monthly_cost >= 0
    error_message = "Estimated EBS monthly cost must be non-negative."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform    = "true"
    Purpose      = "cost-optimization-demo"
    Team         = "DevOps"
    CreatedBy    = "terraform"
    Learning     = "terraform-fundamentals"
  }
}