output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.web.id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = aws_launch_template.web.arn
}

output "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.name
}

output "auto_scaling_group_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.web.arn
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.web.arn
}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.web.zone_id
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.web.arn
}

output "target_group_name" {
  description = "Name of the target group"
  value       = aws_lb_target_group.web.name
}

# Structured output for easy consumption
output "compute_config" {
  description = "Complete compute configuration"
  value = {
    launch_template = {
      id  = aws_launch_template.web.id
      arn = aws_launch_template.web.arn
    }
    auto_scaling_group = {
      name = aws_autoscaling_group.web.name
      arn  = aws_autoscaling_group.web.arn
    }
    load_balancer = {
      arn       = aws_lb.web.arn
      dns_name  = aws_lb.web.dns_name
      zone_id   = aws_lb.web.zone_id
    }
    target_group = {
      arn  = aws_lb_target_group.web.arn
      name = aws_lb_target_group.web.name
    }
  }
}