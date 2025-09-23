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
  default     = "security-groups-demo"

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
  description = "CIDR block for management access (replace with your public IP/32)"
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

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Purpose     = "security-groups-demo"
    Owner       = "Security Team"
    Environment = "learning"
  }
}