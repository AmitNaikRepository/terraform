output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "web_security_group_arn" {
  description = "ARN of the web security group"
  value       = aws_security_group.web.arn
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

output "application_security_group_arn" {
  description = "ARN of the application security group"
  value       = aws_security_group.application.arn
}

output "database_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.database.id
}

output "database_security_group_arn" {
  description = "ARN of the database security group"
  value       = aws_security_group.database.arn
}

# Structured output for easy consumption
output "security_groups" {
  description = "All security group information"
  value = {
    web = {
      id  = aws_security_group.web.id
      arn = aws_security_group.web.arn
    }
    application = {
      id  = aws_security_group.application.id
      arn = aws_security_group.application.arn
    }
    database = {
      id  = aws_security_group.database.id
      arn = aws_security_group.database.arn
    }
  }
}