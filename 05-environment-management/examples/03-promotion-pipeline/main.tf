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
    tags = local.common_tags
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  # Common tags for all resources
  common_tags = merge(var.default_tags, {
    Module     = "promotion-pipeline"
    Purpose    = "environment-promotion-automation"
    Account    = local.account_id
    Region     = local.region
  })

  # Pipeline configuration
  pipeline_name = "${var.project_name}-promotion-pipeline"
  
  # Source configuration
  source_location = var.github_repo != "" ? var.github_repo : var.codecommit_repo_name

  # Environment promotion stages
  promotion_stages = [
    {
      name        = "Source"
      category    = "Source"
      provider    = var.github_repo != "" ? "GitHub" : "CodeCommit"
      version     = "1"
    },
    {
      name        = "ValidateAndPlan"
      category    = "Build"
      provider    = "CodeBuild"
      version     = "1"
      environment = "dev"
    },
    {
      name        = "DeployToDev"
      category    = "Build"
      provider    = "CodeBuild"
      version     = "1"
      environment = "dev"
    },
    {
      name        = "ApprovalForStaging"
      category    = "Approval"
      provider    = "Manual"
      version     = "1"
    },
    {
      name        = "DeployToStaging"
      category    = "Build"
      provider    = "CodeBuild"
      version     = "1"
      environment = "staging"
    },
    {
      name        = "IntegrationTests"
      category    = "Test"
      provider    = "CodeBuild"
      version     = "1"
      environment = "staging"
    },
    {
      name        = "ApprovalForProduction"
      category    = "Approval"
      provider    = "Manual"
      version     = "1"
    },
    {
      name        = "DeployToProduction"
      category    = "Build"
      provider    = "CodeBuild"
      version     = "1"
      environment = "prod"
    }
  ]
}

# S3 bucket for CodePipeline artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = "${var.project_name}-pipeline-artifacts-${local.account_id}-${local.region}"
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-pipeline-artifacts"
    Type = "pipeline-storage"
  })
}

resource "aws_s3_bucket_versioning" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket = aws_s3_bucket.pipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CodeCommit repository (if not using GitHub)
resource "aws_codecommit_repository" "main" {
  count = var.codecommit_repo_name != "" ? 1 : 0

  repository_name = var.codecommit_repo_name
  description     = "Repository for ${var.project_name} infrastructure code"

  tags = merge(local.common_tags, {
    Name = var.codecommit_repo_name
    Type = "source-control"
  })
}

# IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:GetRepository",
          "codecommit:ListBranches",
          "codecommit:ListRepositories"
        ]
        Resource = var.codecommit_repo_name != "" ? aws_codecommit_repository.main[0].arn : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.pipeline_notifications.arn
      }
    ]
  })
}

# IAM role for CodeBuild
resource "aws_iam_role" "codebuild_role" {
  name = "${var.project_name}-codebuild-role"

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

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.project_name}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

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
        Resource = "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.pipeline_artifacts.arn,
          "${aws_s3_bucket.pipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "iam:*",
          "s3:*",
          "rds:*",
          "cloudwatch:*",
          "logs:*",
          "ssm:*",
          "route53:*",
          "acm:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "*"
      }
    ]
  })
}

# CodeBuild project for validation and planning
resource "aws_codebuild_project" "validate_plan" {
  name         = "${var.project_name}-validate-plan"
  description  = "Validate and plan Terraform changes"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VAR_environment"
      value = "dev"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-validate.yml"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-validate-plan"
    Type = "validation"
  })
}

# CodeBuild project for deployment to dev
resource "aws_codebuild_project" "deploy_dev" {
  name         = "${var.project_name}-deploy-dev"
  description  = "Deploy to development environment"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VAR_environment"
      value = "dev"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "dev"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-deploy-dev"
    Type = "deployment"
    Environment = "dev"
  })
}

# CodeBuild project for deployment to staging
resource "aws_codebuild_project" "deploy_staging" {
  name         = "${var.project_name}-deploy-staging"
  description  = "Deploy to staging environment"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VAR_environment"
      value = "staging"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "staging"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-deploy-staging"
    Type = "deployment"
    Environment = "staging"
  })
}

# CodeBuild project for integration tests
resource "aws_codebuild_project" "integration_tests" {
  name         = "${var.project_name}-integration-tests"
  description  = "Run integration tests against staging"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TEST_ENVIRONMENT"
      value = "staging"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-test.yml"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-integration-tests"
    Type = "testing"
  })
}

# CodeBuild project for deployment to production
resource "aws_codebuild_project" "deploy_prod" {
  name         = "${var.project_name}-deploy-prod"
  description  = "Deploy to production environment"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type                       = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_VAR_environment"
      value = "prod"
    }

    environment_variable {
      name  = "ENVIRONMENT"
      value = "prod"
    }
  }

  source {
    type = "CODEPIPELINE"
    buildspec = "buildspec-deploy.yml"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-deploy-prod"
    Type = "deployment"
    Environment = "prod"
  })
}

# SNS topic for pipeline notifications
resource "aws_sns_topic" "pipeline_notifications" {
  name = "${var.project_name}-pipeline-notifications"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-pipeline-notifications"
    Type = "notifications"
  })
}

resource "aws_sns_topic_subscription" "email_notifications" {
  count = var.notification_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.pipeline_notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# EventBridge rule for pipeline state changes
resource "aws_cloudwatch_event_rule" "pipeline_state_change" {
  name        = "${var.project_name}-pipeline-state-change"
  description = "Capture pipeline state changes"

  event_pattern = jsonencode({
    source      = ["aws.codepipeline"]
    detail-type = ["CodePipeline Pipeline Execution State Change"]
    detail = {
      pipeline = [aws_codepipeline.main.name]
    }
  })

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.pipeline_state_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.pipeline_notifications.arn

  input_transformer {
    input_paths = {
      pipeline = "$.detail.pipeline"
      state    = "$.detail.state"
      region   = "$.region"
      time     = "$.time"
    }
    input_template = jsonencode({
      message = "Pipeline <pipeline> in region <region> changed state to <state> at <time>"
      pipeline = "<pipeline>"
      state    = "<state>"
      timestamp = "<time>"
    })
  }
}

# CodePipeline
resource "aws_codepipeline" "main" {
  name     = local.pipeline_name
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.pipeline_artifacts.bucket
    type     = "S3"
  }

  # Source stage
  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = var.github_repo != "" ? "ThirdParty" : "AWS"
      provider         = var.github_repo != "" ? "GitHub" : "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = var.github_repo != "" ? {
        Owner      = split("/", var.github_repo)[0]
        Repo       = split("/", var.github_repo)[1]
        Branch     = var.source_branch
        OAuthToken = var.github_token
      } : {
        RepositoryName = var.codecommit_repo_name
        BranchName     = var.source_branch
      }
    }
  }

  # Validate and Plan stage
  stage {
    name = "ValidateAndPlan"

    action {
      name             = "ValidateAndPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["validate_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.validate_plan.name
      }
    }
  }

  # Deploy to Dev stage
  stage {
    name = "DeployToDev"

    action {
      name             = "DeployToDev"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["dev_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy_dev.name
      }
    }
  }

  # Manual approval for staging
  stage {
    name = "ApprovalForStaging"

    action {
      name     = "ApprovalForStaging"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Please review the dev deployment and approve for staging promotion."
        ExternalEntityLink = "https://${local.region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${local.pipeline_name}/view"
      }
    }
  }

  # Deploy to Staging stage
  stage {
    name = "DeployToStaging"

    action {
      name             = "DeployToStaging"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["staging_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy_staging.name
      }
    }
  }

  # Integration Tests stage
  stage {
    name = "IntegrationTests"

    action {
      name            = "IntegrationTests"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.integration_tests.name
      }
    }
  }

  # Manual approval for production
  stage {
    name = "ApprovalForProduction"

    action {
      name     = "ApprovalForProduction"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Please review staging deployment and integration tests. Approve for production deployment."
        ExternalEntityLink = "https://${local.region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${local.pipeline_name}/view"
      }
    }
  }

  # Deploy to Production stage
  stage {
    name = "DeployToProduction"

    action {
      name             = "DeployToProduction"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["prod_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy_prod.name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = local.pipeline_name
    Type = "ci-cd-pipeline"
  })
}

# CloudWatch dashboard for pipeline monitoring
resource "aws_cloudwatch_dashboard" "pipeline_monitoring" {
  dashboard_name = "${var.project_name}-pipeline-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/codebuild/${aws_codebuild_project.validate_plan.name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = local.region
          title   = "Recent Build Logs"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CodePipeline", "PipelineExecutionSuccess", "PipelineName", aws_codepipeline.main.name],
            [".", "PipelineExecutionFailure", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = local.region
          title   = "Pipeline Execution Results"
          period  = 300
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-pipeline-dashboard"
    Type = "monitoring"
  })
}