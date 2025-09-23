output "current_workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "resolved_environment" {
  description = "Environment resolved from workspace"
  value       = local.environment
}

output "vpc_id" {
  description = "ID of the VPC for current workspace"
  value       = aws_vpc.workspace_demo.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.workspace_demo.cidr_block
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "load_balancer_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.web.dns_name}"
}

output "s3_bucket_name" {
  description = "Name of the workspace-specific S3 bucket"
  value       = aws_s3_bucket.workspace_demo.bucket
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "lambda_function_name" {
  description = "Name of the workspace manager Lambda function"
  value       = aws_lambda_function.workspace_manager.function_name
}

output "ssm_parameter_name" {
  description = "SSM parameter storing workspace configuration"
  value       = aws_ssm_parameter.workspace_config.name
}

# Workspace Strategy Information
output "workspace_strategy" {
  description = "Comprehensive workspace strategy information"
  value = {
    current_workspace = terraform.workspace
    workspace_type = terraform.workspace == "default" ? "development" : terraform.workspace
    environment = local.environment
    
    workspace_mapping = {
      default = "dev (default workspace)"
      dev     = "development"
      staging = "staging/pre-production"
      prod    = "production"
      test    = "testing/experimental"
    }
    
    state_isolation = {
      method = "terraform-workspaces"
      state_key = "workspace-strategy/terraform.tfstate"
      workspace_state = "separate state files per workspace"
      current_state_path = "workspace-strategy/env:/${terraform.workspace}/terraform.tfstate"
    }
    
    resource_isolation = {
      naming_strategy = "${var.project_name}-${terraform.workspace}-{resource}"
      vpc_cidr_strategy = "unique CIDR per workspace"
      tagging_strategy = "workspace and environment tags on all resources"
    }
  }
}

# Workspace Configuration Comparison
output "workspace_configurations" {
  description = "Comparison of configurations across all workspaces"
  value = {
    dev_default = {
      workspace_name    = "default or dev"
      instance_type     = "t3.micro"
      scaling          = "1-2 instances"
      multi_az         = false
      monitoring       = false
      nat_gateway      = false
      vpc_cidr         = "10.0.0.0/16 or 10.1.0.0/16"
      cost_focus       = "Maximum cost optimization"
      use_case         = "Development and testing"
    }
    
    staging = {
      workspace_name    = "staging"
      instance_type     = "t3.small"
      scaling          = "2-4 instances"
      multi_az         = true
      monitoring       = true
      nat_gateway      = true
      vpc_cidr         = "10.2.0.0/16"
      cost_focus       = "Balanced cost and performance"
      use_case         = "Pre-production testing"
    }
    
    prod = {
      workspace_name    = "prod"
      instance_type     = "t3.medium"
      scaling          = "3-10 instances"
      multi_az         = true
      monitoring       = true
      nat_gateway      = true
      vpc_cidr         = "10.3.0.0/16"
      cost_focus       = "Performance and reliability"
      use_case         = "Production workloads"
    }
    
    test = {
      workspace_name    = "test"
      instance_type     = "t3.micro"
      scaling          = "1 instance"
      multi_az         = false
      monitoring       = false
      nat_gateway      = false
      vpc_cidr         = "10.4.0.0/16"
      cost_focus       = "Ultra-low cost"
      use_case         = "Experimental features"
    }
  }
}

# Current Workspace Details
output "current_workspace_details" {
  description = "Detailed configuration for the current workspace"
  value = {
    workspace_info = {
      name              = terraform.workspace
      environment       = local.environment
      vpc_cidr          = local.vpc_cidr
      name_prefix       = local.name_prefix
    }
    
    infrastructure = {
      instance_type     = local.current_config.instance_type
      min_instances     = local.current_config.min_size
      max_instances     = local.current_config.max_size
      desired_instances = local.current_config.desired_capacity
      volume_size       = local.current_config.volume_size
      multi_az         = local.current_config.multi_az
    }
    
    features = {
      monitoring_enabled    = local.current_config.enable_monitoring
      nat_gateway_enabled   = terraform.workspace == "prod" || terraform.workspace == "staging"
      ssh_access_enabled    = terraform.workspace != "prod"
      encryption_enabled    = terraform.workspace == "prod"
      deletion_protection   = terraform.workspace == "prod"
      instance_protection   = terraform.workspace == "prod"
    }
    
    retention_policies = {
      backup_retention_days = local.current_config.backup_retention
      log_retention_days    = local.current_config.log_retention
      s3_versioning        = terraform.workspace == "prod" ? "enabled" : "suspended"
    }
  }
}

# Workspace Management Commands
output "workspace_commands" {
  description = "Terraform workspace management commands"
  value = {
    list_workspaces = "terraform workspace list"
    show_current    = "terraform workspace show"
    create_new      = {
      dev     = "terraform workspace new dev"
      staging = "terraform workspace new staging"
      prod    = "terraform workspace new prod"
      test    = "terraform workspace new test"
    }
    switch_workspace = {
      to_dev     = "terraform workspace select dev"
      to_staging = "terraform workspace select staging"
      to_prod    = "terraform workspace select prod"
      to_default = "terraform workspace select default"
    }
    delete_workspace = {
      warning = "terraform workspace delete <name> (only when workspace is empty)"
      example = "terraform workspace delete test"
    }
  }
}

# Deployment Workflow
output "deployment_workflow" {
  description = "Recommended deployment workflow using workspaces"
  value = {
    initial_setup = [
      "1. terraform init (initialize with backend configuration)",
      "2. terraform workspace list (check available workspaces)",
      "3. terraform workspace new dev (create development workspace)",
      "4. terraform plan (review plan for dev workspace)",
      "5. terraform apply (deploy to dev workspace)"
    ]
    
    environment_promotion = [
      "1. terraform workspace select staging",
      "2. terraform plan (review staging configuration)",
      "3. terraform apply (deploy to staging)",
      "4. # Test and validate in staging",
      "5. terraform workspace select prod",
      "6. terraform plan (review production configuration)",
      "7. terraform apply (deploy to production)"
    ]
    
    feature_development = [
      "1. terraform workspace new feature-branch-name",
      "2. terraform plan (isolated environment for feature)",
      "3. terraform apply (test feature changes)",
      "4. # Complete feature development and testing",
      "5. terraform destroy (clean up feature workspace)",
      "6. terraform workspace delete feature-branch-name"
    ]
    
    best_practices = [
      "Always check current workspace before applying changes",
      "Use workspace-specific tfvars files for environment-specific values",
      "Implement proper state locking with DynamoDB",
      "Tag all resources with workspace and environment information",
      "Use workspace-aware CIDR blocks to prevent conflicts"
    ]
  }
}

# State Management
output "state_management" {
  description = "State management strategy for workspaces"
  value = {
    backend_type = "S3 with workspace isolation"
    state_isolation = {
      method          = "Terraform workspaces create separate state files"
      state_key_pattern = "workspace-strategy/env:/{workspace}/terraform.tfstate"
      current_state_key = "workspace-strategy/env:/${terraform.workspace}/terraform.tfstate"
    }
    
    state_locking = {
      enabled         = "DynamoDB table for concurrent access protection"
      table_name      = var.state_dynamodb_table
      lock_key        = "workspace-strategy/env:/${terraform.workspace}/terraform.tfstate"
    }
    
    workspace_benefits = [
      "Complete state isolation between environments",
      "Same configuration code across all environments",
      "Easy environment switching with terraform workspace commands",
      "Reduced risk of cross-environment changes",
      "Simplified CI/CD pipeline integration"
    ]
    
    workspace_limitations = [
      "All workspaces share the same backend configuration",
      "Limited to single backend type per configuration",
      "Workspace names must be known in advance for some operations",
      "State file location depends on workspace name",
      "Difficult to share resources between workspaces"
    ]
  }
}

# Security Considerations
output "security_considerations" {
  description = "Security aspects of workspace strategy"
  value = {
    isolation_benefits = [
      "Complete resource isolation between workspaces",
      "Separate VPCs with unique CIDR blocks prevent network conflicts",
      "Workspace-specific security groups and access controls",
      "Environment-specific encryption and protection settings"
    ]
    
    access_control = {
      workspace_access = "IAM permissions can be scoped per workspace"
      state_access     = "S3 bucket policies can restrict workspace state access"
      resource_access  = "Resources tagged with workspace for access control"
    }
    
    production_protections = {
      deletion_protection  = terraform.workspace == "prod" ? "enabled" : "disabled"
      instance_protection  = terraform.workspace == "prod" ? "enabled" : "disabled"
      ssh_access          = terraform.workspace == "prod" ? "disabled" : "enabled"
      enhanced_monitoring  = terraform.workspace == "prod" ? "enabled" : "basic"
    }
  }
}

# Cost Analysis
output "cost_analysis" {
  description = "Cost implications of workspace strategy"
  value = {
    current_workspace_cost = {
      workspace     = terraform.workspace
      estimated_monthly = terraform.workspace == "prod" ? "$200-400" : 
                         terraform.workspace == "staging" ? "$100-200" : 
                         terraform.workspace == "test" ? "$20-40" : "$50-100"
    }
    
    cost_factors = {
      instance_costs = "Varies by workspace: ${local.current_config.instance_type}"
      nat_gateway    = terraform.workspace == "prod" || terraform.workspace == "staging" ? "~$45/month per NAT Gateway" : "Disabled for cost savings"
      monitoring     = local.current_config.enable_monitoring ? "Enhanced monitoring ~$15/month" : "Basic monitoring included"
      storage        = "EBS volumes: ${local.current_config.volume_size}GB per instance"
    }
    
    cost_optimization = [
      "Dev/test workspaces use smaller instances and single AZ",
      "NAT Gateway disabled in dev/test to reduce costs",
      "Monitoring disabled in non-production workspaces",
      "Shorter log retention in dev/test environments",
      "On-demand instances in dev, consider Reserved Instances for prod"
    ]
  }
}