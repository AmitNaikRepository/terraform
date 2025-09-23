output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "load_balancer_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.web.dns_name}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.rightsizing_demo.id
}

output "auto_scaling_groups" {
  description = "Auto Scaling Group information"
  value = {
    web_tier = {
      name = aws_autoscaling_group.web_tier.name
      arn  = aws_autoscaling_group.web_tier.arn
    }
    app_tier = {
      name = aws_autoscaling_group.app_tier.name
      arn  = aws_autoscaling_group.app_tier.arn
    }
    worker_tier = {
      name = aws_autoscaling_group.worker_tier.name
      arn  = aws_autoscaling_group.worker_tier.arn
    }
  }
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch right-sizing dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.rightsizing_monitoring.dashboard_name}"
}

# Right-sizing Configuration Summary
output "rightsizing_configuration" {
  description = "Summary of right-sizing configuration for each tier"
  value = {
    web_tier = {
      instance_type        = var.web_tier_instance_type
      instance_count       = var.web_tier_count
      min_instances        = var.web_tier_min_size
      max_instances        = var.web_tier_max_size
      volume_size          = "${var.web_tier_volume_size}GB"
      workload_optimized   = "HTTP/HTTPS request handling"
      target_cpu_usage     = "15-25%"
      target_memory_usage  = "40-60%"
      estimated_monthly_cost = "$${local.instance_costs[var.web_tier_instance_type] * var.web_tier_count}"
    }
    
    app_tier = {
      instance_type        = var.app_tier_instance_type
      instance_count       = var.app_tier_count
      min_instances        = var.app_tier_min_size
      max_instances        = var.app_tier_max_size
      volume_size          = "${var.app_tier_volume_size}GB"
      workload_optimized   = "Business logic and API processing"
      target_cpu_usage     = "30-50%"
      target_memory_usage  = "50-70%"
      estimated_monthly_cost = "$${local.instance_costs[var.app_tier_instance_type] * var.app_tier_count}"
    }
    
    worker_tier = {
      instance_type        = var.worker_tier_instance_type
      instance_count       = var.worker_tier_count
      min_instances        = var.worker_tier_min_size
      max_instances        = var.worker_tier_max_size
      volume_size          = "${var.worker_tier_volume_size}GB"
      workload_optimized   = "Background processing and batch jobs"
      target_cpu_usage     = "60-80%"
      target_memory_usage  = "40-60%"
      estimated_monthly_cost = "$${local.instance_costs[var.worker_tier_instance_type] * var.worker_tier_count}"
    }
  }
}

# Cost Analysis
output "cost_analysis" {
  description = "Detailed cost analysis and optimization recommendations"
  value = {
    current_configuration = {
      web_tier_monthly     = "$${local.instance_costs[var.web_tier_instance_type] * var.web_tier_count}"
      app_tier_monthly     = "$${local.instance_costs[var.app_tier_instance_type] * var.app_tier_count}"
      worker_tier_monthly  = "$${local.instance_costs[var.worker_tier_instance_type] * var.worker_tier_count}"
      total_monthly        = "$${local.total_monthly_cost}"
      total_annual         = "$${local.total_monthly_cost * 12}"
    }
    
    optimization_potential = {
      oversized_warning = {
        web_tier = var.web_tier_instance_type == "t3.large" || var.web_tier_instance_type == "t3.xlarge" ? 
                   "Consider downsizing - web tier rarely needs large instances" : "Appropriately sized"
        app_tier = var.app_tier_instance_type == "t3.xlarge" ? 
                   "Consider t3.large or smaller for most workloads" : "Appropriately sized"
        worker_tier = var.worker_tier_instance_type == "t3.xlarge" ? 
                      "Monitor CPU usage - may be oversized" : "Sized for processing workloads"
      }
      
      undersized_warning = {
        web_tier = var.web_tier_instance_type == "t3.nano" ? 
                   "Monitor performance - may need t3.micro for production" : "Sufficient for workload"
        app_tier = var.app_tier_instance_type == "t3.micro" ? 
                   "Consider t3.small for better application performance" : "Sufficient for workload"
        worker_tier = var.worker_tier_instance_type == "t3.small" ? 
                      "Monitor queue processing times - may need more CPU" : "Sufficient for workload"
      }
      
      cost_savings_opportunities = [
        var.web_tier_instance_type == "t3.large" ? "Downsize web tier to t3.small: Save ~$45/month" : null,
        var.app_tier_instance_type == "t3.xlarge" ? "Downsize app tier to t3.medium: Save ~$90/month" : null,
        var.worker_tier_count > 1 && var.worker_tier_instance_type == "t3.xlarge" ? "Use scheduled scaling for workers: Save ~$60/month" : null,
        !var.enable_detailed_monitoring ? null : "Disable detailed monitoring in dev: Save ~$21/month"
      ]
    }
  }
}

# Performance vs Cost Recommendations
output "rightsizing_recommendations" {
  description = "Actionable right-sizing recommendations based on workload patterns"
  value = {
    immediate_actions = [
      "Monitor CPU and memory utilization via CloudWatch dashboard",
      "Set up CloudWatch alarms for under/over-utilization",
      "Review Auto Scaling policies and thresholds",
      "Analyze application performance metrics vs costs"
    ]
    
    weekly_reviews = [
      "Check average CPU utilization across all tiers",
      "Review scaling events and patterns",
      "Validate that target utilization rates are being met",
      "Monitor application response times during peak usage"
    ]
    
    monthly_optimizations = [
      "Analyze 30-day utilization trends for rightsizing opportunities",
      "Review and adjust Auto Scaling policies based on usage patterns",
      "Evaluate instance type performance vs cost for each tier",
      "Consider Reserved Instances for predictable workloads"
    ]
    
    workload_specific_guidance = {
      web_tier = {
        optimal_utilization = "15-25% CPU, 40-60% memory"
        scaling_triggers    = "Scale based on request count and response time"
        cost_optimization   = "Use Application Load Balancer for efficient distribution"
        monitoring_focus    = "Monitor request latency and connection counts"
      }
      
      app_tier = {
        optimal_utilization = "30-50% CPU, 50-70% memory"
        scaling_triggers    = "Scale based on CPU and memory utilization"
        cost_optimization   = "Right-size based on business logic complexity"
        monitoring_focus    = "Monitor database connection pools and API response times"
      }
      
      worker_tier = {
        optimal_utilization = "60-80% CPU, 40-60% memory"
        scaling_triggers    = "Scale based on queue depth and processing time"
        cost_optimization   = "Use scheduled scaling for batch processing windows"
        monitoring_focus    = "Monitor queue processing rates and job completion times"
      }
    }
  }
}

# Right-sizing Best Practices
output "rightsizing_best_practices" {
  description = "Right-sizing best practices implemented in this configuration"
  value = {
    tier_separation = [
      "✅ Separate instance types for different workload patterns",
      "✅ Web tier optimized for HTTP request handling",
      "✅ App tier sized for business logic processing",
      "✅ Worker tier configured for background processing"
    ]
    
    auto_scaling = [
      "✅ Auto Scaling Groups with different scaling policies per tier",
      "✅ CloudWatch alarms for CPU-based scaling",
      "✅ Health checks to ensure instance reliability",
      "✅ Rolling updates for zero-downtime deployments"
    ]
    
    cost_controls = [
      "✅ Instance types selected based on workload requirements",
      "✅ EBS volumes sized appropriately for each tier",
      "✅ Optional detailed monitoring (disabled by default for cost savings)",
      "✅ Comprehensive tagging for cost allocation and tracking"
    ]
    
    monitoring_and_optimization = [
      "✅ CloudWatch dashboard for utilization monitoring",
      "✅ Right-sizing recommendations based on actual usage",
      "✅ Cost analysis with optimization opportunities",
      "✅ Performance vs cost trade-off analysis"
    ]
    
    workload_optimization = [
      "✅ Target utilization rates defined for each tier",
      "✅ Instance types matched to workload characteristics",
      "✅ Storage optimization with GP3 volumes",
      "✅ Network optimization with proper subnet placement"
    ]
  }
}

# Monitoring URLs and Resources
output "monitoring_resources" {
  description = "Monitoring and management resources for right-sizing"
  value = {
    cloudwatch_dashboard = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.rightsizing_monitoring.dashboard_name}"
    
    auto_scaling_groups = {
      web_tier    = "https://${var.aws_region}.console.aws.amazon.com/ec2/autoscaling/home?region=${var.aws_region}#AutoScalingGroups:id=${aws_autoscaling_group.web_tier.name}"
      app_tier    = "https://${var.aws_region}.console.aws.amazon.com/ec2/autoscaling/home?region=${var.aws_region}#AutoScalingGroups:id=${aws_autoscaling_group.app_tier.name}"
      worker_tier = "https://${var.aws_region}.console.aws.amazon.com/ec2/autoscaling/home?region=${var.aws_region}#AutoScalingGroups:id=${aws_autoscaling_group.worker_tier.name}"
    }
    
    load_balancer = "https://${var.aws_region}.console.aws.amazon.com/ec2/v2/home?region=${var.aws_region}#LoadBalancers:search=${aws_lb.web.name}"
    
    cost_explorer = "Use AWS Cost Explorer with tags: Project=${var.project_name}, Environment=${var.environment}"
  }
}