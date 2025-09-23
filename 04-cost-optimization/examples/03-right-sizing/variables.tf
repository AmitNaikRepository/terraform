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
  default     = "right-sizing-demo"

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

variable "management_cidr" {
  description = "CIDR block for management access"
  type        = string
  default     = "203.0.113.0/32"  # Example IP - replace with your actual IP

  validation {
    condition     = can(cidrhost(var.management_cidr, 0))
    error_message = "Management CIDR must be a valid CIDR block."
  }
}

# Web Tier Configuration
variable "web_tier_instance_type" {
  description = "Instance type for web tier (optimized for HTTP serving)"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.nano", "t3.micro", "t3.small", "t3.medium"], var.web_tier_instance_type)
    error_message = "Web tier instance type must be a cost-optimized type suitable for web serving."
  }
}

variable "web_tier_count" {
  description = "Number of instances in web tier"
  type        = number
  default     = 2

  validation {
    condition     = var.web_tier_count >= 1 && var.web_tier_count <= 5
    error_message = "Web tier count must be between 1 and 5."
  }
}

variable "web_tier_min_size" {
  description = "Minimum instances in web tier ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.web_tier_min_size >= 1 && var.web_tier_min_size <= 5
    error_message = "Web tier minimum size must be between 1 and 5."
  }
}

variable "web_tier_max_size" {
  description = "Maximum instances in web tier ASG"
  type        = number
  default     = 4

  validation {
    condition     = var.web_tier_max_size >= 2 && var.web_tier_max_size <= 10
    error_message = "Web tier maximum size must be between 2 and 10."
  }
}

variable "web_tier_volume_size" {
  description = "EBS volume size for web tier instances (GB)"
  type        = number
  default     = 20

  validation {
    condition     = var.web_tier_volume_size >= 8 && var.web_tier_volume_size <= 50
    error_message = "Web tier volume size must be between 8 and 50 GB."
  }
}

# Application Tier Configuration
variable "app_tier_instance_type" {
  description = "Instance type for application tier (optimized for business logic)"
  type        = string
  default     = "t3.small"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t3.large"], var.app_tier_instance_type)
    error_message = "App tier instance type must be suitable for application processing."
  }
}

variable "app_tier_count" {
  description = "Number of instances in application tier"
  type        = number
  default     = 2

  validation {
    condition     = var.app_tier_count >= 1 && var.app_tier_count <= 5
    error_message = "App tier count must be between 1 and 5."
  }
}

variable "app_tier_min_size" {
  description = "Minimum instances in application tier ASG"
  type        = number
  default     = 1

  validation {
    condition     = var.app_tier_min_size >= 1 && var.app_tier_min_size <= 5
    error_message = "App tier minimum size must be between 1 and 5."
  }
}

variable "app_tier_max_size" {
  description = "Maximum instances in application tier ASG"
  type        = number
  default     = 5

  validation {
    condition     = var.app_tier_max_size >= 2 && var.app_tier_max_size <= 10
    error_message = "App tier maximum size must be between 2 and 10."
  }
}

variable "app_tier_volume_size" {
  description = "EBS volume size for application tier instances (GB)"
  type        = number
  default     = 30

  validation {
    condition     = var.app_tier_volume_size >= 20 && var.app_tier_volume_size <= 100
    error_message = "App tier volume size must be between 20 and 100 GB."
  }
}

# Worker Tier Configuration
variable "worker_tier_instance_type" {
  description = "Instance type for worker tier (optimized for background processing)"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = contains(["t3.small", "t3.medium", "t3.large", "t3.xlarge"], var.worker_tier_instance_type)
    error_message = "Worker tier instance type must be suitable for background processing."
  }
}

variable "worker_tier_count" {
  description = "Number of instances in worker tier"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_tier_count >= 0 && var.worker_tier_count <= 3
    error_message = "Worker tier count must be between 0 and 3."
  }
}

variable "worker_tier_min_size" {
  description = "Minimum instances in worker tier ASG"
  type        = number
  default     = 0

  validation {
    condition     = var.worker_tier_min_size >= 0 && var.worker_tier_min_size <= 3
    error_message = "Worker tier minimum size must be between 0 and 3."
  }
}

variable "worker_tier_max_size" {
  description = "Maximum instances in worker tier ASG"
  type        = number
  default     = 3

  validation {
    condition     = var.worker_tier_max_size >= 1 && var.worker_tier_max_size <= 5
    error_message = "Worker tier maximum size must be between 1 and 5."
  }
}

variable "worker_tier_volume_size" {
  description = "EBS volume size for worker tier instances (GB)"
  type        = number
  default     = 40

  validation {
    condition     = var.worker_tier_volume_size >= 20 && var.worker_tier_volume_size <= 200
    error_message = "Worker tier volume size must be between 20 and 200 GB."
  }
}

# Monitoring Configuration
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (additional cost)"
  type        = bool
  default     = false
}

# Default tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform     = "true"
    Purpose       = "right-sizing-demo"
    CostOptimized = "true"
    RightSized    = "true"
    Team          = "DevOps"
  }
}