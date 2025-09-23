# Module 08: Disaster Recovery → Business Continuity Planning

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Design Disaster Recovery Architectures**: Implement multi-region DR strategies with automated failover and data replication
- **Build Backup and Restore Systems**: Create comprehensive backup strategies for databases, applications, and infrastructure state
- **Implement Business Continuity Planning**: Design systems that maintain operations during various failure scenarios
- **Configure Cross-Region Replication**: Set up automated data synchronization and failover mechanisms across AWS regions
- **Establish Recovery Time and Recovery Point Objectives**: Define and implement RTO/RPO requirements that align with business needs
- **Build Resilience Testing**: Implement chaos engineering and disaster recovery testing to validate system resilience
- **Apply Software Engineering Resilience Patterns**: Connect DR strategies to application-level fault tolerance and recovery mechanisms
- **Design for Multiple Failure Modes**: Create systems that can handle everything from single component failures to entire region outages

## 🎯 Overview

Disaster Recovery (DR) in infrastructure is fundamentally about building systems that can survive and recover from various types of failures, much like how software applications implement error handling, retries, and graceful degradation. This module explores how infrastructure resilience patterns mirror software engineering fault tolerance practices and how proper DR planning enables business continuity.

Just as software engineers design applications with exception handling, circuit breakers, and retry logic, infrastructure engineers must architect systems that can detect failures, recover gracefully, and maintain business operations. Understanding these patterns is crucial for building production-ready systems that can withstand real-world failures and disasters.

## 📖 Core Concepts

### Disaster Recovery Fundamentals

#### Recovery Objectives
- **RTO (Recovery Time Objective)**: Maximum acceptable downtime during a disaster
- **RPO (Recovery Point Objective)**: Maximum acceptable data loss during a disaster
- **MTTR (Mean Time to Recovery)**: Average time to restore service after failure
- **MTBF (Mean Time Between Failures)**: Average time between system failures

#### DR Strategies by Recovery Time

| Strategy | RTO | RPO | Cost | Complexity | Use Cases |
|----------|-----|-----|------|------------|-----------|
| Backup & Restore | Hours to Days | Hours | Low | Low | Development, non-critical |
| Pilot Light | 10s of Minutes | Minutes | Medium | Medium | Small critical workloads |
| Warm Standby | Minutes | Minutes | Medium-High | Medium | Business-critical applications |
| Multi-Site Active/Active | Seconds | Seconds | High | High | Mission-critical systems |

### Software Engineering Parallels

| Infrastructure Pattern | Software Engineering Pattern | Purpose |
|------------------------|------------------------------|---------|
| Multi-Region Deployment | Service Redundancy | Eliminate single points of failure |
| Automated Failover | Circuit Breaker Pattern | Detect failures and reroute traffic |
| Data Replication | Database Transactions/ACID | Ensure data consistency across systems |
| Health Checks | Application Health Endpoints | Monitor system health and trigger recovery |
| Backup Automation | Version Control/Snapshots | Preserve system state for recovery |
| Runbook Automation | Exception Handling | Automated response to known failure modes |

### Failure Classifications

#### Infrastructure Failures
- **Hardware Failures**: Server, storage, network equipment failures
- **Software Failures**: Operating system, application, database failures  
- **Network Failures**: Connectivity, DNS, load balancer failures
- **Power Failures**: Data center power, cooling system failures

#### Regional/Geographic Failures
- **Natural Disasters**: Earthquakes, hurricanes, floods, wildfires
- **Human-Caused Disasters**: Cyber attacks, terrorism, accidents
- **Provider Outages**: AWS region/service outages, ISP failures
- **Regulatory Issues**: Data sovereignty, compliance requirements

#### Application-Level Failures
- **Data Corruption**: Database corruption, file system errors
- **Configuration Errors**: Misconfigurations causing service failures
- **Security Incidents**: Data breaches, malware, insider threats
- **Performance Degradation**: Resource exhaustion, memory leaks

### Business Impact Classification

#### Tier 1 (Mission Critical)
- **RTO**: < 1 hour
- **RPO**: < 15 minutes
- **Examples**: Payment processing, emergency services, trading systems

#### Tier 2 (Business Critical)  
- **RTO**: < 4 hours
- **RPO**: < 1 hour
- **Examples**: Customer-facing applications, core business systems

#### Tier 3 (Important)
- **RTO**: < 24 hours
- **RPO**: < 4 hours
- **Examples**: Internal applications, reporting systems

#### Tier 4 (Non-Critical)
- **RTO**: < 72 hours
- **RPO**: < 24 hours
- **Examples**: Development environments, archive systems

## 🛠️ Terraform Implementation

### 1. Multi-Region Disaster Recovery Architecture

This implementation creates a comprehensive DR solution with primary and secondary regions:

```hcl
# examples/01-multi-region-dr/main.tf

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Primary region provider
provider "aws" {
  alias  = "primary"
  region = var.primary_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Multi-Region-DR"
      Region      = "primary"
    }
  }
}

# Secondary region provider for DR
provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Multi-Region-DR"
      Region      = "secondary"
    }
  }
}

# Data sources for availability zones
data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

# Route 53 Health Check for primary region
resource "aws_route53_health_check" "primary_endpoint" {
  fqdn                            = var.primary_endpoint_fqdn
  port                           = 443
  type                           = "HTTPS"
  resource_path                  = "/health"
  failure_threshold              = "3"
  request_interval               = "30"
  cloudwatch_alarm_region        = var.primary_region
  cloudwatch_alarm_name          = aws_cloudwatch_metric_alarm.primary_health.alarm_name

  tags = {
    Name = "${var.project_name}-${var.environment}-primary-health-check"
  }
}

# CloudWatch Alarm for primary region health
resource "aws_cloudwatch_metric_alarm" "primary_health" {
  provider = aws.primary
  
  alarm_name          = "${var.project_name}-${var.environment}-primary-health-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HealthCheckPercentHealthy"
  namespace           = "AWS/Route53"
  period              = "60"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Primary region health check alarm"
  
  alarm_actions = [aws_sns_topic.dr_alerts_primary.arn]
  ok_actions    = [aws_sns_topic.dr_alerts_primary.arn]

  dimensions = {
    HealthCheckId = aws_route53_health_check.primary_endpoint.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-primary-health-alarm"
  }
}

# SNS Topics for DR alerts
resource "aws_sns_topic" "dr_alerts_primary" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-dr-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-dr-alerts-primary"
  }
}

resource "aws_sns_topic" "dr_alerts_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-${var.environment}-dr-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-dr-alerts-secondary"
  }
}

# Primary Region Infrastructure
module "primary_infrastructure" {
  source = "./modules/region-infrastructure"
  
  providers = {
    aws = aws.primary
  }
  
  project_name     = var.project_name
  environment      = var.environment
  region           = var.primary_region
  vpc_cidr         = var.primary_vpc_cidr
  is_primary       = true
  
  # Database configuration
  database_instance_class     = var.primary_database_instance_class
  database_backup_retention   = var.database_backup_retention
  database_snapshot_id       = null
  
  # Auto Scaling configuration
  min_capacity = var.primary_min_capacity
  max_capacity = var.primary_max_capacity
  
  # Cross-region replication
  replication_region = var.secondary_region
  
  # SNS topic for alerts
  alert_topic_arn = aws_sns_topic.dr_alerts_primary.arn
}

# Secondary Region Infrastructure (DR)
module "secondary_infrastructure" {
  source = "./modules/region-infrastructure"
  
  providers = {
    aws = aws.secondary
  }
  
  project_name     = var.project_name
  environment      = var.environment
  region           = var.secondary_region
  vpc_cidr         = var.secondary_vpc_cidr
  is_primary       = false
  
  # Database configuration (smaller instance for cost optimization)
  database_instance_class     = var.secondary_database_instance_class
  database_backup_retention   = var.database_backup_retention
  database_snapshot_id       = null  # Will be restored from backup during DR
  
  # Auto Scaling configuration (minimal resources)
  min_capacity = var.secondary_min_capacity
  max_capacity = var.secondary_max_capacity
  
  # Cross-region replication
  replication_region = var.primary_region
  
  # SNS topic for alerts
  alert_topic_arn = aws_sns_topic.dr_alerts_secondary.arn
  
  # Dependency on primary region
  depends_on = [module.primary_infrastructure]
}

# Route 53 Hosted Zone for DNS failover
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Name = "${var.project_name}-${var.environment}-hosted-zone"
  }
}

# Primary region DNS record (primary)
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  
  set_identifier = "primary"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  
  health_check_id = aws_route53_health_check.primary_endpoint.id
  
  alias {
    name                   = module.primary_infrastructure.load_balancer_dns_name
    zone_id               = module.primary_infrastructure.load_balancer_zone_id
    evaluate_target_health = true
  }
}

# Secondary region DNS record (failover)
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  
  set_identifier = "secondary"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  
  alias {
    name                   = module.secondary_infrastructure.load_balancer_dns_name
    zone_id               = module.secondary_infrastructure.load_balancer_zone_id
    evaluate_target_health = true
  }
}

# Cross-region VPC Peering for data replication (if needed)
resource "aws_vpc_peering_connection" "primary_to_secondary" {
  provider = aws.primary
  
  peer_vpc_id   = module.secondary_infrastructure.vpc_id
  vpc_id        = module.primary_infrastructure.vpc_id
  peer_region   = var.secondary_region
  auto_accept   = false

  tags = {
    Name = "${var.project_name}-${var.environment}-primary-to-secondary-peering"
  }
}

resource "aws_vpc_peering_connection_accepter" "secondary" {
  provider = aws.secondary
  
  vpc_peering_connection_id = aws_vpc_peering_connection.primary_to_secondary.id
  auto_accept              = true

  tags = {
    Name = "${var.project_name}-${var.environment}-secondary-peering-accepter"
  }
}

# Lambda function for automated failover
resource "aws_lambda_function" "dr_orchestrator" {
  provider = aws.primary
  
  filename         = "dr_orchestrator.zip"
  function_name    = "${var.project_name}-${var.environment}-dr-orchestrator"
  role            = aws_iam_role.dr_orchestrator.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.dr_orchestrator.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME      = var.project_name
      ENVIRONMENT       = var.environment
      PRIMARY_REGION    = var.primary_region
      SECONDARY_REGION  = var.secondary_region
      ROUTE53_ZONE_ID   = aws_route53_zone.main.zone_id
      SNS_TOPIC_ARN     = aws_sns_topic.dr_alerts_primary.arn
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-dr-orchestrator"
  }
}

data "archive_file" "dr_orchestrator" {
  type        = "zip"
  output_path = "dr_orchestrator.zip"
  
  source {
    content = templatefile("${path.module}/lambda/dr_orchestrator.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for DR orchestrator
resource "aws_iam_role" "dr_orchestrator" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-dr-orchestrator"

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

resource "aws_iam_role_policy" "dr_orchestrator" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-dr-orchestrator-policy"
  role     = aws_iam_role.dr_orchestrator.id

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
          "route53:ChangeResourceRecordSets",
          "route53:GetChange",
          "route53:ListResourceRecordSets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:RestoreDBClusterFromSnapshot",
          "rds:CreateDBClusterSnapshot",
          "rds:DescribeDBClusters",
          "rds:DescribeDBClusterSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.dr_alerts_primary.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = "arn:aws:iam::*:role/${var.project_name}-${var.environment}-dr-*"
      }
    ]
  })
}

# CloudWatch Event Rule for automated DR triggers
resource "aws_cloudwatch_event_rule" "dr_trigger" {
  provider = aws.primary
  
  name        = "${var.project_name}-${var.environment}-dr-trigger"
  description = "Trigger DR orchestration based on health check failures"

  event_pattern = jsonencode({
    source      = ["aws.route53"]
    detail-type = ["Route 53 Health Check Alarm"]
    detail = {
      state = {
        value = ["ALARM"]
      }
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-dr-trigger"
  }
}

resource "aws_cloudwatch_event_target" "dr_orchestrator" {
  provider = aws.primary
  
  rule      = aws_cloudwatch_event_rule.dr_trigger.name
  target_id = "DROrchestrator"
  arn       = aws_lambda_function.dr_orchestrator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_dr" {
  provider = aws.primary
  
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr_orchestrator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.dr_trigger.arn
}

# DynamoDB Global Table for session data replication
resource "aws_dynamodb_table" "sessions_primary" {
  provider = aws.primary
  
  name           = "${var.project_name}-${var.environment}-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "session_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sessions-primary"
  }
}

resource "aws_dynamodb_table" "sessions_secondary" {
  provider = aws.secondary
  
  name           = "${var.project_name}-${var.environment}-sessions"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "session_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sessions-secondary"
  }
}

# DynamoDB Global Table configuration
resource "aws_dynamodb_global_table" "sessions" {
  provider = aws.primary
  name     = aws_dynamodb_table.sessions_primary.name

  replica {
    region_name = var.primary_region
  }

  replica {
    region_name = var.secondary_region
  }

  depends_on = [
    aws_dynamodb_table.sessions_primary,
    aws_dynamodb_table.sessions_secondary
  ]
}
```

```python
# examples/01-multi-region-dr/lambda/dr_orchestrator.py

import json
import boto3
import os
import time
import logging
from datetime import datetime, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
PROJECT_NAME = os.environ.get('PROJECT_NAME')
ENVIRONMENT = os.environ.get('ENVIRONMENT')
PRIMARY_REGION = os.environ.get('PRIMARY_REGION')
SECONDARY_REGION = os.environ.get('SECONDARY_REGION')
ROUTE53_ZONE_ID = os.environ.get('ROUTE53_ZONE_ID')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')

def handler(event, context):
    """
    DR Orchestrator Lambda function
    Handles automated disaster recovery procedures
    """
    try:
        logger.info(f"DR orchestration triggered: {json.dumps(event)}")
        
        # Parse the event to determine the failure type
        failure_type = determine_failure_type(event)
        logger.info(f"Failure type determined: {failure_type}")
        
        # Execute DR procedure based on failure type
        if failure_type == 'primary_region_failure':
            result = execute_primary_region_failover()
        elif failure_type == 'database_failure':
            result = execute_database_recovery()
        elif failure_type == 'application_failure':
            result = execute_application_recovery()
        else:
            result = execute_health_check_recovery()
        
        # Send notification
        send_notification(f"DR procedure completed: {failure_type}", result)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'DR orchestration completed successfully',
                'failure_type': failure_type,
                'result': result
            })
        }
    
    except Exception as e:
        logger.error(f"Error in DR orchestration: {str(e)}")
        send_notification("DR orchestration failed", {'error': str(e)})
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': 'DR orchestration failed',
                'error': str(e)
            })
        }

def determine_failure_type(event):
    """Analyze the event to determine the type of failure"""
    if 'source' in event and event['source'] == 'aws.route53':
        return 'primary_region_failure'
    elif 'alarm_name' in event and 'database' in event.get('alarm_name', '').lower():
        return 'database_failure'
    elif 'alarm_name' in event and 'application' in event.get('alarm_name', '').lower():
        return 'application_failure'
    else:
        return 'health_check_failure'

def execute_primary_region_failover():
    """Execute complete failover to secondary region"""
    logger.info("Executing primary region failover")
    
    results = {}
    
    try:
        # 1. Scale up secondary region infrastructure
        results['scale_up'] = scale_up_secondary_region()
        
        # 2. Restore database from latest backup
        results['database_restore'] = restore_database_in_secondary()
        
        # 3. Update Route 53 to point to secondary region
        results['dns_update'] = update_dns_failover()
        
        # 4. Verify secondary region health
        results['health_check'] = verify_secondary_region_health()
        
        logger.info("Primary region failover completed successfully")
        return results
    
    except Exception as e:
        logger.error(f"Primary region failover failed: {str(e)}")
        raise

def scale_up_secondary_region():
    """Scale up Auto Scaling Groups in secondary region"""
    autoscaling_secondary = boto3.client('autoscaling', region_name=SECONDARY_REGION)
    
    asg_name = f"{PROJECT_NAME}-{ENVIRONMENT}-web-asg"
    
    response = autoscaling_secondary.update_auto_scaling_group(
        AutoScalingGroupName=asg_name,
        MinSize=2,
        DesiredCapacity=3,
        MaxSize=10
    )
    
    logger.info(f"Scaled up ASG {asg_name} in secondary region")
    return {'asg_name': asg_name, 'status': 'scaled_up'}

def restore_database_in_secondary():
    """Restore database from latest backup in secondary region"""
    rds_primary = boto3.client('rds', region_name=PRIMARY_REGION)
    rds_secondary = boto3.client('rds', region_name=SECONDARY_REGION)
    
    cluster_id = f"{PROJECT_NAME}-{ENVIRONMENT}-cluster"
    
    # Get latest snapshot from primary region
    snapshots = rds_primary.describe_db_cluster_snapshots(
        DBClusterIdentifier=cluster_id,
        SnapshotType='manual',
        MaxRecords=1
    )
    
    if not snapshots['DBClusterSnapshots']:
        # Create snapshot if none exists
        snapshot_id = f"{cluster_id}-dr-snapshot-{int(time.time())}"
        rds_primary.create_db_cluster_snapshot(
            DBClusterSnapshotIdentifier=snapshot_id,
            DBClusterIdentifier=cluster_id
        )
        
        # Wait for snapshot to complete
        waiter = rds_primary.get_waiter('db_cluster_snapshot_completed')
        waiter.wait(DBClusterSnapshotIdentifier=snapshot_id)
    else:
        snapshot_id = snapshots['DBClusterSnapshots'][0]['DBClusterSnapshotIdentifier']
    
    # Check if cluster already exists in secondary region
    try:
        rds_secondary.describe_db_clusters(
            DBClusterIdentifier=f"{cluster_id}-dr"
        )
        logger.info("DR database cluster already exists")
        return {'status': 'already_exists', 'cluster_id': f"{cluster_id}-dr"}
    except rds_secondary.exceptions.DBClusterNotFoundFault:
        pass
    
    # Restore cluster in secondary region
    rds_secondary.restore_db_cluster_from_snapshot(
        DBClusterIdentifier=f"{cluster_id}-dr",
        SnapshotIdentifier=snapshot_id,
        Engine='aurora-mysql'
    )
    
    logger.info(f"Database restore initiated in secondary region")
    return {'status': 'restoring', 'snapshot_id': snapshot_id, 'cluster_id': f"{cluster_id}-dr"}

def update_dns_failover():
    """Update Route 53 to failover to secondary region"""
    route53 = boto3.client('route53')
    
    # This is a simplified example - in practice, you might update health check thresholds
    # or modify DNS records based on your specific configuration
    
    # For demonstration, we'll create a log entry
    logger.info("DNS failover would be triggered by Route 53 health checks automatically")
    return {'status': 'automatic_failover_configured'}

def verify_secondary_region_health():
    """Verify that secondary region is healthy and ready"""
    elbv2_secondary = boto3.client('elbv2', region_name=SECONDARY_REGION)
    
    # Check load balancer health
    load_balancers = elbv2_secondary.describe_load_balancers()
    
    for lb in load_balancers['LoadBalancers']:
        if PROJECT_NAME in lb['LoadBalancerName'] and ENVIRONMENT in lb['LoadBalancerName']:
            if lb['State']['Code'] != 'active':
                raise Exception(f"Load balancer {lb['LoadBalancerName']} is not active")
    
    logger.info("Secondary region health verification completed")
    return {'status': 'healthy', 'region': SECONDARY_REGION}

def execute_database_recovery():
    """Execute database-specific recovery procedures"""
    logger.info("Executing database recovery")
    
    # Implement database-specific recovery logic
    # This could include:
    # - Promoting read replica
    # - Restoring from point-in-time backup
    # - Switching to standby database
    
    return {'status': 'database_recovery_completed'}

def execute_application_recovery():
    """Execute application-specific recovery procedures"""
    logger.info("Executing application recovery")
    
    # Implement application-specific recovery logic
    # This could include:
    # - Restarting services
    # - Clearing caches
    # - Rolling back deployments
    
    return {'status': 'application_recovery_completed'}

def execute_health_check_recovery():
    """Execute general health check recovery procedures"""
    logger.info("Executing health check recovery")
    
    # Implement general recovery logic
    return {'status': 'health_check_recovery_completed'}

def send_notification(subject, details):
    """Send notification via SNS"""
    sns = boto3.client('sns', region_name=PRIMARY_REGION)
    
    message = {
        'timestamp': datetime.utcnow().isoformat(),
        'project': PROJECT_NAME,
        'environment': ENVIRONMENT,
        'subject': subject,
        'details': details
    }
    
    try:
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject=f"[{PROJECT_NAME}] {subject}",
            Message=json.dumps(message, indent=2)
        )
        logger.info("Notification sent successfully")
    except Exception as e:
        logger.error(f"Failed to send notification: {str(e)}")
```

```hcl
# examples/01-multi-region-dr/modules/region-infrastructure/main.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Local values for region-specific configuration
locals {
  availability_zones = data.aws_availability_zones.current.names
  
  # Adjust capacity based on whether this is primary or secondary region
  actual_min_capacity = var.is_primary ? var.min_capacity : 0
  actual_max_capacity = var.is_primary ? var.max_capacity : var.max_capacity
}

data "aws_availability_zones" "current" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-${var.region}"
    Role = var.is_primary ? "primary" : "secondary"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw-${var.region}"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count = min(length(local.availability_zones), 3)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}-${var.region}"
    Type = "public"
  }
}

# Private Subnets for Database
resource "aws_subnet" "private" {
  count = min(length(local.availability_zones), 3)
  
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 101)
  availability_zone = local.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}-${var.region}"
    Type = "private"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt-${var.region}"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-${var.region}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg-${var.region}"
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.project_name}-${var.environment}-db-${var.region}-"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-db-sg-${var.region}"
  }
}

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group-${var.region}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group-${var.region}"
  }
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.project_name}-${var.environment}-cluster-${var.region}"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.02.0"
  database_name          = "appdb"
  master_username        = "admin"
  master_password        = random_password.db_master.result
  
  backup_retention_period = var.database_backup_retention
  preferred_backup_window = var.is_primary ? "03:00-04:00" : "07:00-08:00"
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  storage_encrypted = true
  
  # Cross-region backup replication
  dynamic "s3_import" {
    for_each = var.database_snapshot_id != null ? [1] : []
    content {
      source_engine         = "mysql"
      source_engine_version = "8.0"
      bucket_name          = "${var.project_name}-${var.environment}-db-backups"
      bucket_prefix        = "mysql-backup"
      ingestion_role       = aws_iam_role.s3_import_role[0].arn
    }
  }
  
  # Enable automatic backups and point-in-time recovery
  copy_tags_to_snapshot = true
  deletion_protection   = var.is_primary
  skip_final_snapshot  = !var.is_primary
  
  tags = {
    Name = "${var.project_name}-${var.environment}-cluster-${var.region}"
    Role = var.is_primary ? "primary" : "secondary"
  }

  lifecycle {
    ignore_changes = [master_password]
  }
}

resource "random_password" "db_master" {
  length  = 16
  special = true
}

# Aurora Cluster Instance
resource "aws_rds_cluster_instance" "cluster_instances" {
  count = var.is_primary ? 2 : 1  # Primary has 2 instances, secondary has 1
  
  identifier           = "${var.project_name}-${var.environment}-${count.index}-${var.region}"
  cluster_identifier   = aws_rds_cluster.main.id
  instance_class       = var.database_instance_class
  engine              = aws_rds_cluster.main.engine
  engine_version      = aws_rds_cluster.main.engine_version
  
  performance_insights_enabled = var.is_primary
  monitoring_interval         = var.is_primary ? 60 : 0
  
  tags = {
    Name = "${var.project_name}-${var.environment}-db-${count.index}-${var.region}"
  }
}

# S3 Import Role (conditional)
resource "aws_iam_role" "s3_import_role" {
  count = var.database_snapshot_id != null ? 1 : 0
  name  = "${var.project_name}-${var.environment}-s3-import-${var.region}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb-${var.region}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.is_primary

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-${var.region}"
    Role = var.is_primary ? "primary" : "secondary"
  }
}

# Target Group
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-tg-${var.region}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg-${var.region}"
  }
}

# Load Balancer Listener
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# Launch Template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-${var.region}-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    environment  = var.environment
    region       = var.region
    is_primary   = var.is_primary
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-web-instance-${var.region}"
      Role = var.is_primary ? "primary" : "secondary"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name               = "${var.project_name}-${var.environment}-web-asg-${var.region}"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns  = [aws_lb_target_group.web.arn]
  health_check_type  = "ELB"

  min_size         = local.actual_min_capacity
  max_size         = local.actual_max_capacity
  desired_capacity = local.actual_min_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web-asg-${var.region}"
    propagate_at_launch = false
  }

  tag {
    key                 = "Role"
    value               = var.is_primary ? "primary" : "secondary"
    propagate_at_launch = true
  }
}
```

### 2. Automated Backup and Restore System

```hcl
# examples/02-backup-restore/main.tf

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
      Module      = "Backup-Restore"
    }
  }
}

# AWS Backup Vault with encryption
resource "aws_backup_vault" "main" {
  name        = "${var.project_name}-${var.environment}-backup-vault"
  kms_key_arn = aws_kms_key.backup.arn

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-vault"
  }
}

# KMS key for backup encryption
resource "aws_kms_key" "backup" {
  description             = "KMS key for AWS Backup"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-kms"
  }
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${var.project_name}-${var.environment}-backup"
  target_key_id = aws_kms_key.backup.key_id
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup" {
  name = "${var.project_name}-${var.environment}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_service_role" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_service_role_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Backup Plan for Critical Resources
resource "aws_backup_plan" "critical_resources" {
  name = "${var.project_name}-${var.environment}-critical-backup-plan"

  # Hourly backups for critical databases (RPO: 1 hour)
  rule {
    rule_name         = "hourly_database_backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 * * * ? *)"  # Every hour
    start_window      = 60                   # 1 hour window
    completion_window = 180                  # 3 hours to complete

    recovery_point_tags = {
      BackupType = "hourly"
      Frequency  = "critical"
    }

    lifecycle {
      cold_storage_after = 30    # Move to cold storage after 30 days
      delete_after      = 365    # Delete after 1 year
    }
  }

  # Daily backups for application data (RPO: 24 hours)
  rule {
    rule_name         = "daily_application_backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 2 * * ? *)"  # Daily at 2 AM
    start_window      = 120                  # 2 hour window
    completion_window = 300                  # 5 hours to complete

    recovery_point_tags = {
      BackupType = "daily"
      Frequency  = "standard"
    }

    lifecycle {
      cold_storage_after = 60    # Move to cold storage after 60 days
      delete_after      = 730    # Delete after 2 years
    }
  }

  # Weekly backups for long-term retention (RPO: 1 week)
  rule {
    rule_name         = "weekly_longterm_backups"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 3 ? * SUN *)"  # Weekly on Sunday at 3 AM
    start_window      = 180                    # 3 hour window
    completion_window = 480                    # 8 hours to complete

    recovery_point_tags = {
      BackupType = "weekly"
      Frequency  = "longterm"
    }

    lifecycle {
      cold_storage_after = 90     # Move to cold storage after 90 days
      delete_after      = 2555    # Delete after 7 years
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-critical-backup-plan"
  }
}

# Backup selection for RDS databases
resource "aws_backup_selection" "database_backup" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-${var.environment}-database-backup-selection"
  plan_id      = aws_backup_plan.critical_resources.id

  resources = [
    "arn:aws:rds:*:*:cluster/*${var.project_name}*",
    "arn:aws:rds:*:*:db/*${var.project_name}*"
  ]

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Project"
    value = var.project_name
  }

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = var.environment
  }
}

# Backup selection for EFS file systems
resource "aws_backup_selection" "efs_backup" {
  count = length(var.efs_file_systems) > 0 ? 1 : 0
  
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-${var.environment}-efs-backup-selection"
  plan_id      = aws_backup_plan.critical_resources.id

  resources = var.efs_file_systems

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Project"
    value = var.project_name
  }
}

# Cross-region backup replication
resource "aws_backup_vault" "replica" {
  count = var.backup_replica_region != "" ? 1 : 0
  
  provider = aws.replica
  name     = "${var.project_name}-${var.environment}-backup-vault-replica"

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-vault-replica"
  }
}

# Backup replica provider
provider "aws" {
  alias  = "replica"
  region = var.backup_replica_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "Backup-Restore"
      Region      = "replica"
    }
  }
}

# Lambda function for custom backup validation
resource "aws_lambda_function" "backup_validator" {
  filename         = "backup_validator.zip"
  function_name    = "${var.project_name}-${var.environment}-backup-validator"
  role            = aws_iam_role.backup_validator.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.backup_validator.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME  = var.project_name
      ENVIRONMENT   = var.environment
      BACKUP_VAULT  = aws_backup_vault.main.name
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-validator"
  }
}

data "archive_file" "backup_validator" {
  type        = "zip"
  output_path = "backup_validator.zip"
  
  source {
    content = templatefile("${path.module}/lambda/backup_validator.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for backup validator
resource "aws_iam_role" "backup_validator" {
  name = "${var.project_name}-${var.environment}-backup-validator"

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

resource "aws_iam_role_policy" "backup_validator" {
  name = "${var.project_name}-${var.environment}-backup-validator-policy"
  role = aws_iam_role.backup_validator.id

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
          "backup:ListRecoveryPoints",
          "backup:DescribeRecoveryPoint",
          "backup:ListRestoreJobs",
          "backup:DescribeRestoreJob"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusterSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.backup_alerts.arn
      }
    ]
  })
}

# SNS topic for backup alerts
resource "aws_sns_topic" "backup_alerts" {
  name = "${var.project_name}-${var.environment}-backup-alerts"

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-alerts"
  }
}

# EventBridge rule for backup job completion
resource "aws_cloudwatch_event_rule" "backup_completion" {
  name        = "${var.project_name}-${var.environment}-backup-completion"
  description = "Trigger validation when backup job completes"

  event_pattern = jsonencode({
    source      = ["aws.backup"]
    detail-type = ["Backup Job State Change"]
    detail = {
      state = ["COMPLETED", "FAILED"]
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-backup-completion"
  }
}

resource "aws_cloudwatch_event_target" "backup_validator" {
  rule      = aws_cloudwatch_event_rule.backup_completion.name
  target_id = "BackupValidator"
  arn       = aws_lambda_function.backup_validator.arn
}

resource "aws_lambda_permission" "allow_eventbridge_backup" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backup_validator.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.backup_completion.arn
}

# CloudWatch Dashboard for backup monitoring
resource "aws_cloudwatch_dashboard" "backup_monitoring" {
  dashboard_name = "${var.project_name}-${var.environment}-backup-monitoring"

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
            ["AWS/Backup", "NumberOfBackupJobsCreated"],
            [".", "NumberOfBackupJobsCompleted"],
            [".", "NumberOfBackupJobsFailed"]
          ]
          period = 3600
          stat   = "Sum"
          region = var.aws_region
          title  = "Backup Job Statistics"
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
            ["AWS/Backup", "NumberOfRestoreJobsCreated"],
            [".", "NumberOfRestoreJobsCompleted"],
            [".", "NumberOfRestoreJobsFailed"]
          ]
          period = 3600
          stat   = "Sum"
          region = var.aws_region
          title  = "Restore Job Statistics"
        }
      }
    ]
  })
}

# Automated restore testing (for compliance and validation)
resource "aws_lambda_function" "restore_tester" {
  filename         = "restore_tester.zip"
  function_name    = "${var.project_name}-${var.environment}-restore-tester"
  role            = aws_iam_role.restore_tester.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 900  # 15 minutes

  source_code_hash = data.archive_file.restore_tester.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      TEST_VPC_ID  = var.test_vpc_id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-restore-tester"
  }
}

data "archive_file" "restore_tester" {
  type        = "zip"
  output_path = "restore_tester.zip"
  
  source {
    content = file("${path.module}/lambda/restore_tester.py")
    filename = "index.py"
  }
}

# IAM role for restore tester
resource "aws_iam_role" "restore_tester" {
  name = "${var.project_name}-${var.environment}-restore-tester"

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

resource "aws_iam_role_policy" "restore_tester" {
  name = "${var.project_name}-${var.environment}-restore-tester-policy"
  role = aws_iam_role.restore_tester.id

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
          "backup:StartRestoreJob",
          "backup:DescribeRestoreJob",
          "backup:ListRecoveryPoints"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:RestoreDBClusterFromSnapshot",
          "rds:DeleteDBCluster",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# Schedule restore testing monthly
resource "aws_cloudwatch_event_rule" "monthly_restore_test" {
  name                = "${var.project_name}-${var.environment}-monthly-restore-test"
  description         = "Trigger restore testing monthly"
  schedule_expression = "cron(0 2 1 * ? *)"  # First day of month at 2 AM

  tags = {
    Name = "${var.project_name}-${var.environment}-monthly-restore-test"
  }
}

resource "aws_cloudwatch_event_target" "restore_tester" {
  rule      = aws_cloudwatch_event_rule.monthly_restore_test.name
  target_id = "RestoreTester"
  arn       = aws_lambda_function.restore_tester.arn
}

resource "aws_lambda_permission" "allow_eventbridge_restore_test" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restore_tester.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.monthly_restore_test.arn
}
```

## 🔗 Software Engineering Connections

### Resilience Patterns

#### 1. Circuit Breaker Pattern
Infrastructure DR mirrors application circuit breaker patterns:

```python
# Application-level circuit breaker
import time
import random
from enum import Enum

class CircuitState(Enum):
    CLOSED = "closed"
    OPEN = "open"
    HALF_OPEN = "half_open"

class InfrastructureCircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=300, half_open_limit=3):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.half_open_limit = half_open_limit
        
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        self.half_open_attempts = 0
    
    def call_primary_region(self, operation):
        """Call primary region with circuit breaker protection"""
        if self.state == CircuitState.OPEN:
            if self._should_attempt_reset():
                self.state = CircuitState.HALF_OPEN
                self.half_open_attempts = 0
            else:
                # Route to secondary region
                return self._call_secondary_region(operation)
        
        if self.state == CircuitState.HALF_OPEN:
            if self.half_open_attempts >= self.half_open_limit:
                # Too many attempts in half-open state
                return self._call_secondary_region(operation)
        
        try:
            result = operation()
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            if self.state == CircuitState.OPEN:
                return self._call_secondary_region(operation)
            raise e
    
    def _should_attempt_reset(self):
        return (time.time() - self.last_failure_time) > self.recovery_timeout
    
    def _on_success(self):
        if self.state == CircuitState.HALF_OPEN:
            self.state = CircuitState.CLOSED
        self.failure_count = 0
        self.half_open_attempts = 0
    
    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.state == CircuitState.HALF_OPEN:
            self.half_open_attempts += 1
            self.state = CircuitState.OPEN
        elif self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN
    
    def _call_secondary_region(self, operation):
        """Fallback to secondary region"""
        # Implement secondary region call logic
        return secondary_region_client.call(operation)

# Usage in application
circuit_breaker = InfrastructureCircuitBreaker()

def make_database_call():
    return circuit_breaker.call_primary_region(lambda: primary_db.query("SELECT * FROM users"))
```

#### 2. Retry with Exponential Backoff
```python
import time
import random
import logging

class RetryWithBackoff:
    def __init__(self, max_retries=3, base_delay=1, max_delay=60, backoff_factor=2):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.backoff_factor = backoff_factor
        self.logger = logging.getLogger(__name__)
    
    def execute_with_retry(self, operation, operation_name="operation"):
        """Execute operation with exponential backoff retry"""
        last_exception = None
        
        for attempt in range(self.max_retries + 1):
            try:
                return operation()
            except Exception as e:
                last_exception = e
                
                if attempt == self.max_retries:
                    self.logger.error(f"{operation_name} failed after {self.max_retries} retries: {str(e)}")
                    break
                
                # Calculate delay with jitter
                delay = min(
                    self.base_delay * (self.backoff_factor ** attempt),
                    self.max_delay
                )
                jitter = random.uniform(0, delay * 0.1)
                total_delay = delay + jitter
                
                self.logger.warning(f"{operation_name} failed (attempt {attempt + 1}), retrying in {total_delay:.2f}s: {str(e)}")
                time.sleep(total_delay)
        
        raise last_exception

# Usage for infrastructure operations
retry_handler = RetryWithBackoff(max_retries=5, base_delay=2)

def restore_database_with_retry():
    def restore_operation():
        # AWS Backup restore operation
        backup_client = boto3.client('backup')
        return backup_client.start_restore_job(
            RecoveryPointArn=recovery_point_arn,
            Metadata=restore_metadata,
            IamRoleArn=restore_role_arn
        )
    
    return retry_handler.execute_with_retry(restore_operation, "database_restore")
```

#### 3. Bulkhead Pattern for Resource Isolation
```python
# Resource pool isolation for different failure scenarios
class ResourcePool:
    def __init__(self, name, max_connections, health_check_interval=60):
        self.name = name
        self.max_connections = max_connections
        self.current_connections = 0
        self.health_check_interval = health_check_interval
        self.last_health_check = 0
        self.is_healthy = True
    
    def acquire_connection(self):
        if not self.is_healthy:
            raise Exception(f"Resource pool {self.name} is unhealthy")
        
        if self.current_connections >= self.max_connections:
            raise Exception(f"Resource pool {self.name} is at capacity")
        
        self.current_connections += 1
        return Connection(self)
    
    def release_connection(self):
        self.current_connections = max(0, self.current_connections - 1)
    
    def health_check(self):
        # Implement health check logic
        current_time = time.time()
        if current_time - self.last_health_check > self.health_check_interval:
            self.is_healthy = self._perform_health_check()
            self.last_health_check = current_time
        return self.is_healthy

class DisasterRecoveryResourceManager:
    def __init__(self):
        # Separate resource pools for different operations
        self.pools = {
            'primary_database': ResourcePool('primary_database', max_connections=50),
            'secondary_database': ResourcePool('secondary_database', max_connections=30),
            'backup_operations': ResourcePool('backup_operations', max_connections=10),
            'monitoring': ResourcePool('monitoring', max_connections=20)
        }
    
    def get_connection(self, pool_name):
        if pool_name not in self.pools:
            raise ValueError(f"Unknown resource pool: {pool_name}")
        
        pool = self.pools[pool_name]
        
        # Check health before allocation
        if not pool.health_check():
            # Try fallback pool if available
            if pool_name == 'primary_database':
                return self.get_connection('secondary_database')
            raise Exception(f"Resource pool {pool_name} is unhealthy")
        
        return pool.acquire_connection()

# Usage
resource_manager = DisasterRecoveryResourceManager()

# Isolated resources for backup operations
with resource_manager.get_connection('backup_operations') as conn:
    # Backup operations won't impact application connections
    perform_backup(conn)
```

### Data Consistency Patterns

#### 1. Eventual Consistency with Conflict Resolution
```python
import hashlib
import json
from datetime import datetime

class EventualConsistencyManager:
    def __init__(self):
        self.conflict_resolver = ConflictResolver()
    
    def replicate_data(self, data, source_region, target_regions):
        """Replicate data across regions with conflict detection"""
        timestamp = datetime.utcnow().isoformat()
        checksum = self._calculate_checksum(data)
        
        replication_record = {
            'data': data,
            'timestamp': timestamp,
            'checksum': checksum,
            'source_region': source_region,
            'version': self._get_next_version()
        }
        
        results = {}
        for region in target_regions:
            try:
                result = self._replicate_to_region(replication_record, region)
                results[region] = result
            except ConflictException as e:
                # Handle conflicts using resolution strategy
                resolved_data = self.conflict_resolver.resolve(e.conflicting_records)
                results[region] = self._replicate_to_region(resolved_data, region)
        
        return results
    
    def _calculate_checksum(self, data):
        return hashlib.sha256(json.dumps(data, sort_keys=True).encode()).hexdigest()

class ConflictResolver:
    def resolve(self, conflicting_records):
        """Resolve conflicts using last-writer-wins with version vectors"""
        # Sort by timestamp and version
        sorted_records = sorted(
            conflicting_records,
            key=lambda x: (x['timestamp'], x['version']),
            reverse=True
        )
        
        # Last writer wins
        return sorted_records[0]
```

## 🎯 Hands-on Examples

### Exercise 1: Multi-Region DR Setup

**Objective:** Deploy a complete multi-region disaster recovery solution with automated failover

**Steps:**

1. **Deploy Multi-Region Infrastructure**
   ```bash
   cd examples/01-multi-region-dr
   
   # Initialize and plan
   terraform init
   terraform plan -var="primary_region=us-west-2" -var="secondary_region=us-east-1"
   
   # Apply infrastructure
   terraform apply -var="primary_region=us-west-2" -var="secondary_region=us-east-1"
   ```

2. **Test DNS Failover**
   ```bash
   # Get Route 53 health check ID
   HEALTH_CHECK_ID=$(terraform output -raw health_check_id)
   
   # Monitor health check status
   aws route53 get-health-check --health-check-id $HEALTH_CHECK_ID
   
   # Test DNS resolution
   dig $(terraform output -raw domain_name)
   ```

3. **Simulate Primary Region Failure**
   ```bash
   # Simulate failure by updating health check to fail
   aws route53 change-tags-for-resource \
     --resource-type healthcheck \
     --resource-id $HEALTH_CHECK_ID \
     --add-tags Key=TestFailure,Value=true
   
   # Monitor DNS failover
   watch "dig $(terraform output -raw domain_name)"
   ```

4. **Test DR Orchestration**
   ```bash
   # Get Lambda function name
   DR_FUNCTION=$(terraform output -raw dr_orchestrator_function_name)
   
   # Manually trigger DR orchestration
   aws lambda invoke \
     --function-name $DR_FUNCTION \
     --payload '{"test": true, "failure_type": "primary_region_failure"}' \
     response.json
   
   cat response.json
   ```

### Exercise 2: Comprehensive Backup Strategy

**Objective:** Implement automated backup and restore testing for critical resources

**Steps:**

1. **Deploy Backup Infrastructure**
   ```bash
   cd examples/02-backup-restore
   terraform init
   terraform apply
   ```

2. **Create Test Resources**
   ```bash
   # Create test RDS cluster
   aws rds create-db-cluster \
     --db-cluster-identifier test-cluster-for-backup \
     --engine aurora-mysql \
     --master-username admin \
     --master-user-password TestPassword123! \
     --tags Key=Project,Value=$(terraform output -raw project_name) \
            Key=Environment,Value=$(terraform output -raw environment)
   ```

3. **Monitor Backup Jobs**
   ```bash
   # List backup jobs
   aws backup list-backup-jobs \
     --by-backup-vault-name $(terraform output -raw backup_vault_name)
   
   # Get backup job details
   aws backup describe-backup-job --backup-job-id <job-id>
   ```

4. **Test Restore Process**
   ```bash
   # List recovery points
   aws backup list-recovery-points \
     --backup-vault-name $(terraform output -raw backup_vault_name)
   
   # Trigger restore test
   aws lambda invoke \
     --function-name $(terraform output -raw restore_tester_function_name) \
     --payload '{"test_restore": true}' \
     restore_response.json
   ```

### Exercise 3: Chaos Engineering for DR Testing

**Objective:** Implement chaos engineering practices to test system resilience

**Steps:**

1. **Install AWS Fault Injection Simulator**
   ```bash
   # Create FIS experiment template
   cat > fis-template.json << EOF
   {
     "description": "Test database failover resilience",
     "roleArn": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/FISRole",
     "actions": {
       "StopDBCluster": {
         "actionId": "aws:rds:stop-db-cluster",
         "parameters": {
           "forceFailover": "true"
         },
         "targets": {
           "Clusters": "DBClusters"
         }
       }
     },
     "targets": {
       "DBClusters": {
         "resourceType": "aws:rds:cluster",
         "resourceTags": {
           "Project": "$(terraform output -raw project_name)"
         },
         "selectionMode": "ALL"
       }
     },
     "stopConditions": [
       {
         "source": "aws:cloudwatch:alarm",
         "value": "arn:aws:cloudwatch:us-west-2:$(aws sts get-caller-identity --query Account --output text):alarm:HighErrorRate"
       }
     ],
     "tags": {
       "Name": "DR-Chaos-Test"
     }
   }
   EOF
   ```

2. **Run Chaos Experiments**
   ```bash
   # Create experiment
   aws fis create-experiment-template \
     --cli-input-json file://fis-template.json
   
   # Start experiment
   EXPERIMENT_ID=$(aws fis start-experiment \
     --experiment-template-id <template-id> \
     --query 'experiment.id' --output text)
   
   # Monitor experiment
   aws fis get-experiment --id $EXPERIMENT_ID
   ```

3. **Analyze Results**
   ```bash
   # Check application metrics during chaos
   aws cloudwatch get-metric-statistics \
     --namespace "Custom/$(terraform output -raw project_name)" \
     --metric-name ErrorRate \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Average
   ```

## ✅ Best Practices

### 1. Recovery Objectives Definition
- **Define clear RTO and RPO** based on business requirements, not technical capabilities
- **Document recovery procedures** with step-by-step runbooks
- **Test recovery objectives** regularly to ensure they meet business needs
- **Align costs with criticality** - not everything needs the same level of protection
- **Consider regulatory requirements** for data retention and recovery

### 2. Multi-Region Strategy
- **Choose regions based on latency and compliance** requirements
- **Implement automated health checks** that can detect various failure modes
- **Use DNS-based failover** for automatic traffic routing
- **Consider data sovereignty** and regulatory requirements for cross-border replication
- **Plan for region-wide outages** with geographically diverse backup regions

### 3. Backup Strategy
- **Implement the 3-2-1 rule**: 3 copies, 2 different media types, 1 offsite
- **Automate backup validation** to ensure backups are actually usable
- **Test restore procedures** regularly, not just backups
- **Encrypt backups** both in transit and at rest
- **Monitor backup job success** and alert on failures

### 4. Data Consistency
- **Design for eventual consistency** when using cross-region replication
- **Implement conflict resolution** strategies for data synchronization
- **Use checksums and validation** to ensure data integrity
- **Plan for split-brain scenarios** where regions become isolated
- **Document data flow** and dependencies between systems

### 5. Testing and Validation
- **Conduct regular DR drills** with realistic failure scenarios
- **Use chaos engineering** to test system resilience
- **Validate RTO and RPO** through actual testing, not assumptions
- **Include people and processes** in DR testing, not just technology
- **Learn from failures** and continuously improve procedures

## ⚠️ Common Pitfalls

### 1. Untested Recovery Procedures
**Problem:** DR plans that look good on paper but fail during actual disasters
**Solution:**
```python
# Automated DR testing framework
class DRTestFramework:
    def __init__(self, test_scenarios):
        self.test_scenarios = test_scenarios
        self.test_results = []
    
    def run_automated_dr_tests(self):
        for scenario in self.test_scenarios:
            test_result = {
                'scenario': scenario['name'],
                'start_time': datetime.utcnow(),
                'success': False,
                'rto_actual': None,
                'rpo_actual': None,
                'issues': []
            }
            
            try:
                # Execute DR scenario
                self.execute_scenario(scenario)
                test_result['success'] = True
                test_result['rto_actual'] = self.measure_rto(scenario)
                test_result['rpo_actual'] = self.measure_rpo(scenario)
            except Exception as e:
                test_result['issues'].append(str(e))
            
            self.test_results.append(test_result)
            self.cleanup_scenario(scenario)
        
        return self.generate_report()
```

### 2. Cross-Region Dependencies
**Problem:** Circular dependencies between regions preventing proper failover
**Solution:**
- Design regions to be completely independent
- Avoid cross-region resource dependencies
- Use separate state files for each region
- Implement region-specific DNS and networking

### 3. Data Consistency Issues
**Problem:** Data inconsistencies arising from asynchronous replication
**Solution:**
- Implement application-level consistency checks
- Use conflict resolution strategies
- Design for eventual consistency from the beginning
- Monitor replication lag and alert on excessive delays

### 4. Insufficient Backup Testing
**Problem:** Discovering backup corruption or incompleteness during recovery
**Solution:**
- Implement automated backup validation
- Regularly test restore procedures in isolated environments
- Use checksums and integrity verification
- Monitor backup job completion and file integrity

### 5. Human Process Failures
**Problem:** Technical solutions work but human processes fail during disasters
**Solution:**
- Document detailed runbooks with screenshots
- Train multiple team members on DR procedures
- Practice DR scenarios regularly with the actual team
- Automate as much as possible to reduce human error

## 🔍 Troubleshooting

### Backup Job Failures

**Problem:** AWS Backup jobs failing or taking too long

**Diagnosis:**
```bash
# Check backup job status
aws backup list-backup-jobs \
  --by-state FAILED \
  --query 'BackupJobs[*].{JobId:BackupJobId,State:State,StatusMessage:StatusMessage}'

# Check IAM permissions
aws backup describe-backup-job --backup-job-id <job-id>

# Verify resource tagging
aws backup list-protected-resources
```

**Solutions:**
1. Verify IAM role permissions for AWS Backup
2. Check resource tags match backup selection criteria
3. Ensure backup window allows sufficient time
4. Review resource-specific backup requirements

### Cross-Region Replication Issues

**Problem:** Data not replicating properly between regions

**Diagnosis:**
```bash
# Check RDS cross-region automated backups
aws rds describe-db-clusters \
  --query 'DBClusters[*].{Id:DBClusterIdentifier,BackupRetentionPeriod:BackupRetentionPeriod}'

# Verify VPC peering connection
aws ec2 describe-vpc-peering-connections \
  --filters Name=status-code,Values=active

# Check network connectivity between regions
aws ec2 describe-route-tables
```

**Solutions:**
1. Verify network connectivity between regions
2. Check security group rules for replication traffic
3. Ensure proper IAM permissions for cross-region access
4. Validate replication configuration settings

### DNS Failover Not Working

**Problem:** Route 53 health checks not triggering failover

**Diagnosis:**
```bash
# Check health check status
aws route53 get-health-check --health-check-id <health-check-id>

# Review health check history
aws route53 get-health-check-status --health-check-id <health-check-id>

# Verify DNS record configuration
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>
```

**Solutions:**
1. Verify health check endpoint is accessible
2. Check security group rules allow health check traffic
3. Ensure health check path returns expected status code
4. Review Route 53 failover policy configuration

## 📚 Further Reading

### Official Documentation
- [AWS Disaster Recovery Strategies](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html)
- [AWS Backup Documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/)
- [Amazon Route 53 Health Checks](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/health-checks-how-they-work.html)
- [AWS Well-Architected Framework - Reliability Pillar](https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/)

### Disaster Recovery Best Practices
- [Building Resilient Systems on AWS](https://aws.amazon.com/architecture/reliability/)
- [Disaster Recovery Planning Guide](https://www.ready.gov/business/implementation/IT)
- [Business Continuity Planning](https://www.nist.gov/cyberframework/business-continuity)

### Chaos Engineering and Testing
- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [AWS Fault Injection Simulator](https://docs.aws.amazon.com/fis/latest/userguide/)
- [Chaos Monkey and Netflix's Approach](https://netflix.github.io/chaosmonkey/)

### Software Engineering Patterns
- [Release It! Design and Deploy Production-Ready Software](https://pragprog.com/titles/mnee2/release-it-second-edition/)
- [Building Microservices by Sam Newman](https://samnewman.io/books/building_microservices/)
- [Site Reliability Engineering by Google](https://sre.google/books/)

### Community Resources
- [AWS Disaster Recovery Samples](https://github.com/aws-samples/disaster-recovery-workshop)
- [Terraform AWS Multi-Region Examples](https://github.com/terraform-aws-modules)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)

## 🎯 Next Steps

Congratulations! You've mastered disaster recovery and business continuity planning principles. You now understand how to:

- Design and implement multi-region disaster recovery architectures
- Build comprehensive backup and restore systems with validation
- Establish recovery time and recovery point objectives that align with business needs
- Configure automated failover mechanisms across regions
- Apply software engineering resilience patterns to infrastructure design
- Test and validate disaster recovery procedures through chaos engineering
- Troubleshoot complex DR scenarios and system failures

**Ready for the final challenge?** Proceed to [Module 09: Compliance](../09-compliance/) to learn how to implement governance frameworks, policy as code, and regulatory compliance that ensures your infrastructure meets enterprise and regulatory requirements.

### Skills Gained
✅ Multi-region disaster recovery architecture design  
✅ Automated backup and restore system implementation  
✅ Business continuity planning and RTO/RPO establishment  
✅ Cross-region data replication and failover configuration  
✅ Resilience testing with chaos engineering  
✅ Software engineering resilience pattern application  
✅ DNS-based failover and health check configuration  
✅ Disaster recovery automation and orchestration  
✅ DR testing and validation procedures  

### Career Impact
These disaster recovery skills are essential for senior infrastructure and reliability roles:
- **Senior DevOps Engineer**: Implementing enterprise DR strategies and automation
- **Site Reliability Engineer**: Ensuring system resilience and business continuity
- **Cloud Architect**: Designing fault-tolerant, multi-region architectures
- **Infrastructure Manager**: Leading DR planning and business continuity initiatives
- **Principal Engineer**: Setting organizational standards for resilience and disaster recovery