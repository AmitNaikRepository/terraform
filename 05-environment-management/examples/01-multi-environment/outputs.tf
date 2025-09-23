output "vpc_id" {
  description = "ID of the VPC for this environment"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "load_balancer_url" {
  description = "HTTPS URL of the Application Load Balancer"
  value       = "https://${aws_lb.web.dns_name}"
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "database_endpoint" {
  description = "RDS instance endpoint"
  value       = var.create_database ? aws_db_instance.main[0].endpoint : null
  sensitive   = true
}

output "ssl_certificate_arn" {
  description = "ARN of the SSL certificate"
  value       = aws_acm_certificate.web.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.app_logs.name
}

# Environment Configuration Summary
output "environment_configuration" {
  description = "Summary of environment-specific configuration"
  value = {
    environment = var.environment
    
    infrastructure = {
      vpc_cidr          = local.vpc_cidr
      instance_type     = local.env_config.instance_type
      multi_az          = local.env_config.multi_az
      nat_gateway       = var.environment != "dev"
      ssl_policy        = local.env_config.ssl_policy
    }
    
    scaling = {
      min_size         = local.env_config.min_size
      max_size         = local.env_config.max_size
      desired_capacity = local.env_config.desired_capacity
    }
    
    storage = {
      volume_size      = local.env_config.volume_size
      encryption       = var.environment == "prod"
      backup_enabled   = local.env_config.enable_backup
      retention_days   = local.env_config.retention_days
    }
    
    database = {
      instance_class   = local.env_config.database_size
      multi_az         = local.env_config.multi_az
      backup_retention = local.env_config.retention_days
      encryption       = var.environment == "prod"
      monitoring       = local.env_config.enable_monitoring
    }
    
    security = {
      ssh_access_enabled    = var.environment != "prod"
      deletion_protection   = var.environment == "prod"
      enhanced_monitoring   = local.env_config.enable_monitoring
      ssl_certificate       = true
    }
    
    monitoring_and_logging = {
      detailed_monitoring   = local.env_config.enable_monitoring
      alb_access_logs      = local.env_config.enable_monitoring
      cloudwatch_logs      = true
      log_retention_days   = local.env_config.retention_days
      rds_enhanced_monitoring = local.env_config.enable_monitoring
    }
  }
}

# Environment Comparison
output "environment_comparison" {
  description = "Comparison of configurations across environments"
  value = {
    dev = {
      focus               = "Development and testing"
      cost_optimization   = "Maximum cost savings"
      instance_type       = "t3.micro"
      multi_az           = false
      nat_gateway        = false
      monitoring         = "Basic CloudWatch only"
      backup             = "No backups"
      ssl_policy         = "Basic SSL policy"
      deletion_protection = false
      ssh_access         = "Enabled for debugging"
      retention_days     = 7
    }
    
    staging = {
      focus               = "Pre-production testing and validation"
      cost_optimization   = "Balanced cost and reliability"
      instance_type       = "t3.small"
      multi_az           = true
      nat_gateway        = true
      monitoring         = "Enhanced monitoring enabled"
      backup             = "Daily backups with 30-day retention"
      ssl_policy         = "TLS 1.2 minimum"
      deletion_protection = false
      ssh_access         = "Enabled for troubleshooting"
      retention_days     = 30
    }
    
    prod = {
      focus               = "Production workloads"
      cost_optimization   = "Performance and reliability over cost"
      instance_type       = "t3.medium"
      multi_az           = true
      nat_gateway        = true
      monitoring         = "Full monitoring and logging"
      backup             = "Daily backups with 90-day retention"
      ssl_policy         = "TLS 1.2 minimum"
      deletion_protection = true
      ssh_access         = "Disabled for security"
      retention_days     = 90
    }
  }
}

# Resource Naming Convention
output "resource_naming" {
  description = "Resource naming convention used in this environment"
  value = {
    pattern = "${var.project_name}-${var.environment}-{resource-type}"
    examples = {
      vpc                = "${var.project_name}-${var.environment}-vpc"
      subnet             = "${var.project_name}-${var.environment}-public-subnet-1"
      security_group     = "${var.project_name}-${var.environment}-web-sg"
      auto_scaling_group = "${var.project_name}-${var.environment}-web-asg"
      load_balancer      = "${var.project_name}-${var.environment}-alb"
      database           = "${var.project_name}-${var.environment}-database"
      s3_bucket          = "${var.project_name}-${var.environment}-alb-logs-${random_string.bucket_suffix.result}"
    }
    
    tagging_strategy = {
      required_tags = [
        "Environment: ${var.environment}",
        "Project: ${var.project_name}",
        "Terraform: true"
      ]
      environment_specific_tags = [
        "CostCenter: ${var.environment == "prod" ? "production" : "development"}",
        "Backup: ${local.env_config.enable_backup ? "enabled" : "disabled"}",
        "Monitoring: ${local.env_config.enable_monitoring ? "enabled" : "basic"}"
      ]
    }
  }
}

# Security Configuration
output "security_configuration" {
  description = "Security settings for this environment"
  value = {
    network_security = {
      vpc_isolation       = "Dedicated VPC per environment"
      subnet_segmentation = "Public, private, and database tiers"
      nat_gateway        = var.environment != "dev" ? "Enabled for outbound internet access" : "Disabled to reduce costs"
      security_groups    = "Tier-specific security groups with minimal access"
    }
    
    access_control = {
      ssh_access         = var.environment == "prod" ? "Disabled" : "Enabled from management CIDR"
      database_access    = "Private subnets only, no public access"
      load_balancer     = "Public HTTPS/HTTP access with SSL redirect"
      ssl_termination   = "At load balancer with ACM certificate"
    }
    
    data_protection = {
      encryption_at_rest = var.environment == "prod" ? "Enabled" : "Disabled"
      ssl_in_transit    = "Enabled with TLS 1.2+"
      deletion_protection = var.environment == "prod" ? "Enabled" : "Disabled"
      backup_encryption  = var.environment == "prod" ? "Enabled" : "Disabled"
    }
  }
}

# Cost Optimization
output "cost_optimization" {
  description = "Cost optimization strategies by environment"
  value = {
    current_environment = var.environment
    
    dev_optimizations = [
      "Single AZ deployment to reduce NAT Gateway costs",
      "No NAT Gateway - instances use public subnets when needed",
      "Basic monitoring only (no enhanced monitoring)",
      "No automated backups",
      "Smallest instance types (t3.micro)",
      "No encryption to avoid KMS costs",
      "Short log retention (7 days)"
    ]
    
    staging_optimizations = [
      "Production-like setup but smaller instance types",
      "Enhanced monitoring for testing but shorter retention",
      "Multi-AZ for testing availability patterns",
      "30-day backup retention vs 90 days in prod"
    ]
    
    production_investments = [
      "Multi-AZ for high availability",
      "Enhanced monitoring for operational visibility",
      "90-day backup retention for compliance",
      "Encryption for data protection",
      "Larger instances for performance",
      "Deletion protection to prevent accidental data loss"
    ]
    
    estimated_monthly_costs = {
      dev     = "~$50-80 (optimized for cost)"
      staging = "~$150-200 (balanced approach)"
      prod    = "~$300-500 (optimized for reliability)"
    }
  }
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Instructions for deploying to this environment"
  value = {
    prerequisites = [
      "Configure AWS credentials for target account",
      "Set environment variables: TF_VAR_environment=${var.environment}",
      "Set database password: TF_VAR_db_password=<secure-password>",
      "Update domain_name variable for your domain"
    ]
    
    deployment_commands = {
      init    = "terraform init"
      plan    = "terraform plan -var=\"environment=${var.environment}\""
      apply   = "terraform apply -var=\"environment=${var.environment}\""
      destroy = "terraform destroy -var=\"environment=${var.environment}\""
    }
    
    environment_specific_notes = {
      dev = [
        "Fastest deployment with minimal resources",
        "No NAT Gateway reduces cost but limits private subnet internet access",
        "SSH access enabled for development and debugging"
      ]
      staging = [
        "Production-like setup for testing",
        "All production features enabled but with smaller scale",
        "Ideal for integration testing and performance validation"
      ]
      prod = [
        "Full production configuration with high availability",
        "Deletion protection enabled - requires manual removal for destruction",
        "Enhanced monitoring and logging for operational visibility"
      ]
    }
  }
}

# Monitoring and Alerting
output "monitoring_setup" {
  description = "Monitoring and alerting configuration for this environment"
  value = {
    cloudwatch_logs = {
      application_logs = aws_cloudwatch_log_group.app_logs.name
      retention_days   = local.env_config.retention_days
      log_streams      = ["application", "access", "error"]
    }
    
    load_balancer_monitoring = {
      access_logs_enabled = local.env_config.enable_monitoring
      metrics_available   = [
        "RequestCount",
        "TargetResponseTime",
        "HTTPCode_Target_2XX_Count",
        "HTTPCode_Target_4XX_Count",
        "HTTPCode_Target_5XX_Count"
      ]
    }
    
    database_monitoring = {
      enhanced_monitoring = local.env_config.enable_monitoring
      cloudwatch_logs     = local.env_config.enable_monitoring ? ["error", "general", "slow-query"] : []
      backup_monitoring   = local.env_config.enable_backup
    }
    
    recommended_alarms = [
      "ALB 4XX/5XX error rate > 5%",
      "ALB response time > 2 seconds",
      "ASG instances unhealthy",
      "RDS CPU utilization > 80%",
      "RDS database connections > 80% of max"
    ]
  }
}