terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values for configuration
locals {
  # Environment-specific configuration
  environment_config = {
    dev = {
      vpc_cidr              = "10.0.0.0/16"
      enable_private_subnets = false
      enable_nat_gateway     = false
      instance_type         = "t3.micro"
    }
    staging = {
      vpc_cidr              = "10.1.0.0/16"
      enable_private_subnets = true
      enable_nat_gateway     = true
      instance_type         = "t3.small"
    }
    prod = {
      vpc_cidr              = "10.2.0.0/16"
      enable_private_subnets = true
      enable_nat_gateway     = true
      instance_type         = "t3.medium"
    }
  }

  # Select configuration for current environment
  current_config = local.environment_config[var.environment]

  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Use up to 3 AZs for high availability
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # Common tags for all resources
  common_tags = merge(var.default_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "terraform-fundamentals"
  })
}

# VPC Module - Network Foundation Layer
module "vpc" {
  source = "./modules/vpc"

  name_prefix            = local.name_prefix
  vpc_cidr              = local.current_config.vpc_cidr
  availability_zones    = local.availability_zones
  enable_private_subnets = local.current_config.enable_private_subnets
  enable_nat_gateway     = local.current_config.enable_nat_gateway

  tags = merge(local.common_tags, {
    Layer = "foundation"
    Type  = "networking"
  })
}

# Security Module - Security Foundation Layer
module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr_block

  # Security configuration
  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_ssh_access   = var.enable_ssh_access

  tags = merge(local.common_tags, {
    Layer = "foundation"
    Type  = "security"
  })
}

# Compute Module - Application Layer
module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_ids = [module.security.web_security_group_id]

  # Compute configuration
  instance_type    = local.current_config.instance_type
  min_size        = var.min_size
  max_size        = var.max_size
  desired_capacity = var.desired_capacity

  # Application configuration
  application_port = var.application_port
  health_check_path = var.health_check_path

  tags = merge(local.common_tags, {
    Layer = "application"
    Type  = "compute"
  })
}