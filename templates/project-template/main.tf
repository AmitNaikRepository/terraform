# {PROJECT_NAME} Infrastructure
# Replace {PROJECT_NAME} with your actual project name

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  # Uncomment and configure backend after creating state infrastructure
  # backend "s3" {
  #   bucket         = "{your-terraform-state-bucket}"
  #   key            = "{project-name}/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "{your-terraform-locks-table}"
  #   encrypt        = true
  # }
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

# Local values for configuration and computed values
locals {
  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Use first 3 AZs for high availability
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)
  
  # Environment-specific configuration
  environment_config = {
    dev = {
      vpc_cidr              = "10.0.0.0/16"
      enable_private_subnets = false
      enable_nat_gateway     = false
      instance_type         = "t3.micro"
      min_size             = 1
      max_size             = 2
      desired_capacity     = 1
    }
    staging = {
      vpc_cidr              = "10.1.0.0/16"
      enable_private_subnets = true
      enable_nat_gateway     = true
      instance_type         = "t3.small"
      min_size             = 1
      max_size             = 3
      desired_capacity     = 2
    }
    prod = {
      vpc_cidr              = "10.2.0.0/16"
      enable_private_subnets = true
      enable_nat_gateway     = true
      instance_type         = "t3.medium"
      min_size             = 2
      max_size             = 10
      desired_capacity     = 3
    }
  }
  
  # Current environment configuration
  current_config = local.environment_config[var.environment]
  
  # Common tags for all resources
  common_tags = merge(var.default_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "terraform-fundamentals"
    Owner       = var.owner
    AccountId   = data.aws_caller_identity.current.account_id
  })
}

# Foundation Layer - Networking
module "vpc" {
  source = "./modules/vpc"

  name_prefix            = local.name_prefix
  vpc_cidr              = local.current_config.vpc_cidr
  availability_zones    = local.availability_zones
  enable_private_subnets = local.current_config.enable_private_subnets
  enable_nat_gateway     = local.current_config.enable_nat_gateway

  tags = merge(local.common_tags, {
    Layer     = "foundation"
    Component = "networking"
  })
}

# Foundation Layer - Security
module "security" {
  source = "./modules/security"

  name_prefix         = local.name_prefix
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  allowed_cidr_blocks = var.allowed_cidr_blocks

  tags = merge(local.common_tags, {
    Layer     = "foundation"
    Component = "security"
  })
}

# Foundation Layer - IAM
module "iam" {
  source = "./modules/iam"

  name_prefix  = local.name_prefix
  project_name = var.project_name
  environment  = var.environment

  tags = merge(local.common_tags, {
    Layer     = "foundation"
    Component = "iam"
  })
}

# Application Layer - Compute
module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = local.current_config.enable_private_subnets ? module.vpc.private_subnet_ids : module.vpc.public_subnet_ids
  security_group_ids = [module.security.application_security_group_id]

  # Compute configuration
  instance_type    = local.current_config.instance_type
  min_size        = local.current_config.min_size
  max_size        = local.current_config.max_size
  desired_capacity = local.current_config.desired_capacity

  # IAM configuration
  instance_profile_name = module.iam.instance_profile_name

  tags = merge(local.common_tags, {
    Layer     = "application"
    Component = "compute"
  })
}

# Application Layer - Load Balancer
module "load_balancer" {
  source = "./modules/load-balancer"

  name_prefix        = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_ids = [module.security.load_balancer_security_group_id]

  # Target configuration
  target_group_arn = module.compute.target_group_arn

  tags = merge(local.common_tags, {
    Layer     = "application"
    Component = "load-balancer"
  })
}

# Data Layer - Database (optional)
module "database" {
  count  = var.enable_database ? 1 : 0
  source = "./modules/database"

  name_prefix        = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = local.current_config.enable_private_subnets ? module.vpc.private_subnet_ids : module.vpc.public_subnet_ids
  security_group_ids = [module.security.database_security_group_id]

  # Database configuration
  engine         = var.database_config.engine
  engine_version = var.database_config.engine_version
  instance_class = var.database_config.instance_class
  
  # Multi-AZ for production
  multi_az = var.environment == "prod"

  tags = merge(local.common_tags, {
    Layer     = "data"
    Component = "database"
  })
}

# Platform Layer - Monitoring (optional)
module "monitoring" {
  count  = var.enable_monitoring ? 1 : 0
  source = "./modules/monitoring"

  name_prefix = local.name_prefix
  vpc_id     = module.vpc.vpc_id

  # Monitoring targets
  load_balancer_arn = module.load_balancer.load_balancer_arn
  auto_scaling_group_name = module.compute.auto_scaling_group_name

  tags = merge(local.common_tags, {
    Layer     = "platform"
    Component = "monitoring"
  })
}