output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  description = "Public IP addresses of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Structured output for easy consumption by other modules
output "network_config" {
  description = "Complete network configuration object"
  value = {
    vpc = {
      id         = aws_vpc.main.id
      cidr_block = aws_vpc.main.cidr_block
      arn        = aws_vpc.main.arn
    }
    public_subnets = {
      ids        = aws_subnet.public[*].id
      cidrs      = aws_subnet.public[*].cidr_block
      arns       = aws_subnet.public[*].arn
      azs        = aws_subnet.public[*].availability_zone
    }
    private_subnets = {
      ids        = aws_subnet.private[*].id
      cidrs      = aws_subnet.private[*].cidr_block
      arns       = aws_subnet.private[*].arn
      azs        = aws_subnet.private[*].availability_zone
    }
    gateways = {
      internet_gateway_id = aws_internet_gateway.main.id
      nat_gateway_ids     = aws_nat_gateway.main[*].id
      nat_gateway_ips     = aws_eip.nat[*].public_ip
    }
  }
}