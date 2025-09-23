# Module 10: Team Collaboration → Software Development Workflows

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Design Collaborative Infrastructure Workflows**: Implement Git-based workflows that enable safe, efficient team collaboration on infrastructure
- **Establish Code Review Processes**: Create review workflows that ensure infrastructure quality and knowledge sharing
- **Implement Documentation Standards**: Build comprehensive documentation that enables team onboarding and knowledge transfer
- **Set Up Team Communication Systems**: Configure notifications, alerts, and communication channels for infrastructure teams
- **Apply Agile Practices to Infrastructure**: Adapt software development methodologies to infrastructure management
- **Build Knowledge Sharing Systems**: Create processes and tools that facilitate team learning and expertise distribution

## 🎯 Overview

Team collaboration in infrastructure development mirrors the collaborative practices that have evolved in software development teams. Just as software teams use Git workflows, code reviews, and documentation standards to work effectively together, infrastructure teams need similar practices adapted for infrastructure as code.

This module explores how to apply proven software development collaboration patterns to infrastructure teams. We'll examine how Git workflows, code review processes, documentation practices, and team communication strategies translate to infrastructure management, creating environments where teams can work efficiently while maintaining high standards of quality and reliability.

## 📖 Core Concepts

### Software Development vs Infrastructure Collaboration

| Software Development Practice | Infrastructure Equivalent | Purpose |
|------------------------------|---------------------------|---------|
| Git Feature Branches | Infrastructure Feature Branches | Isolated development of infrastructure changes |
| Pull Request Reviews | Infrastructure Change Reviews | Quality gates and knowledge sharing |
| Code Documentation | Infrastructure Documentation | System understanding and onboarding |
| Sprint Planning | Infrastructure Planning | Capacity planning and priority management |
| Pair Programming | Infrastructure Pairing | Knowledge transfer and quality improvement |
| Daily Standups | Infrastructure Standups | Coordination and blocker identification |

### Collaboration Patterns in Infrastructure

#### 1. Git Workflow Adaptation (Feature Branch Model)
**Software Development:**
```bash
# Feature branch workflow for application code
git checkout -b feature/user-authentication
# Develop feature
git add src/auth/
git commit -m "Add user authentication system"
git push origin feature/user-authentication
# Create pull request → review → merge → deploy
```

**Infrastructure Equivalent:**
```bash
# Feature branch workflow for infrastructure
git checkout -b infrastructure/add-monitoring-stack
# Develop infrastructure changes
terraform workspace new feature-monitoring
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
# Test infrastructure changes
git add modules/monitoring/
git commit -m "Add comprehensive monitoring stack with Prometheus and Grafana"
git push origin infrastructure/add-monitoring-stack
# Create pull request → review → test → merge → promote through environments
```

#### 2. Code Review Processes (Quality Gates)
**Software Development:**
```yaml
# Pull request requirements
pull_request_rules:
  - name: Require code review
    conditions:
      - "#approved-reviews-by>=2"
      - "#review-requested=0"
      - "status-success=ci/tests"
      - "status-success=security/scan"
    actions:
      merge:
        method: merge
```

**Infrastructure Equivalent:**
```yaml
# Infrastructure change requirements
pull_request_rules:
  - name: Require infrastructure review
    conditions:
      - "#approved-reviews-by>=2"
      - "status-success=terraform/validate"
      - "status-success=terraform/plan"
      - "status-success=security/tfsec"
      - "status-success=cost/estimate"
    actions:
      merge:
        method: merge
```

#### 3. Documentation as Code (Knowledge Management)
**Software Development:**
```markdown
# API Documentation
## Authentication Endpoint

### POST /api/auth/login
Authenticates a user and returns a JWT token.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "expires_in": 3600
}
```
```

**Infrastructure Equivalent:**
```markdown
# Infrastructure Documentation
## VPC Module

### Module: modules/vpc

Creates a VPC with public and private subnets across multiple AZs.

**Usage:**
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix        = "myapp-prod"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
}
```

**Outputs:**
```hcl
vpc_id              = "vpc-12345678"
public_subnet_ids   = ["subnet-12345", "subnet-67890"]
private_subnet_ids  = ["subnet-abcde", "subnet-fghij"]
```
```

## 🛠️ Terraform Implementation

### 1. Team Workflow Infrastructure

```hcl
# examples/01-team-workflow/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_organization
}

locals {
  common_tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Repository  = var.repository_name
    Team        = var.team_name
    Purpose     = "team-collaboration"
  }
}

# GitHub Repository Configuration for Infrastructure Collaboration
resource "github_repository" "infrastructure" {
  name        = "${var.project_name}-infrastructure"
  description = "Infrastructure as Code for ${var.project_name}"
  
  visibility = "private"
  
  # Collaboration settings
  has_issues    = true
  has_projects  = true
  has_wiki      = true
  
  # Branch protection and workflow settings
  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = false
  delete_branch_on_merge = true
  
  # Templates and automation
  gitignore_template = "Terraform"
  license_template   = "mit"
  
  # Advanced settings
  archived               = false
  archive_on_destroy     = false
  vulnerability_alerts   = true
  allow_auto_merge       = true
  allow_update_branch    = true
  
  pages {
    source {
      branch = "main"
      path   = "/docs"
    }
  }
  
  topics = [
    "terraform",
    "infrastructure-as-code",
    "aws",
    "devops",
    var.project_name
  ]
}

# Branch Protection Rules for Infrastructure Repository
resource "github_branch_protection" "main" {
  repository_id = github_repository.infrastructure.node_id
  pattern      = "main"
  
  # Require pull request reviews
  required_pull_request_reviews {
    required_approving_review_count = 2
    dismiss_stale_reviews          = true
    restrict_dismissals            = true
    dismissal_restrictions         = var.infrastructure_reviewers
    require_code_owner_reviews     = true
    require_last_push_approval     = true
  }
  
  # Require status checks
  required_status_checks {
    strict = true
    contexts = [
      "terraform/validate",
      "terraform/plan", 
      "security/tfsec",
      "cost/estimate",
      "documentation/check"
    ]
  }
  
  # Additional protections
  enforce_admins         = true
  allows_deletions       = false
  allows_force_pushes    = false
  require_signed_commits = true
  
  # Linear history requirement
  required_linear_history = true
  
  # Conversation resolution requirement
  require_conversation_resolution = true
}

# Team Management
resource "github_team" "infrastructure" {
  name        = "${var.project_name}-infrastructure"
  description = "Infrastructure team for ${var.project_name}"
  privacy     = "closed"
}

resource "github_team" "infrastructure_reviewers" {
  name        = "${var.project_name}-infrastructure-reviewers"
  description = "Senior infrastructure engineers with review privileges"
  privacy     = "closed"
  parent_team_id = github_team.infrastructure.id
}

# Team Repository Access
resource "github_team_repository" "infrastructure_team_repo" {
  team_id    = github_team.infrastructure.id
  repository = github_repository.infrastructure.name
  permission = "push"
}

resource "github_team_repository" "infrastructure_reviewers_repo" {
  team_id    = github_team.infrastructure_reviewers.id
  repository = github_repository.infrastructure.name
  permission = "admin"
}

# Issue and Pull Request Templates
resource "github_repository_file" "pull_request_template" {
  repository = github_repository.infrastructure.name
  branch     = "main"
  file       = ".github/pull_request_template.md"
  
  content = templatefile("${path.module}/templates/pull_request_template.md", {
    project_name = var.project_name
  })
  
  commit_message      = "Add pull request template for infrastructure changes"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@${var.domain_name}"
  overwrite_on_create = true
}

resource "github_repository_file" "issue_template_bug" {
  repository = github_repository.infrastructure.name
  branch     = "main"
  file       = ".github/ISSUE_TEMPLATE/bug_report.md"
  
  content = templatefile("${path.module}/templates/bug_report_template.md", {
    project_name = var.project_name
  })
  
  commit_message      = "Add bug report template"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@${var.domain_name}"
  overwrite_on_create = true
}

resource "github_repository_file" "issue_template_feature" {
  repository = github_repository.infrastructure.name
  branch     = "main"
  file       = ".github/ISSUE_TEMPLATE/feature_request.md"
  
  content = templatefile("${path.module}/templates/feature_request_template.md", {
    project_name = var.project_name
  })
  
  commit_message      = "Add feature request template"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@${var.domain_name}"
  overwrite_on_create = true
}

# Code Owners File for Review Assignment
resource "github_repository_file" "codeowners" {
  repository = github_repository.infrastructure.name
  branch     = "main"
  file       = ".github/CODEOWNERS"
  
  content = templatefile("${path.module}/templates/CODEOWNERS", {
    infrastructure_team = github_team.infrastructure_reviewers.slug
    security_team      = var.security_team
    platform_team      = var.platform_team
  })
  
  commit_message      = "Add CODEOWNERS for automated review assignment"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@${var.domain_name}"
  overwrite_on_create = true
}

# GitHub Actions Workflows for Infrastructure CI/CD
resource "github_repository_file" "terraform_workflow" {
  repository = github_repository.infrastructure.name
  branch     = "main"
  file       = ".github/workflows/terraform.yml"
  
  content = templatefile("${path.module}/templates/terraform_workflow.yml", {
    project_name = var.project_name
    aws_region   = var.aws_region
  })
  
  commit_message      = "Add Terraform CI/CD workflow"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@${var.domain_name}"
  overwrite_on_create = true
}

# Documentation Workflow
resource "github_repository_file" "docs_workflow" {
  repository = github_repository.infrastructure.name
  branch     = "main"
  file       = ".github/workflows/documentation.yml"
  
  content = templatefile("${path.module}/templates/docs_workflow.yml", {
    project_name = var.project_name
  })
  
  commit_message      = "Add documentation generation workflow"
  commit_author       = "Terraform Automation"
  commit_email        = "terraform@${var.domain_name}"
  overwrite_on_create = true
}

# Team Communication Infrastructure
resource "aws_sns_topic" "infrastructure_notifications" {
  name = "${var.project_name}-infrastructure-notifications"
  
  tags = merge(local.common_tags, {
    Purpose = "team-notifications"
  })
}

# Slack Integration for Infrastructure Notifications
resource "aws_sns_topic_subscription" "slack_notifications" {
  topic_arn = aws_sns_topic.infrastructure_notifications.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
  
  delivery_policy = jsonencode({
    healthyRetryPolicy = {
      numRetries = 3
      minDelayTarget = 20
      maxDelayTarget = 20
      numMinDelayRetries = 0
      numMaxDelayRetries = 0
      numNoDelayRetries = 0
      backoffFunction = "linear"
    }
  })
}

# Email Notifications for Critical Infrastructure Events
resource "aws_sns_topic_subscription" "email_notifications" {
  count     = length(var.infrastructure_team_emails)
  topic_arn = aws_sns_topic.infrastructure_notifications.arn
  protocol  = "email"
  endpoint  = var.infrastructure_team_emails[count.index]
}

# CloudWatch Events for Infrastructure Change Notifications
resource "aws_cloudwatch_event_rule" "infrastructure_changes" {
  name        = "${var.project_name}-infrastructure-changes"
  description = "Capture infrastructure changes"
  
  event_pattern = jsonencode({
    source        = ["aws.cloudtrail"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = [
        "ec2.amazonaws.com",
        "rds.amazonaws.com", 
        "s3.amazonaws.com",
        "iam.amazonaws.com"
      ]
      eventName = [
        "CreateInstance",
        "TerminateInstances",
        "CreateDBInstance",
        "DeleteDBInstance",
        "CreateBucket",
        "DeleteBucket",
        "CreateRole",
        "DeleteRole"
      ]
    }
  })
  
  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "infrastructure_notifications" {
  rule      = aws_cloudwatch_event_rule.infrastructure_changes.name
  target_id = "InfrastructureNotificationsTarget"
  arn       = aws_sns_topic.infrastructure_notifications.arn
}

resource "aws_sns_topic_policy" "infrastructure_notifications" {
  arn = aws_sns_topic.infrastructure_notifications.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.infrastructure_notifications.arn
      }
    ]
  })
}

# Infrastructure Knowledge Base
resource "aws_s3_bucket" "knowledge_base" {
  bucket = "${var.project_name}-infrastructure-knowledge-base-${random_string.suffix.result}"
  
  tags = merge(local.common_tags, {
    Purpose = "knowledge-management"
  })
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "knowledge_base" {
  bucket = aws_s3_bucket.knowledge_base.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "knowledge_base" {
  bucket = aws_s3_bucket.knowledge_base.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Team Performance Dashboard
resource "aws_cloudwatch_dashboard" "team_performance" {
  dashboard_name = "${var.project_name}-team-performance"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", "FunctionName", "${var.project_name}-infrastructure-automation"],
            [".", "Errors", ".", "."],
            [".", "Duration", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Infrastructure Automation Performance"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6
        
        properties = {
          query   = "SOURCE '/aws/lambda/${var.project_name}-infrastructure-automation'\n| fields @timestamp, @message\n| filter @message like /ERROR/\n| sort @timestamp desc\n| limit 20"
          region  = var.aws_region
          title   = "Recent Infrastructure Errors"
          view    = "table"
        }
      }
    ]
  })
  
  tags = local.common_tags
}
```

### 2. Code Review and Quality Gates

```hcl
# examples/02-code-review/main.tf

# Quality Gates Lambda Function
resource "aws_lambda_function" "terraform_quality_gates" {
  function_name = "${var.project_name}-terraform-quality-gates"
  role         = aws_iam_role.quality_gates_lambda.arn
  handler      = "index.handler"
  runtime      = "python3.9"
  timeout      = 300
  
  filename         = data.archive_file.quality_gates_lambda.output_path
  source_code_hash = data.archive_file.quality_gates_lambda.output_base64sha256
  
  environment {
    variables = {
      PROJECT_NAME    = var.project_name
      GITHUB_TOKEN    = var.github_token
      SLACK_WEBHOOK   = var.slack_webhook_url
      S3_BUCKET      = aws_s3_bucket.quality_reports.bucket
    }
  }
  
  tags = merge(local.common_tags, {
    Purpose = "quality-gates"
  })
}

data "archive_file" "quality_gates_lambda" {
  type        = "zip"
  output_path = "${path.module}/quality_gates_lambda.zip"
  
  source {
    content = templatefile("${path.module}/lambda/quality_gates.py", {
      project_name = var.project_name
    })
    filename = "index.py"
  }
  
  source {
    content = file("${path.module}/lambda/requirements.txt")
    filename = "requirements.txt"
  }
}

# IAM Role for Quality Gates Lambda
resource "aws_iam_role" "quality_gates_lambda" {
  name = "${var.project_name}-quality-gates-lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy" "quality_gates_lambda" {
  name = "${var.project_name}-quality-gates-lambda-policy"
  role = aws_iam_role.quality_gates_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream", 
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.quality_reports.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.quality_reports.arn
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 Bucket for Quality Reports
resource "aws_s3_bucket" "quality_reports" {
  bucket = "${var.project_name}-quality-reports-${random_string.quality_suffix.result}"
  
  tags = merge(local.common_tags, {
    Purpose = "quality-reports"
  })
}

resource "random_string" "quality_suffix" {
  length  = 8
  special = false
  upper   = false
}

# CodeBuild Projects for Quality Checks
resource "aws_codebuild_project" "terraform_validate" {
  name          = "${var.project_name}-terraform-validate"
  description   = "Terraform validation and formatting checks"
  service_role  = aws_iam_role.codebuild_service.arn
  
  artifacts {
    type = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.project_name}-infrastructure.git"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"
    
    environment_variable {
      name  = "TF_VERSION"
      value = "1.5.0"
    }
  }
  
  source {
    type = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.project_name}-infrastructure.git"
    
    buildspec = templatefile("${path.module}/buildspecs/terraform_validate.yml", {
      project_name = var.project_name
    })
  }
  
  tags = merge(local.common_tags, {
    Purpose = "terraform-validation"
  })
}

resource "aws_codebuild_project" "security_scan" {
  name          = "${var.project_name}-security-scan"
  description   = "Security scanning with tfsec and checkov"
  service_role  = aws_iam_role.codebuild_service.arn
  
  artifacts {
    type = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.project_name}-infrastructure.git"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"
  }
  
  source {
    type = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.project_name}-infrastructure.git"
    
    buildspec = templatefile("${path.module}/buildspecs/security_scan.yml", {
      project_name = var.project_name
      s3_bucket   = aws_s3_bucket.quality_reports.bucket
    })
  }
  
  tags = merge(local.common_tags, {
    Purpose = "security-scanning"
  })
}

resource "aws_codebuild_project" "cost_estimation" {
  name          = "${var.project_name}-cost-estimation"
  description   = "Cost estimation with Infracost"
  service_role  = aws_iam_role.codebuild_service.arn
  
  artifacts {
    type = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.project_name}-infrastructure.git"
  }
  
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type         = "LINUX_CONTAINER"
    
    environment_variable {
      name  = "INFRACOST_API_KEY"
      value = var.infracost_api_key
      type  = "PARAMETER_STORE"
    }
  }
  
  source {
    type = "GITHUB"
    location = "https://github.com/${var.github_organization}/${var.project_name}-infrastructure.git"
    
    buildspec = templatefile("${path.module}/buildspecs/cost_estimation.yml", {
      project_name = var.project_name
      s3_bucket   = aws_s3_bucket.quality_reports.bucket
    })
  }
  
  tags = merge(local.common_tags, {
    Purpose = "cost-estimation"
  })
}

# CodeBuild Service Role
resource "aws_iam_role" "codebuild_service" {
  name = "${var.project_name}-codebuild-service"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy" "codebuild_service" {
  name = "${var.project_name}-codebuild-service-policy"
  role = aws_iam_role.codebuild_service.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.quality_reports.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })
}

# GitHub Webhooks for Quality Gate Triggers
resource "aws_api_gateway_rest_api" "github_webhooks" {
  name        = "${var.project_name}-github-webhooks"
  description = "API Gateway for GitHub webhook integration"
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  tags = local.common_tags
}

resource "aws_api_gateway_resource" "pull_request" {
  rest_api_id = aws_api_gateway_rest_api.github_webhooks.id
  parent_id   = aws_api_gateway_rest_api.github_webhooks.root_resource_id
  path_part   = "pull-request"
}

resource "aws_api_gateway_method" "pull_request_post" {
  rest_api_id   = aws_api_gateway_rest_api.github_webhooks.id
  resource_id   = aws_api_gateway_resource.pull_request.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "pull_request_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.github_webhooks.id
  resource_id             = aws_api_gateway_resource.pull_request.id
  http_method             = aws_api_gateway_method.pull_request_post.http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.terraform_quality_gates.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_quality_gates.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.github_webhooks.execution_arn}/*/*"
}

# Team Performance Metrics
resource "aws_cloudwatch_log_group" "team_metrics" {
  name              = "/aws/lambda/${var.project_name}-team-metrics"
  retention_in_days = 30
  
  tags = local.common_tags
}

resource "aws_lambda_function" "team_metrics_collector" {
  function_name = "${var.project_name}-team-metrics-collector"
  role         = aws_iam_role.team_metrics_lambda.arn
  handler      = "index.handler"
  runtime      = "python3.9"
  timeout      = 300
  
  filename         = data.archive_file.team_metrics_lambda.output_path
  source_code_hash = data.archive_file.team_metrics_lambda.output_base64sha256
  
  environment {
    variables = {
      PROJECT_NAME = var.project_name
      GITHUB_TOKEN = var.github_token
      S3_BUCKET   = aws_s3_bucket.quality_reports.bucket
    }
  }
  
  tags = merge(local.common_tags, {
    Purpose = "team-metrics"
  })
}

data "archive_file" "team_metrics_lambda" {
  type        = "zip"
  output_path = "${path.module}/team_metrics_lambda.zip"
  
  source {
    content = templatefile("${path.module}/lambda/team_metrics.py", {
      project_name = var.project_name
    })
    filename = "index.py"
  }
}

resource "aws_iam_role" "team_metrics_lambda" {
  name = "${var.project_name}-team-metrics-lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# Scheduled execution for team metrics collection
resource "aws_cloudwatch_event_rule" "team_metrics_schedule" {
  name                = "${var.project_name}-team-metrics-schedule"
  description         = "Daily team metrics collection"
  schedule_expression = "cron(0 9 * * ? *)"  # 9 AM daily
  
  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "team_metrics_target" {
  rule      = aws_cloudwatch_event_rule.team_metrics_schedule.name
  target_id = "TeamMetricsLambdaTarget"
  arn       = aws_lambda_function.team_metrics_collector.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_team_metrics" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.team_metrics_collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.team_metrics_schedule.arn
}
```

### 3. Documentation and Knowledge Management

```hcl
# examples/03-documentation/main.tf

# Documentation Generation Infrastructure
resource "aws_s3_bucket" "documentation" {
  bucket = "${var.project_name}-infrastructure-docs-${random_string.docs_suffix.result}"
  
  tags = merge(local.common_tags, {
    Purpose = "documentation"
  })
}

resource "random_string" "docs_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_website_configuration" "documentation" {
  bucket = aws_s3_bucket.documentation.id
  
  index_document {
    suffix = "index.html"
  }
  
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "documentation" {
  bucket = aws_s3_bucket.documentation.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "documentation" {
  bucket = aws_s3_bucket.documentation.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.documentation.arn}/*"
      }
    ]
  })
  
  depends_on = [aws_s3_bucket_public_access_block.documentation]
}

# CloudFront Distribution for Documentation
resource "aws_cloudfront_distribution" "documentation" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.documentation.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.documentation.bucket}"
    
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  aliases = ["docs.${var.domain_name}"]
  
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.documentation.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  
  price_class = "PriceClass_100"
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.documentation.arn
    ssl_support_method  = "sni-only"
  }
  
  tags = merge(local.common_tags, {
    Purpose = "documentation-cdn"
  })
}

# SSL Certificate for Documentation Site
resource "aws_acm_certificate" "documentation" {
  provider    = aws.us_east_1  # CloudFront requires certificates in us-east-1
  domain_name = "docs.${var.domain_name}"
  
  validation_method = "DNS"
  
  lifecycle {
    create_before_destroy = true
  }
  
  tags = merge(local.common_tags, {
    Purpose = "documentation-ssl"
  })
}

# Documentation Generation Lambda
resource "aws_lambda_function" "docs_generator" {
  function_name = "${var.project_name}-docs-generator"
  role         = aws_iam_role.docs_generator_lambda.arn
  handler      = "index.handler"
  runtime      = "python3.9"
  timeout      = 900  # 15 minutes for documentation generation
  memory_size  = 1024
  
  filename         = data.archive_file.docs_generator_lambda.output_path
  source_code_hash = data.archive_file.docs_generator_lambda.output_base64sha256
  
  environment {
    variables = {
      PROJECT_NAME      = var.project_name
      GITHUB_TOKEN      = var.github_token
      S3_BUCKET        = aws_s3_bucket.documentation.bucket
      CLOUDFRONT_ID    = aws_cloudfront_distribution.documentation.id
      TERRAFORM_DOCS_VERSION = "0.16.0"
    }
  }
  
  tags = merge(local.common_tags, {
    Purpose = "documentation-generation"
  })
}

data "archive_file" "docs_generator_lambda" {
  type        = "zip"
  output_path = "${path.module}/docs_generator_lambda.zip"
  
  source {
    content = templatefile("${path.module}/lambda/docs_generator.py", {
      project_name = var.project_name
    })
    filename = "index.py"
  }
  
  source {
    content = file("${path.module}/lambda/docs_requirements.txt")
    filename = "requirements.txt"
  }
}

resource "aws_iam_role" "docs_generator_lambda" {
  name = "${var.project_name}-docs-generator-lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

resource "aws_iam_role_policy" "docs_generator_lambda" {
  name = "${var.project_name}-docs-generator-lambda-policy"
  role = aws_iam_role.docs_generator_lambda.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.documentation.arn,
          "${aws_s3_bucket.documentation.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = aws_cloudfront_distribution.documentation.arn
      }
    ]
  })
}

# Knowledge Base Wiki Infrastructure
resource "aws_lambda_function" "wiki_search" {
  function_name = "${var.project_name}-wiki-search"
  role         = aws_iam_role.wiki_search_lambda.arn
  handler      = "index.handler"
  runtime      = "python3.9"
  timeout      = 30
  
  filename         = data.archive_file.wiki_search_lambda.output_path
  source_code_hash = data.archive_file.wiki_search_lambda.output_base64sha256
  
  environment {
    variables = {
      OPENSEARCH_ENDPOINT = aws_opensearch_domain.knowledge_base.endpoint
    }
  }
  
  tags = merge(local.common_tags, {
    Purpose = "wiki-search"
  })
}

data "archive_file" "wiki_search_lambda" {
  type        = "zip"
  output_path = "${path.module}/wiki_search_lambda.zip"
  
  source {
    content = templatefile("${path.module}/lambda/wiki_search.py", {
      project_name = var.project_name
    })
    filename = "index.py"
  }
}

resource "aws_iam_role" "wiki_search_lambda" {
  name = "${var.project_name}-wiki-search-lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}

# OpenSearch Domain for Knowledge Base Search
resource "aws_opensearch_domain" "knowledge_base" {
  domain_name    = "${var.project_name}-knowledge-base"
  engine_version = "OpenSearch_2.3"
  
  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }
  
  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }
  
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action   = "es:*"
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.project_name}-knowledge-base/*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = var.allowed_ips
          }
        }
      }
    ]
  })
  
  tags = merge(local.common_tags, {
    Purpose = "knowledge-base-search"
  })
}

data "aws_caller_identity" "current" {}

# Automated Documentation Updates
resource "aws_cloudwatch_event_rule" "docs_update_schedule" {
  name                = "${var.project_name}-docs-update-schedule"
  description         = "Trigger documentation updates on repository changes"
  
  event_pattern = jsonencode({
    source        = ["aws.codecommit"]
    "detail-type" = ["CodeCommit Repository State Change"]
    detail = {
      event = ["referenceCreated", "referenceUpdated"]
      referenceName = ["main"]
    }
  })
  
  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "docs_update_target" {
  rule      = aws_cloudwatch_event_rule.docs_update_schedule.name
  target_id = "DocsGeneratorLambdaTarget"
  arn       = aws_lambda_function.docs_generator.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_docs" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.docs_generator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.docs_update_schedule.arn
}

# Team Onboarding Automation
resource "aws_lambda_function" "onboarding_automation" {
  function_name = "${var.project_name}-onboarding-automation"
  role         = aws_iam_role.onboarding_lambda.arn
  handler      = "index.handler"
  runtime      = "python3.9"
  timeout      = 300
  
  filename         = data.archive_file.onboarding_lambda.output_path
  source_code_hash = data.archive_file.onboarding_lambda.output_base64sha256
  
  environment {
    variables = {
      PROJECT_NAME     = var.project_name
      GITHUB_TOKEN     = var.github_token
      SLACK_WEBHOOK    = var.slack_webhook_url
      DOCS_URL        = "https://docs.${var.domain_name}"
      WIKI_URL        = "https://wiki.${var.domain_name}"
    }
  }
  
  tags = merge(local.common_tags, {
    Purpose = "team-onboarding"
  })
}

data "archive_file" "onboarding_lambda" {
  type        = "zip"
  output_path = "${path.module}/onboarding_lambda.zip"
  
  source {
    content = templatefile("${path.module}/lambda/onboarding.py", {
      project_name = var.project_name
    })
    filename = "index.py"
  }
}

resource "aws_iam_role" "onboarding_lambda" {
  name = "${var.project_name}-onboarding-lambda"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = local.common_tags
}
```

## 🔗 Software Engineering Connections

### Collaboration Patterns in Infrastructure

#### 1. Git Workflow → Infrastructure Workflow
**Software Development:**
```bash
# Feature development workflow
git checkout -b feature/user-authentication
# Develop and test feature
git add src/auth/
git commit -m "Add JWT authentication with refresh tokens"
git push origin feature/user-authentication
# Create pull request
gh pr create --title "Add user authentication system" \
  --body "Implements JWT-based authentication with security best practices"
# Code review → merge → CI/CD deployment
```

**Infrastructure Equivalent:**
```bash
# Infrastructure development workflow
git checkout -b infrastructure/add-redis-caching
# Develop and test infrastructure
terraform workspace new feature-redis
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
# Test infrastructure functionality
git add modules/redis/
git commit -m "Add Redis cluster for session caching with high availability"
git push origin infrastructure/add-redis-caching
# Create pull request
gh pr create --title "Add Redis caching infrastructure" \
  --body "Implements Redis cluster with automatic failover and monitoring"
# Infrastructure review → merge → environment promotion
```

#### 2. Code Review → Infrastructure Review
**Software Development:**
```markdown
# Pull Request Review Template
## Code Review Checklist
- [ ] Code follows style guidelines
- [ ] Tests are included and passing
- [ ] Documentation is updated
- [ ] Security considerations addressed
- [ ] Performance impact assessed
- [ ] Breaking changes documented

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Security
- [ ] Input validation implemented
- [ ] Authentication/authorization checked
- [ ] Data sanitization verified
```

**Infrastructure Equivalent:**
```markdown
# Infrastructure Review Checklist
## Infrastructure Review
- [ ] Terraform code follows conventions
- [ ] Security groups follow least privilege
- [ ] Cost impact estimated and approved
- [ ] Backup and monitoring configured
- [ ] Multi-AZ deployment for production resources
- [ ] Tags applied consistently

## Validation
- [ ] `terraform validate` passes
- [ ] `terraform plan` reviewed
- [ ] Security scan (tfsec) passes
- [ ] Cost estimation acceptable

## Security
- [ ] IAM policies follow least privilege
- [ ] Encryption at rest and in transit
- [ ] Network security properly configured
- [ ] Secrets managed securely
```

#### 3. Documentation as Code → Infrastructure Documentation
**Software Development:**
```typescript
/**
 * User Authentication Service
 * 
 * Handles user login, registration, and token management.
 * Uses JWT tokens with refresh token rotation for security.
 * 
 * @example
 * ```typescript
 * const authService = new AuthService(config);
 * const result = await authService.login(email, password);
 * if (result.success) {
 *   console.log('User logged in:', result.user);
 * }
 * ```
 */
class AuthService {
  /**
   * Authenticates a user with email and password
   * @param email - User's email address
   * @param password - User's password
   * @returns Promise containing authentication result
   */
  async login(email: string, password: string): Promise<AuthResult> {
    // Implementation
  }
}
```

**Infrastructure Equivalent:**
```hcl
/**
 * Redis Cluster Module
 * 
 * Creates a highly available Redis cluster for caching and session storage.
 * Includes automatic failover, monitoring, and backup configuration.
 * 
 * @example
 * ```hcl
 * module "redis_cluster" {
 *   source = "./modules/redis-cluster"
 *   
 *   name_prefix     = "myapp-prod"
 *   node_type      = "cache.r6g.large"
 *   num_cache_nodes = 3
 *   
 *   vpc_id     = module.vpc.vpc_id
 *   subnet_ids = module.vpc.private_subnet_ids
 * }
 * ```
 */

variable "node_type" {
  description = "The instance type for Redis nodes (e.g., cache.r6g.large)"
  type        = string
  
  validation {
    condition = can(regex("^cache\\.", var.node_type))
    error_message = "Node type must be a valid ElastiCache instance type."
  }
}

/**
 * Creates the Redis replication group with high availability
 */
resource "aws_elasticache_replication_group" "redis" {
  description          = "Redis cluster for ${var.name_prefix}"
  replication_group_id = "${var.name_prefix}-redis"
  
  node_type               = var.node_type
  num_cache_clusters      = var.num_cache_nodes
  port                   = 6379
  parameter_group_name   = aws_elasticache_parameter_group.redis.name
  subnet_group_name      = aws_elasticache_subnet_group.redis.name
  security_group_ids     = [aws_security_group.redis.id]
  
  # High availability configuration
  automatic_failover_enabled = true
  multi_az_enabled           = true
  
  # Backup and maintenance
  snapshot_retention_limit = 7
  snapshot_window         = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"
  
  tags = var.tags
}
```

## 🎯 Hands-on Examples

### Exercise 1: Implement Git-Based Infrastructure Workflow

**Objective:** Create a complete Git workflow for infrastructure collaboration with automated quality gates

**Requirements:**
- Branch protection rules with required reviews
- Automated validation and security scanning
- Environment-specific deployment approvals
- Team notification and communication

**Steps:**
1. Set up GitHub repository with branch protection
2. Configure automated CI/CD pipeline with quality gates
3. Implement code review requirements and templates
4. Set up team notifications and alerts
5. Test the complete workflow with a sample infrastructure change

### Exercise 2: Build Documentation and Knowledge Management System

**Objective:** Create an automated documentation system that generates and maintains infrastructure documentation

**Requirements:**
- Automated documentation generation from Terraform code
- Searchable knowledge base for team decisions and runbooks
- Team onboarding automation and documentation
- Performance metrics and team analytics

**Steps:**
1. Set up automated documentation generation with terraform-docs
2. Implement searchable knowledge base with OpenSearch
3. Create team onboarding automation
4. Build performance dashboards and metrics collection
5. Test documentation updates and search functionality

### Exercise 3: Establish Team Performance and Quality Metrics

**Objective:** Implement comprehensive team metrics and quality monitoring for infrastructure development

**Requirements:**
- Infrastructure change velocity and quality metrics
- Code review and collaboration analytics
- Cost impact tracking per team and project
- Security and compliance metrics

**Steps:**
1. Implement team metrics collection from GitHub and AWS
2. Set up quality gates and automated quality checks
3. Create team performance dashboards
4. Configure alerting for quality and security issues
5. Generate regular team performance reports

## ✅ Best Practices

### 1. Git Workflow Standards

#### Branch Protection Configuration
```yaml
# .github/branch-protection.yml
protection_rules:
  main:
    required_status_checks:
      strict: true
      contexts:
        - "terraform/validate"
        - "terraform/plan"
        - "security/tfsec"
        - "cost/estimate"
    
    required_pull_request_reviews:
      required_approving_review_count: 2
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
      require_last_push_approval: true
    
    enforce_admins: true
    allow_force_pushes: false
    allow_deletions: false
    required_linear_history: true
```

#### Commit Message Standards
```bash
# Infrastructure commit message format
git commit -m "feat(vpc): add multi-AZ VPC with private subnets

- Add VPC module with 3 availability zones
- Implement private subnets for database tier
- Configure NAT gateways for outbound internet access
- Add comprehensive tagging for cost allocation

Closes #123"
```

### 2. Code Review Process

#### Review Assignment Automation
```
# .github/CODEOWNERS
# Global infrastructure reviewers
* @infrastructure-team

# Network changes require network team review
modules/vpc/ @network-team @infrastructure-team
modules/security/ @security-team @infrastructure-team

# Database changes require DBA review
modules/database/ @dba-team @infrastructure-team

# Cost-sensitive resources require FinOps review
modules/compute/ @finops-team @infrastructure-team
```

#### Review Checklist Template
```markdown
## Infrastructure Review Checklist

### Security
- [ ] IAM policies follow least privilege principle
- [ ] Security groups have minimal required access
- [ ] Encryption enabled for data at rest and in transit
- [ ] Secrets are properly managed (not hardcoded)

### Cost Optimization
- [ ] Instance types appropriate for workload
- [ ] Auto-scaling configured where applicable
- [ ] Reserved capacity considered for predictable workloads
- [ ] Lifecycle policies configured for storage

### Reliability
- [ ] Multi-AZ deployment for production resources
- [ ] Backup and recovery procedures implemented
- [ ] Monitoring and alerting configured
- [ ] Health checks and auto-recovery enabled

### Documentation
- [ ] Module documentation updated
- [ ] README reflects changes
- [ ] Runbooks updated if necessary
- [ ] Architecture diagrams current
```

### 3. Documentation Standards

#### Module Documentation Template
```markdown
# Module: VPC

## Overview
Creates a VPC with public and private subnets across multiple availability zones.

## Usage
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix        = "myapp-prod"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = false
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Architecture

![VPC Architecture](./diagrams/vpc-architecture.png)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for all resource names | `string` | n/a | yes |
| vpc_cidr | CIDR block for VPC | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| public_subnet_ids | IDs of public subnets |

## Examples

### Basic VPC
[Link to basic example](./examples/basic-vpc/)

### VPC with VPN
[Link to VPN example](./examples/vpc-with-vpn/)

## Changelog

### v1.2.0 (2024-01-15)
- Added support for IPv6
- Improved tagging consistency
- Fixed NAT gateway cost optimization
```

### 4. Team Communication

#### Notification Configuration
```hcl
# Infrastructure notifications
resource "aws_sns_topic" "infrastructure_alerts" {
  name = "infrastructure-team-alerts"
  
  tags = {
    Team    = "infrastructure"
    Purpose = "team-communication"
  }
}

# Slack integration
resource "aws_sns_topic_subscription" "slack" {
  topic_arn = aws_sns_topic.infrastructure_alerts.arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# Critical email alerts
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.team_emails)
  topic_arn = aws_sns_topic.infrastructure_alerts.arn
  protocol  = "email"
  endpoint  = var.team_emails[count.index]
}
```

#### Automated Status Updates
```python
# Lambda function for automated status updates
import json
import boto3
import requests

def lambda_handler(event, context):
    """Send infrastructure status updates to team channels"""
    
    # Parse CloudWatch alarm
    message = json.loads(event['Records'][0]['Sns']['Message'])
    
    slack_message = {
        "text": f"🚨 Infrastructure Alert: {message['AlarmName']}",
        "attachments": [
            {
                "color": "danger" if message['NewStateValue'] == 'ALARM' else "good",
                "fields": [
                    {
                        "title": "Status",
                        "value": message['NewStateValue'],
                        "short": True
                    },
                    {
                        "title": "Reason",
                        "value": message['NewStateReason'],
                        "short": True
                    }
                ]
            }
        ]
    }
    
    # Send to Slack
    response = requests.post(
        os.environ['SLACK_WEBHOOK'],
        json=slack_message
    )
    
    return {'statusCode': 200}
```

## ⚠️ Common Pitfalls

### 1. Inadequate Code Review Process
**Problem:** Insufficient review depth leading to quality and security issues

**Solution:**
- Implement mandatory security and cost reviews
- Use automated quality gates to catch issues early
- Require domain expert approval for specialized changes
- Train team members on effective review techniques

### 2. Poor Documentation Maintenance
**Problem:** Documentation becomes outdated and unreliable

**Solution:**
- Automate documentation generation where possible
- Include documentation updates in definition of done
- Regular documentation review and cleanup sessions
- Make documentation part of the deployment pipeline

### 3. Lack of Team Coordination
**Problem:** Team members working in isolation leading to conflicts and duplicated effort

**Solution:**
- Implement regular team sync meetings
- Use shared project boards and issue tracking
- Establish clear ownership and responsibility areas
- Create communication channels for different types of discussions

### 4. Inconsistent Standards and Practices
**Problem:** Different team members following different approaches

**Solution:**
- Document and enforce coding standards
- Use automated linting and formatting tools
- Regular team training and knowledge sharing sessions
- Code review checklists and templates

## 🔍 Troubleshooting

### Git Workflow Issues

**Problem:** Merge conflicts in Terraform state or configuration

**Diagnosis:**
```bash
# Check for state conflicts
terraform plan -detailed-exitcode

# Compare branch differences
git diff main..feature-branch

# Check for resource conflicts
terraform state list
```

**Solutions:**
1. Use separate state files for different components
2. Coordinate changes through team communication
3. Use feature flags for gradual rollouts
4. Implement proper dependency management

### Communication and Notification Problems

**Problem:** Team members not receiving important infrastructure alerts

**Diagnosis:**
```bash
# Check SNS topic subscriptions
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:region:account:topic

# Test notification delivery
aws sns publish --topic-arn arn:aws:sns:region:account:topic --message "Test message"

# Check CloudWatch alarm configurations
aws cloudwatch describe-alarms --state-value ALARM
```

**Solutions:**
1. Verify notification endpoints and permissions
2. Test notification delivery regularly
3. Use multiple notification channels for redundancy
4. Implement escalation procedures for critical alerts

### Documentation and Knowledge Management Issues

**Problem:** Team unable to find or access infrastructure documentation

**Diagnosis:**
```bash
# Check documentation site availability
curl -I https://docs.internal.company.com

# Verify search functionality
curl -X GET "https://search.internal.company.com/_search?q=vpc"

# Check documentation generation pipeline
aws logs describe-log-groups --log-group-name-prefix "/aws/lambda/docs-generator"
```

**Solutions:**
1. Ensure documentation infrastructure is properly configured
2. Implement automated documentation updates
3. Create clear navigation and search capabilities
4. Regular documentation quality reviews

## 📚 Further Reading

### Team Collaboration and Workflows
- [Git Workflows for Teams](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [Code Review Best Practices](https://smartbear.com/learn/code-review/best-practices-for-peer-code-review/)
- [Documentation as Code](https://docs-as-co.de/)

### Infrastructure Collaboration
- [Infrastructure as Code Team Practices](https://infrastructure-as-code.com/team/)
- [Terraform Team Workflows](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [GitOps Principles](https://www.gitops.tech/)

### Agile and DevOps Practices
- [DevOps Team Structures](https://web.devopstopologies.com/)
- [Agile Infrastructure Management](https://agilemanifesto.org/)
- [Continuous Integration for Infrastructure](https://martinfowler.com/articles/continuousIntegration.html)

### Communication and Knowledge Management
- [Effective Technical Communication](https://pragprog.com/titles/7speaking/presentation-zen/)
- [Building Learning Organizations](https://www.amazon.com/Fifth-Discipline-Practice-Learning-Organization/dp/0385517254)
- [Knowledge Management for DevOps](https://itrevolution.com/the-devops-handbook/)

## 🎯 Next Steps

Congratulations! You've completed the comprehensive Terraform Fundamentals learning journey. You now have mastered:

- **Team Collaboration Workflows**: Git-based infrastructure development with quality gates
- **Code Review Processes**: Structured review workflows ensuring quality and knowledge sharing
- **Documentation Standards**: Automated documentation and knowledge management systems
- **Communication Systems**: Team coordination and notification infrastructure
- **Performance Metrics**: Team analytics and continuous improvement processes

### 🎓 Complete Skill Set Achieved

Having completed all 10 modules, you now possess:

✅ **Infrastructure as Code Mastery**
- State management and team collaboration
- Modular architecture and clean code principles
- Security implementation and defense-in-depth
- Cost optimization and resource management
- Environment management and DevOps pipelines

✅ **Advanced Infrastructure Patterns**
- Scalability and system design patterns
- Observability and monitoring engineering
- Disaster recovery and business continuity
- Compliance and governance frameworks
- Team collaboration and software workflows

✅ **Professional Development Skills**
- Enterprise-scale infrastructure design
- Leadership and architectural thinking
- Team coordination and knowledge sharing
- Quality assurance and best practices
- Continuous learning and improvement

### 💼 Career Advancement Opportunities

With these comprehensive skills, you're qualified for senior roles:

- **Senior DevOps Engineer** ($130k-$190k): Lead infrastructure automation initiatives
- **Principal Infrastructure Engineer** ($160k-$230k): Architect enterprise infrastructure solutions
- **Cloud Solutions Architect** ($150k-$220k): Design multi-cloud architectures
- **Platform Engineering Manager** ($170k-$250k): Lead platform engineering teams
- **Site Reliability Engineering Lead** ($180k-$260k): Build and lead SRE practices
- **DevOps Architect** ($160k-$240k): Define organizational DevOps strategies

### 🚀 Next Level Learning

Continue your growth with:
- **Advanced Cloud Architectures**: Multi-cloud and hybrid solutions
- **Kubernetes and Container Orchestration**: Modern application platforms
- **Infrastructure Security**: Advanced security architecture and zero-trust
- **Platform Engineering**: Building developer experience platforms
- **Leadership Development**: Technical leadership and team management

**🎉 Congratulations on completing this comprehensive learning journey!** You've built the expertise to tackle complex infrastructure challenges and lead teams in modern cloud-native environments.