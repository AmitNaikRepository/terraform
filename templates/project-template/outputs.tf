# Infrastructure outputs

output "project_info" {
  description = "Project information"
  value = {
    name        = var.project_name
    environment = var.environment
    region      = var.aws_region
    account_id  = data.aws_caller_identity.current.account_id
  }
}

# Networking outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "Availability zones used"
  value       = local.availability_zones
}

# Load balancer outputs

output "load_balancer_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the load balancer"
  value       = module.load_balancer.load_balancer_zone_id
}

output "load_balancer_arn" {
  description = "ARN of the load balancer"
  value       = module.load_balancer.load_balancer_arn
}

# Application outputs

output "application_url" {
  description = "URL to access the application"
  value       = "http://${module.load_balancer.load_balancer_dns_name}"
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.compute.auto_scaling_group_name
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.compute.auto_scaling_group_arn
}

# Security outputs

output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    load_balancer = module.security.load_balancer_security_group_id
    application   = module.security.application_security_group_id
    database      = module.security.database_security_group_id
  }
}

# Database outputs (conditional)

output "database_endpoint" {
  description = "Database endpoint (if database is enabled)"
  value       = var.enable_database ? module.database[0].endpoint : null
}

output "database_port" {
  description = "Database port (if database is enabled)"
  value       = var.enable_database ? module.database[0].port : null
}

# IAM outputs

output "instance_role_arn" {
  description = "ARN of the instance IAM role"
  value       = module.iam.instance_role_arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = module.iam.instance_profile_name
}

# Monitoring outputs (conditional)

output "monitoring_dashboard_url" {
  description = "URL of the CloudWatch dashboard (if monitoring is enabled)"
  value       = var.enable_monitoring ? module.monitoring[0].dashboard_url : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group (if monitoring is enabled)"
  value       = var.enable_monitoring ? module.monitoring[0].log_group_name : null
}

# Complete configuration object for external consumption

output "infrastructure_config" {
  description = "Complete infrastructure configuration object"
  value = {
    project = {
      name        = var.project_name
      environment = var.environment
      region      = var.aws_region
    }
    networking = {
      vpc_id             = module.vpc.vpc_id
      vpc_cidr           = module.vpc.vpc_cidr_block
      public_subnet_ids  = module.vpc.public_subnet_ids
      private_subnet_ids = module.vpc.private_subnet_ids
      availability_zones = local.availability_zones
    }
    application = {
      url                    = "http://${module.load_balancer.load_balancer_dns_name}"
      load_balancer_dns_name = module.load_balancer.load_balancer_dns_name
      auto_scaling_group_name = module.compute.auto_scaling_group_name
    }
    security = {
      load_balancer_sg = module.security.load_balancer_security_group_id
      application_sg   = module.security.application_security_group_id
      database_sg      = module.security.database_security_group_id
    }
    iam = {
      instance_role_arn     = module.iam.instance_role_arn
      instance_profile_name = module.iam.instance_profile_name
    }
    database = var.enable_database ? {
      endpoint = module.database[0].endpoint
      port     = module.database[0].port
    } : null
    monitoring = var.enable_monitoring ? {
      dashboard_url  = module.monitoring[0].dashboard_url
      log_group_name = module.monitoring[0].log_group_name
    } : null
  }
  sensitive = true  # Mark as sensitive to avoid logging credentials
}

# Environment-specific outputs

output "environment_config" {
  description = "Current environment configuration"
  value = {
    vpc_cidr              = local.current_config.vpc_cidr
    instance_type         = local.current_config.instance_type
    min_size             = local.current_config.min_size
    max_size             = local.current_config.max_size
    desired_capacity     = local.current_config.desired_capacity
    enable_private_subnets = local.current_config.enable_private_subnets
    enable_nat_gateway     = local.current_config.enable_nat_gateway
  }
}

# Tags output

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}