output "s3_bucket_name" {
  description = "Name of the demo S3 bucket"
  value       = aws_s3_bucket.demo.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the demo S3 bucket"
  value       = aws_s3_bucket.demo.arn
}

output "application_instance_role_arn" {
  description = "ARN of the application instance role"
  value       = aws_iam_role.application_instance.arn
}

output "application_instance_role_name" {
  description = "Name of the application instance role"
  value       = aws_iam_role.application_instance.name
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.application.name
}

output "read_only_auditor_role_arn" {
  description = "ARN of the read-only auditor role"
  value       = aws_iam_role.read_only_auditor.arn
}

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_config.arn
}

# IAM Security Summary
output "iam_security_summary" {
  description = "Summary of IAM security implementation"
  value = {
    principle_of_least_privilege = {
      s3_access       = "Limited to specific bucket and paths only"
      cloudwatch_logs = "Write access to specific log group only"
      secrets_access  = "Read access to specific application secrets only"
    }
    security_controls = {
      region_restriction   = "IAM roles restricted to specific AWS region"
      external_id_required = "Audit role requires external ID for assumption"
      version_control      = "Secrets access limited to AWSCURRENT version"
    }
    role_separation = {
      application_role = "Minimal permissions for application operations"
      audit_role      = "Read-only access with additional CloudWatch Insights"
    }
    monitoring = {
      cloudwatch_logs = aws_cloudwatch_log_group.application.name
      secrets_manager = aws_secretsmanager_secret.app_config.name
    }
  }
}