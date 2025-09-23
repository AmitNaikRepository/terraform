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
  default     = "promotion-demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

# Source Configuration
variable "github_repo" {
  description = "GitHub repository in format 'owner/repo' (leave empty to use CodeCommit)"
  type        = string
  default     = ""

  validation {
    condition     = var.github_repo == "" || can(regex("^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$", var.github_repo))
    error_message = "GitHub repo must be in format 'owner/repo' or empty."
  }
}

variable "github_token" {
  description = "GitHub personal access token (required if using GitHub)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "codecommit_repo_name" {
  description = "CodeCommit repository name (used if GitHub repo is not specified)"
  type        = string
  default     = "terraform-infrastructure"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.codecommit_repo_name))
    error_message = "CodeCommit repository name must be valid."
  }
}

variable "source_branch" {
  description = "Source branch to monitor for changes"
  type        = string
  default     = "main"

  validation {
    condition     = length(var.source_branch) > 0
    error_message = "Source branch cannot be empty."
  }
}

# Pipeline Configuration
variable "notification_email" {
  description = "Email address for pipeline notifications"
  type        = string
  default     = ""

  validation {
    condition     = var.notification_email == "" || can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.notification_email))
    error_message = "Notification email must be a valid email address or empty."
  }
}

variable "enable_manual_approvals" {
  description = "Enable manual approval steps in the pipeline"
  type        = bool
  default     = true
}

variable "enable_integration_tests" {
  description = "Enable integration testing stage"
  type        = bool
  default     = true
}

# Environment-specific Configuration
variable "environments" {
  description = "List of environments to deploy to in order"
  type        = list(string)
  default     = ["dev", "staging", "prod"]

  validation {
    condition     = length(var.environments) >= 1 && length(var.environments) <= 5
    error_message = "Must specify 1-5 environments."
  }

  validation {
    condition = alltrue([
      for env in var.environments : contains(["dev", "staging", "prod", "test", "demo"], env)
    ])
    error_message = "All environments must be one of: dev, staging, prod, test, demo."
  }
}

variable "deployment_timeout" {
  description = "Timeout for deployment stages in minutes"
  type        = number
  default     = 60

  validation {
    condition     = var.deployment_timeout >= 5 && var.deployment_timeout <= 480
    error_message = "Deployment timeout must be between 5 and 480 minutes."
  }
}

# Build Configuration
variable "codebuild_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"

  validation {
    condition = contains([
      "BUILD_GENERAL1_SMALL",
      "BUILD_GENERAL1_MEDIUM", 
      "BUILD_GENERAL1_LARGE"
    ], var.codebuild_compute_type)
    error_message = "CodeBuild compute type must be a valid option."
  }
}

variable "terraform_version" {
  description = "Terraform version to use in builds"
  type        = string
  default     = "1.5.0"

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.terraform_version))
    error_message = "Terraform version must be in format X.Y.Z."
  }
}

# Security Configuration
variable "enable_artifact_encryption" {
  description = "Enable encryption for pipeline artifacts"
  type        = bool
  default     = true
}

variable "enable_resource_scanning" {
  description = "Enable security scanning of Terraform resources"
  type        = bool
  default     = true
}

# Default tags
variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform    = "true"
    Purpose      = "promotion-pipeline-demo"
    Repository   = "terraform-fundamentals"
    Team         = "DevOps"
    Pipeline     = "automated"
    CostCenter   = "engineering"
  }

  validation {
    condition     = contains(keys(var.default_tags), "Terraform")
    error_message = "Default tags must include 'Terraform' key."
  }
}