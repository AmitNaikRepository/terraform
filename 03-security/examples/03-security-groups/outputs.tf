output "vpc_id" {
  description = "ID of the demo VPC"
  value       = aws_vpc.demo.id
}

output "web_instance_id" {
  description = "ID of the web server instance"
  value       = aws_instance.web.id
}

output "web_instance_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}

output "app_instance_id" {
  description = "ID of the application server instance"
  value       = aws_instance.app.id
}

output "app_instance_private_ip" {
  description = "Private IP of the application server"
  value       = aws_instance.app.private_ip
}

# Security Group Information
output "security_groups" {
  description = "Security group details"
  value = {
    web_tier = {
      id   = aws_security_group.web_tier.id
      name = aws_security_group.web_tier.name
    }
    app_tier = {
      id   = aws_security_group.app_tier.id
      name = aws_security_group.app_tier.name
    }
    database_tier = {
      id   = aws_security_group.database_tier.id
      name = aws_security_group.database_tier.name
    }
    bastion = {
      id   = aws_security_group.bastion.id
      name = aws_security_group.bastion.name
    }
    alb = {
      id   = aws_security_group.alb.id
      name = aws_security_group.alb.name
    }
  }
}

# Security Architecture Summary
output "security_architecture" {
  description = "Summary of security group architecture"
  value = {
    network_segmentation = {
      web_tier      = "Public subnet - accepts HTTP/HTTPS from internet"
      app_tier      = "Private subnet - accepts traffic only from web tier"
      database_tier = "Most restricted - accepts traffic only from app tier"
    }
    access_patterns = {
      internet_to_web = "HTTP(80), HTTPS(443)"
      web_to_app     = "Application port (${var.app_port})"
      app_to_db      = "MySQL(3306)"
      bastion_access = "SSH(22) from management network only"
    }
    security_principles = {
      least_privilege    = "Each tier has minimum required access"
      defense_in_depth   = "Multiple layers of security controls"
      explicit_deny      = "No unnecessary outbound rules"
      reference_security = "Security groups reference each other, not IP ranges"
    }
    best_practices = {
      name_prefix        = "Used for better resource naming"
      lifecycle_rules    = "create_before_destroy for zero-downtime updates"
      specific_rules     = "Granular port and protocol specifications"
      management_access  = "Restricted to specific CIDR blocks"
    }
  }
}