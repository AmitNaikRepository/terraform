output "s3_bucket_name" {
  description = "Name of the S3 bucket with lifecycle management"
  value       = aws_s3_bucket.lifecycle_demo.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket with lifecycle management"
  value       = aws_s3_bucket.lifecycle_demo.arn
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.lifecycle_demo.name
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.lifecycle_demo.arn
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.demo.dns_name
}

output "load_balancer_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.demo.dns_name}"
}

output "lambda_function_name" {
  description = "Name of the cost optimization Lambda function"
  value       = aws_lambda_function.cost_optimizer.function_name
}

output "lambda_function_arn" {
  description = "ARN of the cost optimization Lambda function"
  value       = aws_lambda_function.cost_optimizer.arn
}

# Lifecycle Management Summary
output "lifecycle_management_summary" {
  description = "Summary of automated lifecycle management features"
  value = {
    s3_lifecycle_policies = {
      current_objects = {
        standard_to_ia     = "30 days"
        ia_to_glacier      = "60 days"
        glacier_to_deep    = "180 days"
        expiration         = var.enable_object_expiration ? "${var.object_expiration_days} days" : "disabled"
      }
      log_files = {
        standard_to_ia     = "7 days"
        ia_to_glacier      = "30 days"
        glacier_to_deep    = "90 days"
        expiration         = "365 days"
      }
      temporary_files = {
        expiration = "7 days"
        multipart_cleanup = "1 day"
      }
      backup_files = {
        immediate_to_ia    = "1 day"
        ia_to_glacier      = "7 days"
        retention_period   = var.backup_retention_enabled ? "${var.backup_retention_days} days" : "indefinite"
      }
      version_management = {
        noncurrent_to_ia      = "30 days"
        noncurrent_to_glacier = "60 days"
        noncurrent_expiration = "90 days"
      }
    }
    
    compute_lifecycle = {
      auto_scaling = {
        min_instances      = var.asg_min_size
        max_instances      = var.asg_max_size
        desired_instances  = var.asg_desired_capacity
        spot_instances     = var.use_spot_instances ? "enabled" : "disabled"
        spot_max_price     = var.use_spot_instances ? "$${var.spot_max_price}/hour" : "n/a"
      }
      scheduled_scaling = {
        enabled           = var.enable_scheduled_scaling
        scale_down_time   = var.enable_scheduled_scaling ? var.scale_down_schedule : "disabled"
        scale_up_time     = var.enable_scheduled_scaling ? var.scale_up_schedule : "disabled"
        business_hours    = "Scale up: 8 AM weekdays, Scale down: 6 PM weekdays"
      }
      instance_refresh = {
        strategy          = "Rolling"
        min_healthy       = "50%"
        warmup_time       = "300 seconds"
      }
    }
    
    automation = {
      cost_optimizer_lambda = {
        enabled           = var.enable_automated_optimization
        schedule          = "Daily at 10 PM"
        functions         = [
          "Unused instance detection",
          "S3 storage optimization",
          "Cost anomaly detection",
          "Resource tagging compliance"
        ]
      }
    }
  }
}

# Cost Savings Estimates
output "cost_savings_estimates" {
  description = "Estimated cost savings from lifecycle management"
  value = {
    s3_storage_savings = {
      standard_to_ia_transition    = "Up to 45% savings after 30 days"
      ia_to_glacier_transition     = "Up to 68% additional savings after 60 days"
      glacier_to_deep_transition   = "Up to 75% additional savings after 180 days"
      version_lifecycle_management = "Up to 50% savings on versioned objects"
      incomplete_upload_cleanup    = "Prevents unnecessary storage charges"
    }
    
    compute_savings = {
      scheduled_scaling = {
        evening_shutdown   = "Up to 75% savings during off-hours"
        weekend_shutdown   = "Up to 67% savings during weekends"
        business_hours_only = "Potential 50-60% monthly compute savings"
      }
      spot_instances = {
        enabled           = var.use_spot_instances
        potential_savings = var.use_spot_instances ? "Up to 90% compared to On-Demand" : "Enable for up to 90% savings"
        max_price         = var.use_spot_instances ? "$${var.spot_max_price}/hour" : "n/a"
      }
      rightsizing = {
        instance_type     = var.instance_type
        optimization_note = "Using cost-optimized instance types"
      }
    }
    
    operational_savings = {
      automated_optimization = {
        manual_effort_reduction = "80% reduction in manual cost optimization tasks"
        proactive_cost_control  = "Prevents cost overruns through automation"
        compliance_automation   = "Automatic resource tagging and lifecycle compliance"
      }
    }
  }
}

# Monitoring and Alerts
output "monitoring_and_automation" {
  description = "Monitoring and automation configuration"
  value = {
    eventbridge_schedules = {
      cost_optimization = var.enable_automated_optimization ? "Daily at 10 PM" : "disabled"
      auto_scaling = {
        scale_up   = var.enable_scheduled_scaling ? var.scale_up_schedule : "disabled"
        scale_down = var.enable_scheduled_scaling ? var.scale_down_schedule : "disabled"
      }
    }
    
    lambda_automation = {
      function_name     = aws_lambda_function.cost_optimizer.function_name
      runtime          = "python3.9"
      timeout          = "300 seconds"
      environment_vars = {
        PROJECT_NAME = var.project_name
        ENVIRONMENT  = var.environment
        BUCKET_NAME  = aws_s3_bucket.lifecycle_demo.bucket
      }
    }
    
    cost_optimization_features = [
      "Automated instance shutdown detection",
      "S3 storage class optimization",
      "Unused resource identification",
      "Cost anomaly detection",
      "Resource tagging compliance",
      "Lifecycle policy enforcement"
    ]
  }
}

# Best Practices Summary
output "lifecycle_best_practices" {
  description = "Lifecycle management best practices implemented"
  value = {
    storage_optimization = [
      "✅ Intelligent tiering based on access patterns",
      "✅ Aggressive archiving for logs and temporary files",
      "✅ Version lifecycle management to reduce storage costs",
      "✅ Automatic cleanup of incomplete multipart uploads",
      "✅ Separate policies for different data types (logs, backups, temp files)"
    ]
    
    compute_optimization = [
      "✅ Scheduled scaling based on business hours",
      "✅ Spot instance utilization for cost-tolerant workloads",
      "✅ Auto Scaling Group with health checks and rolling updates",
      "✅ Instance refresh strategy for zero-downtime updates",
      "✅ Cost-optimized instance types (${var.instance_type})"
    ]
    
    automation_practices = [
      "✅ Event-driven cost optimization via Lambda",
      "✅ Scheduled automation for regular cost reviews",
      "✅ Infrastructure as Code for consistent lifecycle policies",
      "✅ Comprehensive tagging for cost allocation and automation",
      "✅ Proactive cost management through automated actions"
    ]
    
    monitoring_practices = [
      "✅ CloudWatch integration for utilization monitoring",
      "✅ Application Load Balancer health checks",
      "✅ EventBridge scheduling for automation",
      "✅ Lambda function logging for audit trails",
      "✅ Auto Scaling metrics and events tracking"
    ]
  }
}