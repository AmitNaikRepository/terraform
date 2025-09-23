# Core module outputs

output "module_name" {
  description = "Name of this module"
  value       = "{MODULE_NAME}"
}

output "resource_tags" {
  description = "Common tags applied to all resources"
  value       = local.common_tags
}

# Resource-specific outputs

output "example_bucket_id" {
  description = "ID of the example S3 bucket"
  value       = aws_s3_bucket.example.id
}

output "example_bucket_arn" {
  description = "ARN of the example S3 bucket"
  value       = aws_s3_bucket.example.arn
}

output "example_bucket_domain_name" {
  description = "Domain name of the example S3 bucket"
  value       = aws_s3_bucket.example.bucket_domain_name
}

# Structured output for easy consumption by other modules
output "bucket_config" {
  description = "Complete bucket configuration object"
  value = {
    id          = aws_s3_bucket.example.id
    arn         = aws_s3_bucket.example.arn
    domain_name = aws_s3_bucket.example.bucket_domain_name
    region      = aws_s3_bucket.example.region
  }
}

# Conditional outputs (example)
output "conditional_output" {
  description = "Output that's only present when feature is enabled"
  value       = var.enable_feature ? "Feature is enabled" : null
}

# List outputs (example)
output "resource_list" {
  description = "List of created resource IDs"
  value = [
    aws_s3_bucket.example.id,
    # Add other resource IDs here
  ]
}

# Map outputs (example)
output "resource_map" {
  description = "Map of resource names to their IDs"
  value = {
    bucket = aws_s3_bucket.example.id
    # Add other resources here
  }
}