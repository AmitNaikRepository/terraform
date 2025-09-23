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

output "security_group_ids" {
  description = "Security group IDs created"
  value = {
    web_security_group = module.security.web_security_group_id
  }
}

output "compute_config" {
  description = "Compute configuration details"
  value = {
    auto_scaling_group_name = module.compute.auto_scaling_group_name
    launch_template_id      = module.compute.launch_template_id
    target_group_arn       = module.compute.target_group_arn
  }
}

output "environment_config" {
  description = "Current environment configuration"
  value = {
    environment            = var.environment
    vpc_cidr              = local.current_config.vpc_cidr
    instance_type         = local.current_config.instance_type
    enable_private_subnets = local.current_config.enable_private_subnets
    enable_nat_gateway     = local.current_config.enable_nat_gateway
  }
}

# Structured output for easy consumption by other configurations
output "infrastructure_config" {
  description = "Complete infrastructure configuration"
  value = {
    networking = {
      vpc_id             = module.vpc.vpc_id
      public_subnet_ids  = module.vpc.public_subnet_ids
      private_subnet_ids = module.vpc.private_subnet_ids
      availability_zones = local.availability_zones
    }
    security = {
      web_security_group_id = module.security.web_security_group_id
    }
    compute = {
      auto_scaling_group_name = module.compute.auto_scaling_group_name
      launch_template_id      = module.compute.launch_template_id
    }
    environment = {
      name         = var.environment
      project_name = var.project_name
      region       = var.aws_region
    }
  }
}