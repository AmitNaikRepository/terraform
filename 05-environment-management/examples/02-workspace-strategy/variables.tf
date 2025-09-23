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
  description = "Name of the project (used in resource naming and workspace identification)"
  type        = string
  default     = "workspace-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
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

variable "ami_id" {
  description = "AMI ID for EC2 instances (leave empty for latest Amazon Linux)"
  type        = string
  default     = ""
}

# Workspace-specific overrides
variable "workspace_instance_type_override" {
  description = "Override instance type for current workspace"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.workspace_instance_type_override : contains(["t3.micro", "t3.small", "t3.medium", "t3.large"], v)
    ])
    error_message = "All instance type overrides must be valid EC2 instance types."
  }
}

variable "workspace_monitoring_override" {
  description = "Override monitoring settings per workspace"
  type        = map(bool)
  default     = {}
}

variable "workspace_multi_az_override" {
  description = "Override multi-AZ settings per workspace"
  type        = map(bool)
  default     = {}
}

# Backend configuration variables
variable "state_bucket" {
  description = "S3 bucket for Terraform state storage"
  type        = string
  default     = ""

  validation {
    condition     = var.state_bucket == "" || can(regex("^[a-z0-9-]+$", var.state_bucket))
    error_message = "State bucket must be empty or a valid S3 bucket name."
  }
}

variable "state_dynamodb_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.state_dynamodb_table))
    error_message = "DynamoDB table name must be valid."
  }
}

# Default tags that will be merged with workspace-specific tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform        = "true"
    Purpose          = "workspace-strategy-demo"
    Repository       = "terraform-fundamentals"
    Team             = "DevOps"
    ManagementMethod = "terraform-workspaces"
  }

  validation {
    condition     = contains(keys(var.default_tags), "Terraform")
    error_message = "Default tags must include 'Terraform' key."
  }
}