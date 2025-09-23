# Replace {MODULE_NAME} with your actual module name
# Replace {DESCRIPTION} with your module description

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Local values for data transformation and computed values
locals {
  # Common naming prefix for all resources
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Common tags for all resources in this module
  common_tags = merge(var.tags, {
    Module      = "{MODULE_NAME}"
    Component   = "{COMPONENT_TYPE}"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })
  
  # Example computed values
  # availability_zones = slice(data.aws_availability_zones.available.names, 0, var.az_count)
}

# Data sources (if needed)
# data "aws_availability_zones" "available" {
#   state = "available"
# }

# Example resource - replace with your actual resources
resource "aws_s3_bucket" "example" {
  bucket = "${local.name_prefix}-{module-name}-bucket-${random_string.suffix.result}"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-{module-name}-bucket"
    Type = "storage"
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Additional resources go here...