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
  default     = "multi-env-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "domain_name" {
  description = "Base domain name for the application"
  type        = string
  default     = "example.com"

  validation {
    condition     = can(regex("^[a-z0-9.-]+\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "management_cidr" {
  description = "CIDR block for management access (SSH, etc.)"
  type        = string
  default     = "203.0.113.0/32"  # Example IP - replace with your actual IP

  validation {
    condition     = can(cidrhost(var.management_cidr, 0))
    error_message = "Management CIDR must be a valid CIDR block."
  }
}

variable "app_port" {
  description = "Port number for the application"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port > 1024 && var.app_port < 65536
    error_message = "Application port must be between 1024 and 65535."
  }
}

# Database Configuration
variable "create_database" {
  description = "Whether to create RDS database instance"
  type        = bool
  default     = true
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "admin"

  validation {
    condition     = length(var.db_username) >= 1 && length(var.db_username) <= 16
    error_message = "Database username must be between 1 and 16 characters."
  }
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# Environment-specific overrides (optional)
variable "instance_type_override" {
  description = "Override instance type for specific environment testing"
  type        = string
  default     = null

  validation {
    condition     = var.instance_type_override == null || contains(["t3.micro", "t3.small", "t3.medium", "t3.large"], var.instance_type_override)
    error_message = "Instance type override must be a valid EC2 instance type."
  }
}

variable "enable_nat_gateway_override" {
  description = "Override NAT Gateway creation for cost control in dev"
  type        = bool
  default     = null
}

variable "enable_monitoring_override" {
  description = "Override monitoring settings for specific environments"
  type        = bool
  default     = null
}

variable "backup_retention_override" {
  description = "Override backup retention days for specific environments"
  type        = number
  default     = null

  validation {
    condition     = var.backup_retention_override == null || (var.backup_retention_override >= 0 && var.backup_retention_override <= 35)
    error_message = "Backup retention override must be between 0 and 35 days."
  }
}

# Default tags - environment-specific tags are added in locals
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Purpose     = "multi-environment-demo"
    Repository  = "terraform-fundamentals"
    Team        = "DevOps"
    CreatedBy   = "terraform"
  }

  validation {
    condition     = contains(keys(var.default_tags), "Terraform")
    error_message = "Default tags must include 'Terraform' key."
  }
}