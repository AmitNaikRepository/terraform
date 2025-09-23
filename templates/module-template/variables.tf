# Core module variables

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

variable "tags" {
  description = "Tags to apply to all resources created by this module"
  type        = map(string)
  default     = {}
}

# Module-specific variables

variable "name_prefix" {
  description = "Prefix for naming resources (optional, will default to project-environment)"
  type        = string
  default     = null
}

# Example variables - replace with your module's actual variables

variable "example_setting" {
  description = "Example configuration setting"
  type        = string
  default     = "default-value"

  validation {
    condition     = contains(["option1", "option2", "option3"], var.example_setting)
    error_message = "Example setting must be one of: option1, option2, option3."
  }
}

variable "enable_feature" {
  description = "Enable optional feature"
  type        = bool
  default     = false
}

variable "configuration_object" {
  description = "Complex configuration object"
  type = object({
    setting1 = string
    setting2 = number
    setting3 = bool
  })
  default = {
    setting1 = "default"
    setting2 = 10
    setting3 = true
  }

  validation {
    condition     = var.configuration_object.setting2 > 0
    error_message = "Setting2 must be greater than 0."
  }
}

variable "optional_list" {
  description = "Optional list of items"
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.optional_list) <= 10
    error_message = "Optional list cannot contain more than 10 items."
  }
}