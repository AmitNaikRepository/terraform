terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.default_tags
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  
  common_tags = merge(var.default_tags, {
    Module  = "iam-security"
    Purpose = "least-privilege-demo"
  })
}

# S3 Bucket for demonstration
resource "aws_s3_bucket" "demo" {
  bucket = "${var.project_name}-${var.environment}-demo-${random_string.suffix.result}"

  tags = merge(local.common_tags, {
    Purpose = "iam-demo"
    DataClass = "demo"
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Application Instance Role with Least Privilege
resource "aws_iam_role" "application_instance" {
  name = "${var.project_name}-${var.environment}-app-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    RoleType = "application-instance"
    Access   = "least-privilege"
  })
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "application" {
  name = "${var.project_name}-${var.environment}-app-instance-profile"
  role = aws_iam_role.application_instance.name

  tags = local.common_tags
}

# S3 Access Policy - Specific bucket and path only
resource "aws_iam_policy" "s3_limited_access" {
  name        = "${var.project_name}-${var.environment}-s3-limited-access"
  description = "Limited S3 access for application"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListSpecificBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.demo.arn
        ]
        Condition = {
          StringLike = {
            "s3:prefix" = [
              "${var.environment}/*",
              "shared/*"
            ]
          }
        }
      },
      {
        Sid    = "ReadWriteSpecificPaths"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "${aws_s3_bucket.demo.arn}/${var.environment}/*",
          "${aws_s3_bucket.demo.arn}/shared/*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    PolicyType = "s3-access"
    Scope      = "limited"
  })
}

# CloudWatch Logs Policy - Specific log group only
resource "aws_iam_policy" "cloudwatch_logs_limited" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs"
  description = "Limited CloudWatch logs access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.application.arn}:*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    PolicyType = "logging"
    Scope      = "limited"
  })
}

# Secrets Manager Access Policy - Specific secrets only
resource "aws_iam_policy" "secrets_limited_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Limited access to specific application secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.app_config.arn
        ]
        Condition = {
          StringEquals = {
            "secretsmanager:VersionStage" = "AWSCURRENT"
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    PolicyType = "secrets-access"
    Scope      = "limited"
  })
}

# Attach policies to instance role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.application_instance.name
  policy_arn = aws_iam_policy.s3_limited_access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.application_instance.name
  policy_arn = aws_iam_policy.cloudwatch_logs_limited.arn
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.application_instance.name
  policy_arn = aws_iam_policy.secrets_limited_access.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = merge(local.common_tags, {
    LogType = "application"
  })
}

# Secrets Manager Secret
resource "aws_secretsmanager_secret" "app_config" {
  name                    = "${var.project_name}-${var.environment}-app-config"
  description             = "Application configuration for ${var.project_name}"
  recovery_window_in_days = 7

  tags = merge(local.common_tags, {
    SecretType = "application-config"
  })
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    database_url = "postgresql://user:pass@localhost:5432/myapp"
    api_key      = "demo-api-key-12345"
    environment  = var.environment
  })
}

# Read-Only Role for Monitoring/Auditing
resource "aws_iam_role" "read_only_auditor" {
  name = "${var.project_name}-${var.environment}-read-only-auditor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.audit_external_id
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    RoleType = "auditor"
    Access   = "read-only"
  })
}

# Attach AWS managed ReadOnlyAccess policy
resource "aws_iam_role_policy_attachment" "read_only_access" {
  role       = aws_iam_role.read_only_auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Custom policy for specific audit requirements
resource "aws_iam_policy" "audit_specific" {
  name        = "${var.project_name}-${var.environment}-audit-specific"
  description = "Specific audit permissions beyond read-only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.application.arn}:*"
        ]
      }
    ]
  })

  tags = merge(local.common_tags, {
    PolicyType = "audit"
    Scope      = "cloudwatch-insights"
  })
}

resource "aws_iam_role_policy_attachment" "audit_specific" {
  role       = aws_iam_role.read_only_auditor.name
  policy_arn = aws_iam_policy.audit_specific.arn
}