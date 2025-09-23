# Core project variables

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string

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

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region name."
  }
}

variable "owner" {
  description = "Owner of the infrastructure (for tagging)"
  type        = string
  default     = "Platform Team"
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Repository = "terraform-fundamentals"
  }
}

# Security variables

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"]  # Restrict this in production

  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All CIDR blocks must be valid IPv4 CIDR notation."
  }
}

# Optional feature flags

variable "enable_database" {
  description = "Enable database module"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring module"
  type        = bool
  default     = false
}

variable "enable_backup" {
  description = "Enable backup configuration"
  type        = bool
  default     = false
}

# Database configuration

variable "database_config" {
  description = "Database configuration object"
  type = object({
    engine         = string
    engine_version = string
    instance_class = string
  })
  default = {
    engine         = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
  }

  validation {
    condition = contains([
      "mysql", "postgres", "mariadb"
    ], var.database_config.engine)
    error_message = "Database engine must be one of: mysql, postgres, mariadb."
  }
}

# Application configuration

variable "application_config" {
  description = "Application-specific configuration"
  type = object({
    port              = number
    health_check_path = string
    protocol          = string
  })
  default = {
    port              = 8080
    health_check_path = "/health"
    protocol          = "HTTP"
  }

  validation {
    condition     = var.application_config.port >= 1 && var.application_config.port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.application_config.protocol)
    error_message = "Protocol must be HTTP or HTTPS."
  }
}

# Notification configuration

variable "notification_config" {
  description = "Notification configuration for alerts"
  type = object({
    email_addresses = list(string)
    slack_webhook   = string
  })
  default = {
    email_addresses = []
    slack_webhook   = ""
  }

  validation {
    condition = alltrue([
      for email in var.notification_config.email_addresses : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All email addresses must be valid email format."
  }
}

# Cost optimization

variable "cost_optimization" {
  description = "Cost optimization settings"
  type = object({
    enable_spot_instances = bool
    schedule_scaling      = bool
    lifecycle_policies    = bool
  })
  default = {
    enable_spot_instances = false
    schedule_scaling      = false
    lifecycle_policies    = true
  }
}

# Backup configuration

variable "backup_config" {
  description = "Backup configuration settings"
  type = object({
    retention_days      = number
    backup_window      = string
    maintenance_window = string
    enable_cross_region = bool
  })
  default = {
    retention_days      = 7
    backup_window      = "03:00-04:00"
    maintenance_window = "sun:04:00-sun:05:00"
    enable_cross_region = false
  }

  validation {
    condition     = var.backup_config.retention_days >= 1 && var.backup_config.retention_days <= 35
    error_message = "Backup retention must be between 1 and 35 days."
  }
}