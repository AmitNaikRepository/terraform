output "vpc_id" {
  description = "ID of the cost-optimized VPC"
  value       = aws_vpc.cost_demo.id
}

output "instance_ids" {
  description = "IDs of the EC2 instances with cost tracking"
  value       = aws_instance.cost_demo[*].id
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances"
  value       = aws_instance.cost_demo[*].public_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket with lifecycle management"
  value       = aws_s3_bucket.cost_demo.bucket
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch cost monitoring dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring.dashboard_name}"
}

output "budget_name" {
  description = "Name of the AWS Budget for cost control"
  value       = aws_budgets_budget.cost_demo.name
}

# Cost Optimization Summary
output "cost_optimization_summary" {
  description = "Summary of cost optimization strategies implemented"
  value = {
    tagging_strategy = {
      cost_allocation_tags = [
        "CostCenter: ${var.cost_center}",
        "Project: ${var.project_name}",
        "Environment: ${var.environment}",
        "Owner: ${var.owner}",
        "BusinessUnit: ${var.business_unit}",
        "Application: ${var.application_name}"
      ]
      operational_tags = [
        "Terraform: true",
        "ManagedBy: terraform",
        "Repository: terraform-fundamentals"
      ]
      cost_control_tags = [
        "AutoShutdown: ${var.auto_shutdown_enabled}",
        "ShutdownSchedule: ${var.shutdown_schedule}",
        "BackupRequired: ${var.backup_required}",
        "Monitoring: ${var.detailed_monitoring ? "detailed" : "basic"}"
      ]
    }
    
    resource_optimization = {
      ec2_instances = {
        instance_type    = var.instance_type
        count           = var.instance_count
        monitoring      = var.detailed_monitoring ? "detailed" : "basic"
        auto_shutdown   = var.auto_shutdown_enabled
      }
      storage = {
        ebs_volume_type = var.volume_type
        volume_size     = "${var.volume_size}GB"
        encrypted       = true
        s3_lifecycle    = "enabled"
      }
    }
    
    cost_controls = {
      monthly_budget     = "$${var.monthly_budget_limit}"
      budget_alerts      = ["80% threshold", "100% forecast"]
      notification_email = var.budget_notification_email
      cost_monitoring    = "cloudwatch_dashboard"
    }
    
    estimated_monthly_costs = {
      ec2_instances = "$${local.monthly_cost_estimate.ec2_instances}"
      s3_storage    = "$${local.monthly_cost_estimate.s3_storage}"
      vpc_resources = "$${local.monthly_cost_estimate.vpc_resources}"
      total_estimate = "$${local.monthly_cost_estimate.total}"
    }
  }
}

# Resource-specific cost information
output "resource_cost_breakdown" {
  description = "Detailed cost breakdown by resource type"
  value = {
    compute = {
      ec2_instances = {
        count              = var.instance_count
        instance_type      = var.instance_type
        estimated_monthly  = "$${var.estimated_monthly_cost_per_instance * var.instance_count}"
        optimization_notes = var.instance_type == "t3.micro" ? "Cost optimized" : "Consider t3.micro for dev/test"
      }
      ebs_volumes = {
        count             = var.instance_count
        volume_type       = var.volume_type
        total_size        = "${var.instance_count * var.volume_size}GB"
        estimated_monthly = "$${var.estimated_ebs_monthly_cost * var.instance_count}"
      }
    }
    
    storage = {
      s3_bucket = {
        lifecycle_management = "enabled"
        storage_classes      = ["STANDARD", "STANDARD_IA", "GLACIER", "DEEP_ARCHIVE"]
        estimated_monthly    = "$${var.estimated_s3_monthly_cost}"
        cost_optimization   = "Automatic tiering after 30/90/365 days"
      }
    }
    
    networking = {
      vpc_resources = {
        components        = ["VPC", "Subnets", "IGW", "Route Tables", "Security Groups"]
        estimated_monthly = "$${var.estimated_vpc_monthly_cost}"
        optimization_note = "Most VPC components have no additional cost"
      }
    }
    
    monitoring = {
      cloudwatch = {
        detailed_monitoring = var.detailed_monitoring
        dashboard          = "included"
        estimated_monthly  = var.detailed_monitoring ? "$3.50" : "$0.30"
      }
      budgets = {
        cost_budget       = "enabled"
        alert_thresholds  = ["80%", "100%"]
        estimated_monthly = "$0.60"
      }
    }
  }
}

# Cost optimization recommendations
output "cost_optimization_recommendations" {
  description = "Actionable cost optimization recommendations"
  value = {
    immediate_actions = [
      "Review instance utilization via CloudWatch dashboard",
      "Enable auto-shutdown for non-production instances",
      "Set up budget alerts for cost monitoring",
      "Use lifecycle policies for S3 storage optimization"
    ]
    
    weekly_reviews = [
      "Check CloudWatch metrics for rightsizing opportunities",
      "Review budget alerts and spending patterns",
      "Verify auto-shutdown schedules are working",
      "Audit unused resources via cost allocation tags"
    ]
    
    monthly_optimizations = [
      "Analyze cost reports by tags (CostCenter, Project, Environment)",
      "Review S3 storage class transitions effectiveness",
      "Evaluate instance types based on utilization metrics",
      "Consider Reserved Instances for consistent workloads"
    ]
    
    cost_visibility = {
      dashboard_url = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.cost_monitoring.dashboard_name}"
      cost_explorer = "Use AWS Cost Explorer filtered by Project: ${var.project_name}"
      billing_alerts = "Budget: ${aws_budgets_budget.cost_demo.name}"
    }
  }
}