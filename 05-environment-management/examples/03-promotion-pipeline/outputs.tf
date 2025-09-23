output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.main.arn
}

output "pipeline_url" {
  description = "URL to view the pipeline in AWS Console"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.main.name}/view"
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket storing pipeline artifacts"
  value       = aws_s3_bucket.pipeline_artifacts.bucket
}

output "codecommit_repository_url" {
  description = "URL of the CodeCommit repository (if created)"
  value       = var.codecommit_repo_name != "" ? aws_codecommit_repository.main[0].clone_url_http : null
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for pipeline notifications"
  value       = aws_sns_topic.pipeline_notifications.arn
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard for pipeline monitoring"
  value       = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.pipeline_monitoring.dashboard_name}"
}

# CodeBuild Projects
output "codebuild_projects" {
  description = "Information about CodeBuild projects"
  value = {
    validate_plan = {
      name = aws_codebuild_project.validate_plan.name
      arn  = aws_codebuild_project.validate_plan.arn
      url  = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.validate_plan.name}"
    }
    deploy_dev = {
      name = aws_codebuild_project.deploy_dev.name
      arn  = aws_codebuild_project.deploy_dev.arn
      url  = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.deploy_dev.name}"
    }
    deploy_staging = {
      name = aws_codebuild_project.deploy_staging.name
      arn  = aws_codebuild_project.deploy_staging.arn
      url  = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.deploy_staging.name}"
    }
    integration_tests = {
      name = aws_codebuild_project.integration_tests.name
      arn  = aws_codebuild_project.integration_tests.arn
      url  = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.integration_tests.name}"
    }
    deploy_prod = {
      name = aws_codebuild_project.deploy_prod.name
      arn  = aws_codebuild_project.deploy_prod.arn
      url  = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codebuild/projects/${aws_codebuild_project.deploy_prod.name}"
    }
  }
}

# Pipeline Configuration Summary
output "pipeline_configuration" {
  description = "Summary of pipeline configuration and workflow"
  value = {
    pipeline_overview = {
      name                = aws_codepipeline.main.name
      source_type         = var.github_repo != "" ? "GitHub" : "CodeCommit"
      source_location     = var.github_repo != "" ? var.github_repo : var.codecommit_repo_name
      branch              = var.source_branch
      manual_approvals    = var.enable_manual_approvals
      integration_tests   = var.enable_integration_tests
    }

    promotion_workflow = {
      stage_1 = "Source: Code checkout from repository"
      stage_2 = "Validate: Terraform validation and plan generation"
      stage_3 = "Deploy Dev: Automatic deployment to development"
      stage_4 = "Approval: Manual review for staging promotion"
      stage_5 = "Deploy Staging: Automatic deployment to staging"
      stage_6 = "Tests: Integration testing against staging"
      stage_7 = "Approval: Manual review for production promotion"
      stage_8 = "Deploy Prod: Automatic deployment to production"
    }

    environments = {
      dev = {
        automatic_deployment = true
        approval_required    = false
        testing_included     = false
        rollback_strategy    = "terraform destroy and redeploy"
      }
      staging = {
        automatic_deployment = true
        approval_required    = true
        testing_included     = true
        rollback_strategy    = "terraform plan and apply previous version"
      }
      prod = {
        automatic_deployment = false
        approval_required    = true
        testing_included     = false
        rollback_strategy    = "manual intervention required"
      }
    }
  }
}

# Deployment Strategy
output "deployment_strategy" {
  description = "Deployment strategy and best practices implemented"
  value = {
    promotion_gates = {
      dev_to_staging = [
        "Successful dev deployment",
        "Manual approval with review",
        "Code quality validation"
      ]
      staging_to_prod = [
        "Successful staging deployment",
        "Integration tests passed",
        "Manual approval with review",
        "Change management approval"
      ]
    }

    safety_measures = [
      "Terraform plan validation before apply",
      "Manual approval gates for environment promotion",
      "Integration testing in staging environment",
      "Separate IAM roles per environment",
      "Artifact encryption and versioning",
      "Pipeline state monitoring and alerting"
    ]

    rollback_procedures = {
      development = "Quick destroy and redeploy from source"
      staging     = "Terraform plan with previous version and apply"
      production  = "Emergency rollback with manual intervention"
    }

    monitoring_and_alerts = {
      pipeline_monitoring = "CloudWatch dashboard with build logs and metrics"
      state_change_alerts = "SNS notifications for pipeline state changes"
      failure_notifications = "Email alerts for failed deployments"
      success_notifications = "Email alerts for successful production deployments"
    }
  }
}

# Build and Test Configuration
output "build_configuration" {
  description = "Build and test configuration details"
  value = {
    build_environment = {
      compute_type     = var.codebuild_compute_type
      terraform_version = var.terraform_version
      base_image      = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
      build_timeout   = "${var.deployment_timeout} minutes"
    }

    build_stages = {
      validation = {
        purpose      = "Validate Terraform syntax and generate plan"
        environment  = "dev (for validation)"
        buildspec   = "buildspec-validate.yml"
        outputs     = ["Terraform plan", "Validation report"]
      }
      deployment = {
        purpose      = "Deploy infrastructure to target environment"
        environments = var.environments
        buildspec   = "buildspec-deploy.yml"
        outputs     = ["Terraform state", "Resource outputs"]
      }
      testing = {
        purpose      = "Run integration tests against deployed infrastructure"
        environment  = "staging"
        buildspec   = "buildspec-test.yml"
        outputs     = ["Test results", "Coverage report"]
      }
    }

    security_features = {
      artifact_encryption  = var.enable_artifact_encryption
      resource_scanning   = var.enable_resource_scanning
      least_privilege_iam = "Separate IAM roles with minimal required permissions"
      secure_communications = "HTTPS/TLS for all API communications"
    }
  }
}

# Required Files and Setup
output "required_files" {
  description = "Required files and setup instructions for the pipeline"
  value = {
    repository_structure = {
      required_files = [
        "main.tf (Terraform configuration)",
        "variables.tf (Terraform variables)",
        "outputs.tf (Terraform outputs)",
        "buildspec-validate.yml (Validation build specification)",
        "buildspec-deploy.yml (Deployment build specification)",
        "buildspec-test.yml (Testing build specification)"
      ]
      
      recommended_structure = [
        "terraform/",
        "  ├── main.tf",
        "  ├── variables.tf",
        "  ├── outputs.tf",
        "  └── environments/",
        "      ├── dev.tfvars",
        "      ├── staging.tfvars",
        "      └── prod.tfvars",
        "buildspec-validate.yml",
        "buildspec-deploy.yml",
        "buildspec-test.yml",
        "tests/",
        "  └── integration/",
        "README.md"
      ]
    }

    buildspec_templates = {
      validate = {
        filename = "buildspec-validate.yml"
        purpose  = "Terraform validation and planning"
        phases   = ["install", "pre_build", "build", "post_build"]
      }
      deploy = {
        filename = "buildspec-deploy.yml"
        purpose  = "Terraform deployment to target environment"
        phases   = ["install", "pre_build", "build", "post_build"]
      }
      test = {
        filename = "buildspec-test.yml"
        purpose  = "Integration testing of deployed infrastructure"
        phases   = ["install", "pre_build", "build", "post_build"]
      }
    }

    setup_instructions = [
      "1. Create repository (GitHub or CodeCommit)",
      "2. Add Terraform configuration files",
      "3. Add buildspec files for each stage",
      "4. Configure GitHub token (if using GitHub)",
      "5. Set up notification email",
      "6. Deploy this Terraform configuration",
      "7. Commit and push to trigger first pipeline run"
    ]
  }
}

# Cost and Resource Information
output "cost_and_resources" {
  description = "Cost implications and resource usage of the pipeline"
  value = {
    aws_services_used = {
      codepipeline = {
        service     = "AWS CodePipeline"
        cost_model  = "Per pipeline execution"
        estimated_cost = "$1.00 per pipeline execution"
      }
      codebuild = {
        service     = "AWS CodeBuild"
        cost_model  = "Per build minute"
        estimated_cost = "$0.005 per build minute (BUILD_GENERAL1_SMALL)"
      }
      s3 = {
        service     = "Amazon S3"
        cost_model  = "Storage and requests"
        estimated_cost = "$0.023 per GB/month + request costs"
      }
      cloudwatch = {
        service     = "Amazon CloudWatch"
        cost_model  = "Logs and metrics"
        estimated_cost = "$0.50 per GB ingested"
      }
      sns = {
        service     = "Amazon SNS"
        cost_model  = "Per notification"
        estimated_cost = "$0.50 per million notifications"
      }
    }

    estimated_monthly_costs = {
      light_usage  = "$10-20/month (1-2 deployments/week)"
      moderate_usage = "$30-50/month (daily deployments)"
      heavy_usage  = "$75-100/month (multiple deployments/day)"
    }

    cost_optimization_tips = [
      "Use smaller CodeBuild compute types for simple deployments",
      "Configure S3 lifecycle policies for artifact cleanup",
      "Use specific branch triggers to avoid unnecessary builds",
      "Implement build caching to reduce build times",
      "Monitor CloudWatch logs retention periods"
    ]
  }
}

# Troubleshooting and Monitoring
output "monitoring_and_troubleshooting" {
  description = "Monitoring and troubleshooting information"
  value = {
    monitoring_resources = {
      pipeline_console = "https://${data.aws_region.current.name}.console.aws.amazon.com/codesuite/codepipeline/pipelines/${aws_codepipeline.main.name}/view"
      cloudwatch_dashboard = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.pipeline_monitoring.dashboard_name}"
      build_logs = "Available in CodeBuild project console and CloudWatch Logs"
      sns_notifications = aws_sns_topic.pipeline_notifications.arn
    }

    common_troubleshooting = {
      build_failures = [
        "Check CodeBuild logs in CloudWatch",
        "Verify IAM permissions for CodeBuild role",
        "Validate Terraform syntax and configuration",
        "Check environment variable configuration"
      ]
      approval_delays = [
        "Check SNS subscription confirmation",
        "Verify approver has pipeline permissions",
        "Review approval notification emails"
      ]
      deployment_failures = [
        "Review Terraform plan output",
        "Check target environment state",
        "Verify AWS resource limits and quotas",
        "Validate environment-specific variables"
      ]
    }

    pipeline_states = {
      succeeded = "All stages completed successfully"
      failed    = "One or more stages failed - check build logs"
      stopping  = "Pipeline execution is being stopped"
      stopped   = "Pipeline execution was stopped manually"
      pending   = "Pipeline is waiting for manual approval"
    }
  }
}