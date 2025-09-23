output "vpc_id" {
  description = "ID of the secure VPC"
  value       = aws_vpc.secure.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the secure VPC"
  value       = aws_vpc.secure.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public (DMZ) subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private (application) subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "nat_gateway_ips" {
  description = "Public IP addresses of NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

output "flow_logs_log_group" {
  description = "CloudWatch log group for VPC flow logs"
  value       = aws_cloudwatch_log_group.vpc_flow_log.name
}

# Security architecture summary
output "security_architecture" {
  description = "Summary of the security architecture implemented"
  value = {
    network_segmentation = {
      dmz_tier         = "Public subnets for load balancers only"
      application_tier = "Private subnets with NAT gateway access"
      data_tier       = "Isolated database subnets with no internet"
    }
    security_controls = {
      vpc_flow_logs    = "Enabled for all network traffic monitoring"
      network_isolation = "3-tier architecture with proper segmentation"
      outbound_control = "NAT gateways for controlled internet access"
    }
    monitoring = {
      flow_logs        = aws_cloudwatch_log_group.vpc_flow_log.name
      log_retention    = "30 days"
    }
  }
}