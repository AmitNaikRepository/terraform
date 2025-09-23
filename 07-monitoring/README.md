# Module 07: Monitoring → Observability Engineering

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Design Comprehensive Monitoring**: Implement multi-layer monitoring strategies using CloudWatch, custom metrics, and distributed tracing
- **Build Observability Pipelines**: Create log aggregation, metric collection, and trace correlation systems that provide end-to-end visibility
- **Implement Alerting Systems**: Design intelligent alerting with proper escalation, noise reduction, and incident response automation
- **Deploy Application Performance Monitoring (APM)**: Integrate application-level monitoring with infrastructure metrics for complete observability
- **Create Monitoring Dashboards**: Build actionable dashboards that enable quick problem identification and resolution
- **Establish SLAs and SLOs**: Define and monitor service level objectives that align with business requirements
- **Apply Observability Patterns**: Connect infrastructure monitoring to software engineering practices like distributed tracing, structured logging, and chaos engineering
- **Implement Proactive Monitoring**: Build systems that predict and prevent issues before they impact users

## 🎯 Overview

Monitoring in modern infrastructure is fundamentally about observability - the ability to understand system behavior from its external outputs. This module explores how monitoring infrastructure mirrors software engineering observability practices and how proper monitoring enables reliable, high-performance applications.

Just as software engineers implement logging, metrics, and tracing to understand application behavior, infrastructure engineers must create comprehensive observability systems that provide insights into system health, performance, and user experience. Understanding these patterns is crucial for building reliable systems that can be debugged, optimized, and scaled effectively.

## 📖 Core Concepts

### The Three Pillars of Observability

#### 1. Metrics (What is happening?)
- **Infrastructure Metrics**: CPU, memory, disk, network utilization
- **Application Metrics**: Request rate, error rate, response time
- **Business Metrics**: User engagement, conversion rates, revenue impact
- **Custom Metrics**: Domain-specific measurements and KPIs

#### 2. Logs (What happened?)
- **Infrastructure Logs**: System events, security logs, audit trails
- **Application Logs**: Business logic, errors, debug information
- **Access Logs**: User interactions, API calls, request patterns
- **Structured Logging**: Machine-readable log formats with correlation IDs

#### 3. Traces (How did it happen?)
- **Distributed Tracing**: Request flow across multiple services
- **Transaction Tracing**: End-to-end request journey
- **Dependency Mapping**: Service interaction patterns
- **Performance Profiling**: Resource usage and bottleneck identification

### Software Engineering Parallels

| Infrastructure Concept | Software Engineering Pattern | Purpose |
|------------------------|------------------------------|---------|
| CloudWatch Dashboards | Application Dashboards | Real-time system visualization |
| Log Aggregation | Centralized Logging | Unified log analysis across services |
| Distributed Tracing | Request Correlation | Track requests across service boundaries |
| Alerting Rules | Exception Handling | Automated response to system anomalies |
| SLA/SLO Monitoring | Unit Test Coverage | Measurable quality and reliability targets |
| Synthetic Monitoring | Integration Testing | Proactive validation of system functionality |

### Monitoring Architecture Layers

#### 1. Infrastructure Layer
- **Host Monitoring**: Server health, resource utilization
- **Network Monitoring**: Connectivity, latency, throughput
- **Storage Monitoring**: Disk usage, IOPS, latency
- **Container Monitoring**: Pod health, resource constraints

#### 2. Platform Layer
- **Load Balancer Monitoring**: Traffic distribution, health checks
- **Database Monitoring**: Query performance, connection pools
- **Cache Monitoring**: Hit rates, memory usage, eviction rates
- **Message Queue Monitoring**: Queue depth, processing rates

#### 3. Application Layer
- **API Monitoring**: Endpoint performance, error rates
- **User Experience Monitoring**: Page load times, user interactions
- **Business Logic Monitoring**: Feature usage, business metrics
- **Security Monitoring**: Authentication, authorization, threats

### Key Performance Indicators (KPIs)

#### Golden Signals
- **Latency**: Request duration and distribution
- **Traffic**: Request rate and volume
- **Errors**: Error rate and types
- **Saturation**: Resource utilization and capacity

#### SRE Metrics
- **Availability**: Uptime percentage and outage duration
- **Reliability**: Mean time between failures (MTBF)
- **Performance**: Response time percentiles (P50, P95, P99)
- **Recovery**: Mean time to recovery (MTTR)

## 🛠️ Terraform Implementation

### 1. Comprehensive CloudWatch Monitoring

This implementation creates a complete monitoring infrastructure with metrics, logs, and alarms:

```hcl
# examples/01-comprehensive-monitoring/main.tf

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
      Module      = "Comprehensive-Monitoring"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# SNS Topics for different alert severity levels
resource "aws_sns_topic" "critical_alerts" {
  name         = "${var.project_name}-${var.environment}-critical-alerts"
  display_name = "Critical Alerts for ${var.project_name}"

  tags = {
    Name     = "${var.project_name}-${var.environment}-critical-alerts"
    Severity = "critical"
  }
}

resource "aws_sns_topic" "warning_alerts" {
  name         = "${var.project_name}-${var.environment}-warning-alerts"
  display_name = "Warning Alerts for ${var.project_name}"

  tags = {
    Name     = "${var.project_name}-${var.environment}-warning-alerts"
    Severity = "warning"
  }
}

resource "aws_sns_topic" "info_alerts" {
  name         = "${var.project_name}-${var.environment}-info-alerts"
  display_name = "Info Alerts for ${var.project_name}"

  tags = {
    Name     = "${var.project_name}-${var.environment}-info-alerts"
    Severity = "info"
  }
}

# SNS Topic Subscriptions (customize based on your notification preferences)
resource "aws_sns_topic_subscription" "critical_email" {
  count = length(var.critical_notification_emails)
  
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.critical_notification_emails[count.index]
}

resource "aws_sns_topic_subscription" "warning_email" {
  count = length(var.warning_notification_emails)
  
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = var.warning_notification_emails[count.index]
}

# CloudWatch Log Groups for different services
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-logs"
    Application = "main-app"
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/api/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-api-logs"
    Application = "api"
  }
}

resource "aws_cloudwatch_log_group" "database" {
  name              = "/aws/rds/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-logs"
    Application = "database"
  }
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-${var.environment}-lambda-logs"
    Application = "serverless"
  }
}

# Custom CloudWatch Log Metric Filters
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.project_name}-${var.environment}-error-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "[timestamp, request_id, level=\"ERROR\", ...]"

  metric_transformation {
    name      = "ApplicationErrorCount"
    namespace = "Custom/${var.project_name}"
    value     = "1"
    
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "api_latency" {
  name           = "${var.project_name}-${var.environment}-api-latency"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "[timestamp, request_id, method, uri, status, duration]"

  metric_transformation {
    name      = "APILatency"
    namespace = "Custom/${var.project_name}"
    value     = "$duration"
    
    default_value = 0
  }
}

resource "aws_cloudwatch_log_metric_filter" "database_slow_queries" {
  name           = "${var.project_name}-${var.environment}-slow-queries"
  log_group_name = aws_cloudwatch_log_group.database.name
  pattern        = "[timestamp, query_time>2000, ...]"

  metric_transformation {
    name      = "SlowQueryCount"
    namespace = "Custom/${var.project_name}"
    value     = "1"
    
    default_value = 0
  }
}

# CloudWatch Composite Alarms
resource "aws_cloudwatch_composite_alarm" "application_health" {
  alarm_name        = "${var.project_name}-${var.environment}-application-health"
  alarm_description = "Overall application health based on multiple metrics"
  
  alarm_rule = join(" OR ", [
    "ALARM(${aws_cloudwatch_metric_alarm.high_error_rate.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.high_response_time.alarm_name})",
    "ALARM(${aws_cloudwatch_metric_alarm.low_availability.alarm_name})"
  ])

  actions_enabled = true
  alarm_actions   = [aws_sns_topic.critical_alerts.arn]
  ok_actions      = [aws_sns_topic.info_alerts.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-application-health"
  }
}

# Individual CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApplicationErrorCount"
  namespace           = "Custom/${var.project_name}"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "This metric monitors application error rate"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.info_alerts.arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name     = "${var.project_name}-${var.environment}-high-error-rate"
    Severity = "critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.project_name}-${var.environment}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "APILatency"
  namespace           = "Custom/${var.project_name}"
  period              = "300"
  statistic           = "Average"
  threshold           = var.response_time_threshold
  alarm_description   = "This metric monitors API response time"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]
  ok_actions         = [aws_sns_topic.info_alerts.arn]

  treat_missing_data = "notBreaching"

  tags = {
    Name     = "${var.project_name}-${var.environment}-high-response-time"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "low_availability" {
  alarm_name          = "${var.project_name}-${var.environment}-low-availability"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = var.min_healthy_hosts
  alarm_description   = "This metric monitors healthy host count"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions         = [aws_sns_topic.info_alerts.arn]

  dimensions = {
    LoadBalancer = var.load_balancer_full_name
  }

  treat_missing_data = "breaching"

  tags = {
    Name     = "${var.project_name}-${var.environment}-low-availability"
    Severity = "critical"
  }
}

# Database monitoring alarms
resource "aws_cloudwatch_metric_alarm" "database_cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-database-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.database_cpu_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.database_cluster_identifier
  }

  tags = {
    Name     = "${var.project_name}-${var.environment}-database-cpu-high"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connections_high" {
  alarm_name          = "${var.project_name}-${var.environment}-database-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = var.database_connections_threshold
  alarm_description   = "This metric monitors RDS connection count"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    DBClusterIdentifier = var.database_cluster_identifier
  }

  tags = {
    Name     = "${var.project_name}-${var.environment}-database-connections-high"
    Severity = "warning"
  }
}

# Custom CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      # Application Health Overview
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Custom/${var.project_name}", "ApplicationErrorCount", { "stat": "Sum", "period": 300 }],
            [".", "APILatency", { "stat": "Average", "period": 300 }],
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.load_balancer_full_name],
            [".", "TargetResponseTime", "LoadBalancer", var.load_balancer_full_name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Application Health Overview"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      
      # Infrastructure Metrics
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.auto_scaling_group_name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."],
            ["AWS/ApplicationELB", "ActiveConnectionCount", "LoadBalancer", var.load_balancer_full_name]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Infrastructure Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      
      # Database Performance
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.database_cluster_identifier],
            [".", "DatabaseConnections", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."],
            ["Custom/${var.project_name}", "SlowQueryCount"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Database Performance"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      
      # Error Rate and Availability
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", var.load_balancer_full_name],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."],
            [".", "HealthyHostCount", ".", "."],
            [".", "UnHealthyHostCount", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Error Rate and Availability"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
      },
      
      # Log Insights Query Widget
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '${aws_cloudwatch_log_group.application.name}' | fields @timestamp, level, message | filter level = 'ERROR' | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent Application Errors"
          view    = "table"
        }
      }
    ]
  })
}

# CloudWatch Insights Saved Queries
resource "aws_cloudwatch_query_definition" "error_analysis" {
  name = "${var.project_name}-${var.environment}-error-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.application.name,
    aws_cloudwatch_log_group.api.name
  ]

  query_string = <<EOF
fields @timestamp, level, message, request_id
| filter level = "ERROR"
| stats count() by bin(5m)
| sort @timestamp desc
EOF
}

resource "aws_cloudwatch_query_definition" "performance_analysis" {
  name = "${var.project_name}-${var.environment}-performance-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.api.name
  ]

  query_string = <<EOF
fields @timestamp, method, uri, status, duration
| filter duration > 1000
| stats avg(duration), max(duration), count() by uri
| sort avg desc
EOF
}

resource "aws_cloudwatch_query_definition" "user_activity_analysis" {
  name = "${var.project_name}-${var.environment}-user-activity"

  log_group_names = [
    aws_cloudwatch_log_group.application.name
  ]

  query_string = <<EOF
fields @timestamp, user_id, action, ip_address
| filter ispresent(user_id)
| stats count() as request_count by user_id
| sort request_count desc
| limit 50
EOF
}

# EventBridge Rules for Advanced Alerting
resource "aws_cloudwatch_event_rule" "auto_scaling_events" {
  name        = "${var.project_name}-${var.environment}-autoscaling-events"
  description = "Capture Auto Scaling events"

  event_pattern = jsonencode({
    source      = ["aws.autoscaling"]
    detail-type = ["EC2 Instance Launch Successful", "EC2 Instance Launch Unsuccessful", "EC2 Instance Terminate Successful"]
    detail = {
      AutoScalingGroupName = [var.auto_scaling_group_name]
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-autoscaling-events"
  }
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.auto_scaling_events.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.info_alerts.arn
}

# Lambda function for custom metric collection
resource "aws_lambda_function" "custom_metrics_collector" {
  filename         = "custom_metrics_collector.zip"
  function_name    = "${var.project_name}-${var.environment}-metrics-collector"
  role            = aws_iam_role.lambda_metrics_collector.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.custom_metrics_collector.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-metrics-collector"
  }
}

# Archive custom metrics collector code
data "archive_file" "custom_metrics_collector" {
  type        = "zip"
  output_path = "custom_metrics_collector.zip"
  
  source {
    content = templatefile("${path.module}/lambda/custom_metrics_collector.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for Lambda metrics collector
resource "aws_iam_role" "lambda_metrics_collector" {
  name = "${var.project_name}-${var.environment}-lambda-metrics-collector"

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

resource "aws_iam_role_policy" "lambda_metrics_collector" {
  name = "${var.project_name}-${var.environment}-lambda-metrics-policy"
  role = aws_iam_role.lambda_metrics_collector.id

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
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.project_name}-${var.environment}-metrics-collector:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "elbv2:DescribeTargetGroups",
          "elbv2:DescribeTargetHealth"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Event Rule to trigger custom metrics collection
resource "aws_cloudwatch_event_rule" "custom_metrics_schedule" {
  name                = "${var.project_name}-${var.environment}-metrics-schedule"
  description         = "Trigger custom metrics collection every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = {
    Name = "${var.project_name}-${var.environment}-metrics-schedule"
  }
}

resource "aws_cloudwatch_event_target" "custom_metrics_lambda" {
  rule      = aws_cloudwatch_event_rule.custom_metrics_schedule.name
  target_id = "CustomMetricsLambda"
  arn       = aws_lambda_function.custom_metrics_collector.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.custom_metrics_collector.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.custom_metrics_schedule.arn
}
```

```python
# examples/01-comprehensive-monitoring/lambda/custom_metrics_collector.py

import json
import boto3
import os
from datetime import datetime, timedelta
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
cloudwatch = boto3.client('cloudwatch')
ec2 = boto3.client('ec2')
autoscaling = boto3.client('autoscaling')
elbv2 = boto3.client('elbv2')

PROJECT_NAME = os.environ.get('PROJECT_NAME', 'monitoring-demo')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')

def handler(event, context):
    """
    Lambda function to collect and publish custom metrics
    """
    try:
        logger.info(f"Starting custom metrics collection for {PROJECT_NAME}-{ENVIRONMENT}")
        
        # Collect various custom metrics
        collect_instance_health_metrics()
        collect_application_performance_metrics()
        collect_cost_optimization_metrics()
        collect_security_metrics()
        
        return {
            'statusCode': 200,
            'body': json.dumps('Custom metrics collection completed successfully')
        }
    except Exception as e:
        logger.error(f"Error in custom metrics collection: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error: {str(e)}')
        }

def collect_instance_health_metrics():
    """Collect EC2 instance health and utilization metrics"""
    try:
        # Get instances in Auto Scaling Groups
        asg_response = autoscaling.describe_auto_scaling_groups(
            AutoScalingGroupNames=[f"{PROJECT_NAME}-{ENVIRONMENT}-web-asg"]
        )
        
        for asg in asg_response['AutoScalingGroups']:
            instance_ids = [instance['InstanceId'] for instance in asg['Instances'] 
                          if instance['LifecycleState'] == 'InService']
            
            if instance_ids:
                # Get instance details
                instances_response = ec2.describe_instances(InstanceIds=instance_ids)
                
                healthy_count = 0
                total_count = len(instance_ids)
                
                for reservation in instances_response['Reservations']:
                    for instance in reservation['Instances']:
                        if instance['State']['Name'] == 'running':
                            healthy_count += 1
                
                # Publish custom health ratio metric
                cloudwatch.put_metric_data(
                    Namespace=f'Custom/{PROJECT_NAME}',
                    MetricData=[
                        {
                            'MetricName': 'HealthyInstanceRatio',
                            'Value': (healthy_count / total_count) * 100 if total_count > 0 else 0,
                            'Unit': 'Percent',
                            'Dimensions': [
                                {
                                    'Name': 'AutoScalingGroup',
                                    'Value': asg['AutoScalingGroupName']
                                }
                            ]
                        },
                        {
                            'MetricName': 'InstanceCount',
                            'Value': total_count,
                            'Unit': 'Count',
                            'Dimensions': [
                                {
                                    'Name': 'AutoScalingGroup',
                                    'Value': asg['AutoScalingGroupName']
                                },
                                {
                                    'Name': 'InstanceState',
                                    'Value': 'Total'
                                }
                            ]
                        },
                        {
                            'MetricName': 'InstanceCount',
                            'Value': healthy_count,
                            'Unit': 'Count',
                            'Dimensions': [
                                {
                                    'Name': 'AutoScalingGroup',
                                    'Value': asg['AutoScalingGroupName']
                                },
                                {
                                    'Name': 'InstanceState',
                                    'Value': 'Healthy'
                                }
                            ]
                        }
                    ]
                )
        
        logger.info("Instance health metrics collected successfully")
    except Exception as e:
        logger.error(f"Error collecting instance health metrics: {str(e)}")

def collect_application_performance_metrics():
    """Collect application-specific performance metrics"""
    try:
        # Calculate request success rate from CloudWatch metrics
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(minutes=5)
        
        # Get successful requests (2xx responses)
        success_response = cloudwatch.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName='HTTPCode_Target_2XX_Count',
            Dimensions=[
                {
                    'Name': 'LoadBalancer',
                    'Value': f"{PROJECT_NAME}-{ENVIRONMENT}-alb"
                }
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=300,
            Statistics=['Sum']
        )
        
        # Get total requests
        total_response = cloudwatch.get_metric_statistics(
            Namespace='AWS/ApplicationELB',
            MetricName='RequestCount',
            Dimensions=[
                {
                    'Name': 'LoadBalancer',
                    'Value': f"{PROJECT_NAME}-{ENVIRONMENT}-alb"
                }
            ],
            StartTime=start_time,
            EndTime=end_time,
            Period=300,
            Statistics=['Sum']
        )
        
        # Calculate success rate
        success_count = sum([dp['Sum'] for dp in success_response['Datapoints']])
        total_count = sum([dp['Sum'] for dp in total_response['Datapoints']])
        
        success_rate = (success_count / total_count) * 100 if total_count > 0 else 100
        
        # Publish success rate metric
        cloudwatch.put_metric_data(
            Namespace=f'Custom/{PROJECT_NAME}',
            MetricData=[
                {
                    'MetricName': 'RequestSuccessRate',
                    'Value': success_rate,
                    'Unit': 'Percent',
                    'Dimensions': [
                        {
                            'Name': 'Environment',
                            'Value': ENVIRONMENT
                        }
                    ]
                }
            ]
        )
        
        logger.info(f"Application performance metrics collected: Success Rate = {success_rate:.2f}%")
    except Exception as e:
        logger.error(f"Error collecting application performance metrics: {str(e)}")

def collect_cost_optimization_metrics():
    """Collect metrics for cost optimization monitoring"""
    try:
        # Get Auto Scaling Group capacity metrics
        asg_response = autoscaling.describe_auto_scaling_groups(
            AutoScalingGroupNames=[f"{PROJECT_NAME}-{ENVIRONMENT}-web-asg"]
        )
        
        for asg in asg_response['AutoScalingGroups']:
            capacity_utilization = (
                asg['DesiredCapacity'] / asg['MaxSize']
            ) * 100 if asg['MaxSize'] > 0 else 0
            
            # Publish capacity utilization metric
            cloudwatch.put_metric_data(
                Namespace=f'Custom/{PROJECT_NAME}',
                MetricData=[
                    {
                        'MetricName': 'CapacityUtilization',
                        'Value': capacity_utilization,
                        'Unit': 'Percent',
                        'Dimensions': [
                            {
                                'Name': 'AutoScalingGroup',
                                'Value': asg['AutoScalingGroupName']
                            }
                        ]
                    },
                    {
                        'MetricName': 'DesiredCapacity',
                        'Value': asg['DesiredCapacity'],
                        'Unit': 'Count',
                        'Dimensions': [
                            {
                                'Name': 'AutoScalingGroup',
                                'Value': asg['AutoScalingGroupName']
                            }
                        ]
                    }
                ]
            )
        
        logger.info("Cost optimization metrics collected successfully")
    except Exception as e:
        logger.error(f"Error collecting cost optimization metrics: {str(e)}")

def collect_security_metrics():
    """Collect security-related metrics"""
    try:
        # This is a placeholder for security metrics collection
        # In a real implementation, you might:
        # - Check for failed login attempts
        # - Monitor suspicious API calls
        # - Track certificate expiration dates
        # - Monitor security group changes
        
        # Example: Track certificate days until expiration
        import ssl
        import socket
        from datetime import datetime
        
        # Check SSL certificate expiration (example)
        hostname = f"{PROJECT_NAME}-{ENVIRONMENT}.example.com"
        try:
            context = ssl.create_default_context()
            with socket.create_connection((hostname, 443), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert = ssock.getpeercert()
                    # Parse certificate expiration date
                    expire_date = datetime.strptime(cert['notAfter'], '%b %d %H:%M:%S %Y %Z')
                    days_until_expiry = (expire_date - datetime.now()).days
                    
                    # Publish certificate expiration metric
                    cloudwatch.put_metric_data(
                        Namespace=f'Custom/{PROJECT_NAME}',
                        MetricData=[
                            {
                                'MetricName': 'CertificateDaysUntilExpiry',
                                'Value': days_until_expiry,
                                'Unit': 'Count',
                                'Dimensions': [
                                    {
                                        'Name': 'Domain',
                                        'Value': hostname
                                    }
                                ]
                            }
                        ]
                    )
        except Exception:
            # Certificate check failed - might not exist yet
            pass
        
        logger.info("Security metrics collected successfully")
    except Exception as e:
        logger.error(f"Error collecting security metrics: {str(e)}")
```

```hcl
# examples/01-comprehensive-monitoring/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "monitoring-demo"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be a valid CloudWatch retention period."
  }
}

variable "critical_notification_emails" {
  description = "List of email addresses for critical alerts"
  type        = list(string)
  default     = ["admin@example.com"]
}

variable "warning_notification_emails" {
  description = "List of email addresses for warning alerts"
  type        = list(string)
  default     = ["team@example.com"]
}

variable "error_rate_threshold" {
  description = "Threshold for error rate alarm (errors per 5 minutes)"
  type        = number
  default     = 10
}

variable "response_time_threshold" {
  description = "Threshold for response time alarm (milliseconds)"
  type        = number
  default     = 2000
}

variable "min_healthy_hosts" {
  description = "Minimum number of healthy hosts"
  type        = number
  default     = 1
}

variable "database_cpu_threshold" {
  description = "Database CPU utilization threshold (%)"
  type        = number
  default     = 80
}

variable "database_connections_threshold" {
  description = "Database connections threshold"
  type        = number
  default     = 80
}

# Variables that would typically come from other modules or data sources
variable "load_balancer_full_name" {
  description = "Full name of the load balancer (for CloudWatch metrics)"
  type        = string
  default     = "app/my-load-balancer/50dc6c495c0c9188"
}

variable "auto_scaling_group_name" {
  description = "Name of the Auto Scaling Group"
  type        = string
  default     = "my-auto-scaling-group"
}

variable "database_cluster_identifier" {
  description = "RDS cluster identifier"
  type        = string
  default     = "my-database-cluster"
}
```

### 2. Distributed Tracing with X-Ray

```hcl
# examples/02-distributed-tracing/main.tf

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
      Module      = "Distributed-Tracing"
    }
  }
}

# X-Ray service role for Lambda tracing
resource "aws_iam_role" "xray_role" {
  name = "${var.project_name}-${var.environment}-xray-role"

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

resource "aws_iam_role_policy_attachment" "xray_write_only_access" {
  role       = aws_iam_role.xray_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Lambda function with X-Ray tracing
resource "aws_lambda_function" "api_handler" {
  filename         = "api_handler.zip"
  function_name    = "${var.project_name}-${var.environment}-api-handler"
  role            = aws_iam_role.xray_role.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 30

  source_code_hash = data.archive_file.api_handler.output_base64sha256

  # Enable X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      _X_AMZN_TRACE_ID = ""  # This will be populated by X-Ray
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api-handler"
  }
}

data "archive_file" "api_handler" {
  type        = "zip"
  output_path = "api_handler.zip"
  
  source {
    content = templatefile("${path.module}/lambda/api_handler.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# API Gateway with X-Ray tracing
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "API Gateway with X-Ray tracing"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api"
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  # Enable X-Ray tracing
  xray_tracing_enabled = true

  # Access logging
  access_log_destination_arn = aws_cloudwatch_log_group.api_gateway.arn
  access_log_format = jsonencode({
    requestId      = "$requestId"
    ip            = "$sourceIp"
    caller        = "$caller"
    user          = "$user"
    requestTime   = "$requestTime"
    httpMethod    = "$httpMethod"
    resourcePath  = "$resourcePath"
    status        = "$status"
    protocol      = "$protocol"
    responseLength = "$responseLength"
    xrayTraceId   = "$xrayTraceId"
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-api-stage"
  }
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-api-gateway-logs"
  }
}

# API Gateway resources and methods
resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "users"
}

resource "aws_api_gateway_method" "get_users" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.users.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_users" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.users.id
  http_method = aws_api_gateway_method.get_users.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.api_handler.invoke_arn
}

resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.get_users,
    aws_api_gateway_integration.get_users
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.users.id,
      aws_api_gateway_method.get_users.id,
      aws_api_gateway_integration.get_users.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# CloudWatch Insights queries for X-Ray analysis
resource "aws_cloudwatch_query_definition" "xray_trace_analysis" {
  name = "${var.project_name}-${var.environment}-xray-trace-analysis"

  log_group_names = [
    aws_cloudwatch_log_group.api_gateway.name
  ]

  query_string = <<EOF
fields @timestamp, xrayTraceId, status, responseLength, requestTime
| filter ispresent(xrayTraceId)
| stats count() as request_count, avg(responseLength) as avg_response_size by status
| sort request_count desc
EOF
}

# CloudWatch Dashboard for distributed tracing
resource "aws_cloudwatch_dashboard" "tracing" {
  dashboard_name = "${var.project_name}-${var.environment}-tracing"

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
            ["AWS/X-Ray", "TracesReceived"],
            [".", "TracesPublished"],
            [".", "LatencyHigh", "ServiceName", "${var.project_name}-${var.environment}-api-handler", "ServiceType", "AWS::Lambda::Function"],
            [".", "ResponseTimeRoot", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "X-Ray Trace Metrics"
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
            ["AWS/ApiGateway", "Count", "ApiName", "${var.project_name}-${var.environment}-api", "Stage", var.environment],
            [".", "Latency", ".", ".", ".", "."],
            [".", "4XXError", ".", ".", ".", "."],
            [".", "5XXError", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "API Gateway Metrics"
        }
      }
    ]
  })
}
```

```python
# examples/02-distributed-tracing/lambda/api_handler.py

import json
import boto3
import os
import time
import random
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Patch AWS SDK calls for X-Ray tracing
patch_all()

PROJECT_NAME = os.environ.get('PROJECT_NAME', 'monitoring-demo')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'dev')

@xray_recorder.capture('api_handler')
def handler(event, context):
    """
    API Gateway Lambda handler with X-Ray tracing
    """
    try:
        # Add custom metadata to X-Ray trace
        xray_recorder.put_metadata('project', PROJECT_NAME)
        xray_recorder.put_metadata('environment', ENVIRONMENT)
        xray_recorder.put_metadata('request_info', {
            'path': event.get('path'),
            'method': event.get('httpMethod'),
            'user_agent': event.get('headers', {}).get('User-Agent')
        })
        
        # Simulate some processing time
        processing_time = random.uniform(0.1, 0.5)
        time.sleep(processing_time)
        
        # Example API operations
        if event['path'] == '/users' and event['httpMethod'] == 'GET':
            return handle_get_users(event, context)
        else:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'Not Found'})
            }
    
    except Exception as e:
        logger.error(f"Error in API handler: {str(e)}")
        
        # Add error information to X-Ray trace
        xray_recorder.put_metadata('error', {
            'type': type(e).__name__,
            'message': str(e)
        })
        
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': 'Internal Server Error'})
        }

@xray_recorder.capture('handle_get_users')
def handle_get_users(event, context):
    """Handle GET /users endpoint"""
    
    # Simulate database call
    users = simulate_database_call()
    
    # Simulate external API call
    user_stats = simulate_external_api_call()
    
    # Combine results
    response_data = {
        'users': users,
        'stats': user_stats,
        'timestamp': int(time.time()),
        'environment': ENVIRONMENT
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response_data)
    }

@xray_recorder.capture('simulate_database_call')
def simulate_database_call():
    """Simulate database query with X-Ray tracing"""
    
    # Add database metadata to trace
    xray_recorder.put_metadata('database', {
        'query': 'SELECT * FROM users LIMIT 10',
        'connection_pool': 'primary'
    })
    
    # Simulate query time
    query_time = random.uniform(0.05, 0.2)
    time.sleep(query_time)
    
    # Return mock data
    users = [
        {'id': i, 'name': f'User {i}', 'email': f'user{i}@example.com'}
        for i in range(1, 11)
    ]
    
    # Add result metadata
    xray_recorder.put_metadata('database_result', {
        'rows_returned': len(users),
        'query_time_ms': query_time * 1000
    })
    
    return users

@xray_recorder.capture('simulate_external_api_call')
def simulate_external_api_call():
    """Simulate external API call with X-Ray tracing"""
    
    # Add external service metadata
    xray_recorder.put_metadata('external_service', {
        'service': 'user-analytics-api',
        'endpoint': '/analytics/user-stats'
    })
    
    # Simulate API call time
    api_time = random.uniform(0.1, 0.3)
    time.sleep(api_time)
    
    # Simulate occasional failures
    if random.random() < 0.05:  # 5% failure rate
        raise Exception("External API call failed")
    
    stats = {
        'total_users': 1000,
        'active_users': 750,
        'new_signups_today': 25
    }
    
    # Add result metadata
    xray_recorder.put_metadata('external_api_result', {
        'response_time_ms': api_time * 1000,
        'cache_hit': random.choice([True, False])
    })
    
    return stats
```

### 3. Application Performance Monitoring (APM) Integration

```hcl
# examples/03-apm-integration/main.tf

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
      Module      = "APM-Integration"
    }
  }
}

# CloudWatch Application Insights
resource "aws_applicationinsights_application" "main" {
  resource_group_name = aws_resourcegroups_group.main.name
  auto_config_enabled = true
  auto_create         = true

  log_patterns {
    pattern_name = "ErrorLogPattern"
    pattern      = "ERROR"
    rank         = 1
  }

  log_patterns {
    pattern_name = "WarnLogPattern"
    pattern      = "WARN"
    rank         = 2
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-app-insights"
  }
}

# Resource Group for Application Insights
resource "aws_resourcegroups_group" "main" {
  name = "${var.project_name}-${var.environment}-resources"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = [
        "AWS::EC2::Instance",
        "AWS::ElasticLoadBalancingV2::LoadBalancer",
        "AWS::RDS::DBCluster",
        "AWS::Lambda::Function",
        "AWS::ElastiCache::CacheCluster"
      ]
      TagFilters = [
        {
          Key    = "Project"
          Values = [var.project_name]
        },
        {
          Key    = "Environment"
          Values = [var.environment]
        }
      ]
    })
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-resource-group"
  }
}

# CloudWatch Synthetics Canary for user experience monitoring
resource "aws_synthetics_canary" "user_journey" {
  name                 = "${var.project_name}-${var.environment}-user-journey"
  artifact_s3_location = "s3://${aws_s3_bucket.canary_artifacts.bucket}"
  execution_role_arn   = aws_iam_role.synthetics_canary.arn
  handler              = "pageLoadBlueprint.handler"
  zip_file             = data.archive_file.canary_script.output_path
  runtime_version      = "syn-nodejs-puppeteer-3.8"

  schedule {
    expression = "rate(5 minutes)"
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb      = 960
    active_tracing    = true
  }

  success_retention_period = 2
  failure_retention_period = 14

  tags = {
    Name = "${var.project_name}-${var.environment}-user-journey-canary"
  }
}

# S3 bucket for Synthetics artifacts
resource "aws_s3_bucket" "canary_artifacts" {
  bucket = "${var.project_name}-${var.environment}-synthetics-artifacts-${random_string.bucket_suffix.result}"

  tags = {
    Name    = "Synthetics Canary Artifacts"
    Purpose = "CloudWatch Synthetics"
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_versioning" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "canary_artifacts" {
  bucket = aws_s3_bucket.canary_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Canary script archive
data "archive_file" "canary_script" {
  type        = "zip"
  output_path = "canary_script.zip"
  
  source {
    content  = file("${path.module}/synthetics/user_journey.js")
    filename = "nodejs/node_modules/pageLoadBlueprint.js"
  }
}

# IAM role for Synthetics Canary
resource "aws_iam_role" "synthetics_canary" {
  name = "${var.project_name}-${var.environment}-synthetics-canary"

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

resource "aws_iam_role_policy_attachment" "synthetics_canary" {
  role       = aws_iam_role.synthetics_canary.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsExecutionRolePolicy"
}

resource "aws_iam_role_policy" "synthetics_canary_s3" {
  name = "${var.project_name}-${var.environment}-synthetics-s3-policy"
  role = aws_iam_role.synthetics_canary.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.canary_artifacts.arn,
          "${aws_s3_bucket.canary_artifacts.arn}/*"
        ]
      }
    ]
  })
}

# CloudWatch alarms for Synthetics
resource "aws_cloudwatch_metric_alarm" "canary_success_rate" {
  alarm_name          = "${var.project_name}-${var.environment}-canary-success-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors synthetic transaction success rate"

  dimensions = {
    CanaryName = aws_synthetics_canary.user_journey.name
  }

  tags = {
    Name     = "${var.project_name}-${var.environment}-canary-success-alarm"
    Severity = "critical"
  }
}

# RUM (Real User Monitoring) App Monitor
resource "aws_rum_app_monitor" "main" {
  name   = "${var.project_name}-${var.environment}-rum"
  domain = var.application_domain

  app_monitor_configuration {
    allow_cookies        = true
    enable_xray         = true
    session_sample_rate = var.rum_sample_rate
    
    telemetries = ["errors", "performance", "http"]
    
    favorite_pages = var.favorite_pages
    
    excluded_pages = [
      "/admin/*",
      "/health",
      "/metrics"
    ]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rum"
  }
}

# Performance monitoring Lambda function
resource "aws_lambda_function" "performance_monitor" {
  filename         = "performance_monitor.zip"
  function_name    = "${var.project_name}-${var.environment}-performance-monitor"
  role            = aws_iam_role.performance_monitor.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  source_code_hash = data.archive_file.performance_monitor.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
      RUM_APP_ID   = aws_rum_app_monitor.main.app_monitor_id
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-performance-monitor"
  }
}

data "archive_file" "performance_monitor" {
  type        = "zip"
  output_path = "performance_monitor.zip"
  
  source {
    content = templatefile("${path.module}/lambda/performance_monitor.py", {
      project_name = var.project_name
      environment  = var.environment
    })
    filename = "index.py"
  }
}

# IAM role for performance monitoring Lambda
resource "aws_iam_role" "performance_monitor" {
  name = "${var.project_name}-${var.environment}-performance-monitor"

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

resource "aws_iam_role_policy" "performance_monitor" {
  name = "${var.project_name}-${var.environment}-performance-monitor-policy"
  role = aws_iam_role.performance_monitor.id

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
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "rum:GetAppMonitor",
          "rum:GetAppMonitorData"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule to trigger performance analysis
resource "aws_cloudwatch_event_rule" "performance_analysis" {
  name                = "${var.project_name}-${var.environment}-performance-analysis"
  description         = "Trigger performance analysis every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "performance_monitor_lambda" {
  rule      = aws_cloudwatch_event_rule.performance_analysis.name
  target_id = "PerformanceMonitorLambda"
  arn       = aws_lambda_function.performance_monitor.arn
}

resource "aws_lambda_permission" "allow_eventbridge_performance" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.performance_monitor.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.performance_analysis.arn
}

# Comprehensive APM Dashboard
resource "aws_cloudwatch_dashboard" "apm" {
  dashboard_name = "${var.project_name}-${var.environment}-apm"

  dashboard_body = jsonencode({
    widgets = [
      # Real User Monitoring
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/RUM", "PageViewCount", "application_name", aws_rum_app_monitor.main.name],
            [".", "SessionCount", ".", "."],
            [".", "ErrorCount", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Real User Monitoring"
        }
      },
      
      # Page Performance
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/RUM", "PageLoadTime", "application_name", aws_rum_app_monitor.main.name],
            [".", "DomContentLoadedTime", ".", "."],
            [".", "FirstContentfulPaintTime", ".", "."],
            [".", "LargestContentfulPaintTime", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Page Performance Metrics"
        }
      },
      
      # Synthetic Monitoring
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["CloudWatchSynthetics", "SuccessPercent", "CanaryName", aws_synthetics_canary.user_journey.name],
            [".", "Duration", ".", "."],
            [".", "Failed", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Synthetic Monitoring"
        }
      },
      
      # Application Insights
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount"],
            [".", "TargetResponseTime"],
            [".", "HTTPCode_Target_2XX_Count"],
            [".", "HTTPCode_Target_4XX_Count"],
            [".", "HTTPCode_Target_5XX_Count"]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Application Performance"
        }
      },
      
      # Custom Performance Metrics
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["Custom/${var.project_name}", "UserExperienceScore"],
            [".", "PerformanceScore"],
            [".", "AvailabilityScore"],
            [".", "ErrorBudgetBurn"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Custom Performance Metrics"
        }
      }
    ]
  })
}
```

## 🔗 Software Engineering Connections

### Observability Patterns

#### 1. Structured Logging
Infrastructure monitoring mirrors application logging best practices:

```python
# Application-level structured logging
import json
import logging
from datetime import datetime

class StructuredLogger:
    def __init__(self, service_name, environment):
        self.service_name = service_name
        self.environment = environment
        self.logger = logging.getLogger(service_name)
    
    def log_request(self, request_id, method, path, status_code, duration):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "service": self.service_name,
            "environment": self.environment,
            "request_id": request_id,
            "event_type": "http_request",
            "method": method,
            "path": path,
            "status_code": status_code,
            "duration_ms": duration,
            "level": "INFO"
        }
        self.logger.info(json.dumps(log_entry))
    
    def log_error(self, request_id, error_type, error_message, stack_trace):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "service": self.service_name,
            "environment": self.environment,
            "request_id": request_id,
            "event_type": "error",
            "error_type": error_type,
            "error_message": error_message,
            "stack_trace": stack_trace,
            "level": "ERROR"
        }
        self.logger.error(json.dumps(log_entry))

# Usage example
logger = StructuredLogger("user-service", "prod")
logger.log_request("req-123", "GET", "/users/456", 200, 150.5)
```

#### 2. Metrics as First-Class Citizens
```python
# Custom metrics collection class
import boto3
import time
from contextlib import contextmanager

class MetricsCollector:
    def __init__(self, namespace):
        self.namespace = namespace
        self.cloudwatch = boto3.client('cloudwatch')
        self.metrics_buffer = []
    
    @contextmanager
    def timer(self, metric_name, dimensions=None):
        """Context manager for timing operations"""
        start_time = time.time()
        try:
            yield
        finally:
            duration = (time.time() - start_time) * 1000
            self.put_metric(metric_name, duration, 'Milliseconds', dimensions)
    
    def put_metric(self, name, value, unit='Count', dimensions=None):
        """Add metric to buffer for batch publishing"""
        metric = {
            'MetricName': name,
            'Value': value,
            'Unit': unit,
            'Timestamp': time.time()
        }
        if dimensions:
            metric['Dimensions'] = [
                {'Name': k, 'Value': v} for k, v in dimensions.items()
            ]
        self.metrics_buffer.append(metric)
        
        # Flush buffer when it gets large
        if len(self.metrics_buffer) >= 20:
            self.flush_metrics()
    
    def flush_metrics(self):
        """Publish buffered metrics to CloudWatch"""
        if self.metrics_buffer:
            self.cloudwatch.put_metric_data(
                Namespace=self.namespace,
                MetricData=self.metrics_buffer
            )
            self.metrics_buffer.clear()

# Usage in application code
metrics = MetricsCollector('MyApp/Production')

# Time database operations
with metrics.timer('DatabaseQuery', {'Operation': 'SELECT'}):
    result = database.execute_query(sql)

# Custom business metrics
metrics.put_metric('UserSignup', 1, dimensions={'Source': 'web'})
metrics.put_metric('Revenue', 99.99, 'None', {'Product': 'premium'})
```

#### 3. Correlation IDs and Distributed Tracing
```python
# Request correlation for distributed systems
import uuid
import threading
from contextvars import ContextVar

# Context variable to store correlation ID across async operations
correlation_id: ContextVar[str] = ContextVar('correlation_id')

class RequestContext:
    def __init__(self, correlation_id=None):
        self.correlation_id = correlation_id or str(uuid.uuid4())
        self.start_time = time.time()
    
    def __enter__(self):
        correlation_id.set(self.correlation_id)
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        correlation_id.set(None)

def get_correlation_id():
    """Get current request correlation ID"""
    try:
        return correlation_id.get()
    except LookupError:
        return None

# Middleware to inject correlation ID
class CorrelationMiddleware:
    def __init__(self, app):
        self.app = app
    
    def __call__(self, environ, start_response):
        # Extract correlation ID from headers or generate new one
        corr_id = environ.get('HTTP_X_CORRELATION_ID', str(uuid.uuid4()))
        
        with RequestContext(corr_id):
            return self.app(environ, start_response)

# Usage in service calls
def make_service_call(url, data):
    headers = {}
    corr_id = get_correlation_id()
    if corr_id:
        headers['X-Correlation-ID'] = corr_id
    
    response = requests.post(url, json=data, headers=headers)
    return response
```

### Service Level Objectives (SLOs)

#### SLO Implementation Pattern
```python
# SLO monitoring and alerting
class SLOMonitor:
    def __init__(self, service_name, slo_targets):
        self.service_name = service_name
        self.slo_targets = slo_targets
        self.metrics = MetricsCollector(f'SLO/{service_name}')
    
    def record_request(self, success, response_time):
        """Record a request outcome for SLO calculation"""
        self.metrics.put_metric('RequestTotal', 1)
        
        if success:
            self.metrics.put_metric('RequestSuccess', 1)
        
        self.metrics.put_metric('ResponseTime', response_time, 'Milliseconds')
        
        # Check if request meets SLO thresholds
        fast_enough = response_time < self.slo_targets['response_time_ms']
        if success and fast_enough:
            self.metrics.put_metric('SLOCompliant', 1)
    
    def calculate_error_budget(self, time_window_hours=24):
        """Calculate remaining error budget"""
        # This would typically query CloudWatch for actual metrics
        availability_target = self.slo_targets['availability_percent']
        error_budget = 100 - availability_target
        
        # Query actual error rate from CloudWatch
        actual_error_rate = self.get_actual_error_rate(time_window_hours)
        
        remaining_budget = error_budget - actual_error_rate
        burn_rate = actual_error_rate / error_budget if error_budget > 0 else 0
        
        self.metrics.put_metric('ErrorBudgetRemaining', remaining_budget, 'Percent')
        self.metrics.put_metric('ErrorBudgetBurnRate', burn_rate, 'Percent')
        
        return {
            'remaining_budget': remaining_budget,
            'burn_rate': burn_rate,
            'time_to_exhaustion_hours': (remaining_budget / actual_error_rate * time_window_hours) if actual_error_rate > 0 else float('inf')
        }

# Usage in application
slo_monitor = SLOMonitor('user-service', {
    'availability_percent': 99.9,
    'response_time_ms': 500
})

# In request handler
start_time = time.time()
try:
    result = process_request()
    success = True
except Exception as e:
    success = False
    raise
finally:
    duration = (time.time() - start_time) * 1000
    slo_monitor.record_request(success, duration)
```

## 🎯 Hands-on Examples

### Exercise 1: Comprehensive Monitoring Setup

**Objective:** Deploy a complete monitoring infrastructure with metrics, logs, alarms, and dashboards

**Steps:**

1. **Deploy the Monitoring Infrastructure**
   ```bash
   cd examples/01-comprehensive-monitoring
   terraform init
   terraform plan -var="environment=dev"
   terraform apply -var="environment=dev"
   ```

2. **Configure SNS Subscriptions**
   ```bash
   # Confirm SNS subscriptions sent to your email
   # Check your email and confirm subscriptions
   
   # Test alert notifications
   aws sns publish \
     --topic-arn $(terraform output -raw critical_alerts_topic_arn) \
     --message "Test critical alert" \
     --subject "Test Alert"
   ```

3. **Generate Test Logs**
   ```bash
   # Send test log entries to CloudWatch
   aws logs put-log-events \
     --log-group-name $(terraform output -raw application_log_group) \
     --log-stream-name "test-stream" \
     --log-events timestamp=$(date +%s000),message='{"level":"ERROR","message":"Test error message","request_id":"req-123"}'
   ```

4. **View Dashboard and Metrics**
   ```bash
   # Get dashboard URL
   echo "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=$(terraform output -raw aws_region)#dashboards:name=$(terraform output -raw dashboard_name)"
   
   # Query custom metrics
   aws cloudwatch get-metric-statistics \
     --namespace "Custom/$(terraform output -raw project_name)" \
     --metric-name ApplicationErrorCount \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 300 \
     --statistics Sum
   ```

### Exercise 2: Distributed Tracing Implementation

**Objective:** Implement X-Ray tracing for a serverless API to understand request flow

**Steps:**

1. **Deploy X-Ray Tracing Infrastructure**
   ```bash
   cd examples/02-distributed-tracing
   terraform init
   terraform apply
   ```

2. **Test API with Tracing**
   ```bash
   # Get API Gateway URL
   API_URL=$(terraform output -raw api_gateway_url)
   
   # Make test requests to generate traces
   for i in {1..10}; do
     curl -H "X-Trace-Test: run-$i" "$API_URL/users"
     sleep 2
   done
   ```

3. **View X-Ray Traces**
   ```bash
   # Get recent traces
   aws xray get-traces \
     --time-range-type TimeRangeByStartTime \
     --start-time $(date -u -d '15 minutes ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S)
   
   # View X-Ray service map in AWS Console
   echo "X-Ray Console: https://console.aws.amazon.com/xray/home?region=$(terraform output -raw aws_region)"
   ```

4. **Analyze Trace Data**
   ```bash
   # Query trace analytics
   aws xray get-trace-summaries \
     --time-range-type TimeRangeByStartTime \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --query 'TraceSummaries[*].{Id:Id,Duration:Duration,ResponseTime:ResponseTime}'
   ```

### Exercise 3: Application Performance Monitoring

**Objective:** Set up comprehensive APM with RUM, synthetic monitoring, and custom metrics

**Steps:**

1. **Deploy APM Infrastructure**
   ```bash
   cd examples/03-apm-integration
   terraform init
   terraform plan -var="application_domain=your-app.com"
   terraform apply -var="application_domain=your-app.com"
   ```

2. **Configure Real User Monitoring**
   ```javascript
   // Add RUM script to your web application
   // Get RUM app monitor ID from Terraform output
   const rumAppId = "$(terraform output -raw rum_app_id)";
   
   // RUM initialization code (add to your web app)
   (function(n,i,v,r,s,c,u,x,z){x=window.AwsRumClient={q:[],n:n,i:i,v:v,r:r,c:c,u:u};window[n]=function(c,p){x.q.push({c:c,p:p});};z=document.createElement('script');z.async=true;z.src=s;document.head.appendChild(z);})(
     'awsrum',
     '1.0.0',
     rumAppId,
     '$(terraform output -raw aws_region)',
     'https://client.rum.us-east-1.amazonaws.com/1.0.2/cwr.js',
     {
       sessionSampleRate: 1.0,
       guestRoleArn: "$(terraform output -raw rum_guest_role_arn)",
       identityPoolId: "$(terraform output -raw rum_identity_pool_id)",
       endpoint: "https://dataplane.rum.$(terraform output -raw aws_region).amazonaws.com",
       telemetries: ["performance","errors","http"],
       allowCookies: true,
       enableXRay: true
     }
   );
   ```

3. **Test Synthetic Monitoring**
   ```bash
   # Check canary status
   aws synthetics get-canary \
     --name $(terraform output -raw canary_name)
   
   # Get canary run results
   aws synthetics get-canary-runs \
     --name $(terraform output -raw canary_name) \
     --max-results 5
   ```

4. **Monitor Performance Dashboard**
   ```bash
   # Access APM dashboard
   echo "APM Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$(terraform output -raw aws_region)#dashboards:name=$(terraform output -raw apm_dashboard_name)"
   
   # View Application Insights
   echo "Application Insights: https://console.aws.amazon.com/systems-manager/appinsights"
   ```

## ✅ Best Practices

### 1. Monitoring Strategy
- **Implement the three pillars** of observability: metrics, logs, and traces
- **Use structured logging** with consistent formats and correlation IDs
- **Set up monitoring from day one** rather than as an afterthought
- **Monitor the business impact** not just technical metrics
- **Establish clear SLAs and SLOs** that align with user expectations

### 2. Alerting Design
- **Alert on symptoms, not causes** to focus on user impact
- **Implement alert fatigue prevention** with proper thresholds and escalation
- **Use composite alarms** to reduce noise and focus on business impact
- **Establish clear escalation procedures** with different severity levels
- **Test your alerting system** regularly to ensure it works during incidents

### 3. Dashboard Creation
- **Design for your audience** with role-specific dashboards
- **Focus on actionable metrics** that lead to clear next steps
- **Use appropriate time ranges** for different types of analysis
- **Implement drill-down capabilities** from high-level to detailed views
- **Keep dashboards up-to-date** and remove obsolete metrics

### 4. Log Management
- **Implement structured logging** with machine-readable formats
- **Use appropriate log levels** and avoid verbose debugging in production
- **Set proper retention policies** based on compliance and cost requirements
- **Implement log aggregation** for multi-service applications
- **Use sampling for high-volume logs** to control costs while maintaining visibility

### 5. Performance Monitoring
- **Monitor real user experience** with RUM and synthetic monitoring
- **Track business metrics** alongside technical performance
- **Implement distributed tracing** for complex service interactions
- **Set up performance budgets** and monitor compliance
- **Use performance testing** to validate monitoring under load

## ⚠️ Common Pitfalls

### 1. Alert Fatigue
**Problem:** Too many alerts causing important ones to be ignored
**Solution:**
```python
# Implement intelligent alerting with context
class AlertManager:
    def __init__(self):
        self.alert_history = {}
        self.escalation_rules = {}
    
    def should_alert(self, metric_name, value, threshold):
        # Implement hysteresis to prevent flapping
        if metric_name in self.alert_history:
            last_alert = self.alert_history[metric_name]
            if last_alert['state'] == 'alerting':
                # Use lower threshold to clear alert (hysteresis)
                return value > threshold * 1.1
        
        return value > threshold
    
    def send_alert(self, severity, message, context):
        # Add context and runbook links
        enhanced_message = f"{message}\n\nContext: {context}\nRunbook: {self.get_runbook_link(severity)}"
        
        # Route based on severity
        if severity == 'critical':
            self.send_to_pager_duty(enhanced_message)
        elif severity == 'warning':
            self.send_to_slack(enhanced_message)
        else:
            self.send_to_email(enhanced_message)
```

### 2. Monitoring the Monitor
**Problem:** Monitoring systems failing without notice
**Solution:**
- Implement external monitoring for your monitoring infrastructure
- Use different technologies for monitoring the monitors
- Set up dead man's switches for critical monitoring components
- Regular testing of monitoring and alerting systems

### 3. High Cardinality Metrics
**Problem:** Metrics with too many dimensions causing cost and performance issues
**Solution:**
- Limit the number of dimensions per metric
- Use sampling for high-cardinality metrics
- Implement metric aggregation before publishing
- Regular cleanup of unused metric dimensions

### 4. Log Data Explosion
**Problem:** Exponential growth in log volume and costs
**Solution:**
- Implement log level filtering based on environment
- Use structured logging to enable better querying and filtering
- Set up automated log retention policies
- Sample verbose logs in production environments

### 5. Distributed Tracing Overhead
**Problem:** Performance impact from extensive tracing
**Solution:**
- Use sampling strategies to balance visibility and performance
- Implement adaptive sampling based on system load
- Monitor the monitoring overhead itself
- Use asynchronous trace publishing when possible

## 🔍 Troubleshooting

### Missing Metrics

**Problem:** Expected metrics not appearing in CloudWatch

**Diagnosis:**
```bash
# Check IAM permissions
aws sts get-caller-identity
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names cloudwatch:PutMetricData \
  --resource-arns "*"

# Verify metric namespace and names
aws cloudwatch list-metrics \
  --namespace "Custom/YourProject" \
  --max-records 50
```

**Solutions:**
1. Verify IAM permissions for CloudWatch PutMetricData
2. Check metric publishing code for errors
3. Validate metric namespace and dimension names
4. Review CloudWatch agent configuration

### High Alert Volume

**Problem:** Receiving too many alerts from monitoring system

**Diagnosis:**
```bash
# Analyze alarm states
aws cloudwatch describe-alarms \
  --state-value ALARM \
  --query 'MetricAlarms[*].{Name:AlarmName,Reason:StateReason}'

# Review alarm history
aws cloudwatch describe-alarm-history \
  --alarm-name "your-alarm-name" \
  --start-date $(date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S) \
  --max-records 50
```

**Solutions:**
1. Review alarm thresholds and evaluation periods
2. Implement composite alarms to reduce noise
3. Add proper hysteresis to prevent flapping
4. Use different notification channels for different severities

### Trace Sampling Issues

**Problem:** Important traces not being captured

**Diagnosis:**
```bash
# Check X-Ray trace statistics
aws xray get-trace-summaries \
  --time-range-type TimeRangeByStartTime \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --query 'TraceSummaries | length(@)'

# Review sampling rules
aws xray get-sampling-rules
```

**Solutions:**
1. Adjust X-Ray sampling rules for important services
2. Implement custom sampling logic for critical paths
3. Ensure X-Ray daemon is running and accessible
4. Check network connectivity to X-Ray service

## 📚 Further Reading

### Official Documentation
- [Amazon CloudWatch User Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
- [AWS X-Ray Developer Guide](https://docs.aws.amazon.com/xray/latest/devguide/)
- [CloudWatch Application Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-application-insights.html)
- [Amazon CloudWatch RUM](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-RUM.html)

### Observability Best Practices
- [Google SRE Book - Monitoring Distributed Systems](https://sre.google/sre-book/monitoring-distributed-systems/)
- [The Three Pillars of Observability](https://www.oreilly.com/library/view/distributed-systems-observability/9781492033431/)
- [Observability Engineering by Charity Majors](https://www.oreilly.com/library/view/observability-engineering/9781492076438/)

### Monitoring Patterns and Anti-patterns
- [Monitoring and Alerting Anti-Patterns](https://docs.google.com/document/d/199PqyG3UsyXlwieHaqbGiWVa8eMWi8zzAn0YfcApr8Q/)
- [Site Reliability Engineering Workbook](https://sre.google/workbook/table-of-contents/)
- [Service Level Objectives](https://sre.google/sre-book/service-level-objectives/)

### Tools and Technologies
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- [Prometheus Monitoring](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jaeger Tracing](https://www.jaegertracing.io/docs/)

### Community Resources
- [AWS Observability Best Practices Guide](https://aws-observability.github.io/observability-best-practices/)
- [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- [AWS CloudFormation and Terraform Templates](https://github.com/aws-samples/aws-monitoring-templates)

## 🎯 Next Steps

Congratulations! You've mastered comprehensive monitoring and observability engineering principles. You now understand how to:

- Design and implement multi-layer monitoring strategies
- Build observability pipelines that provide end-to-end visibility
- Create intelligent alerting systems with proper escalation
- Deploy application performance monitoring with real user insights
- Connect infrastructure monitoring to software engineering practices
- Troubleshoot complex performance and reliability issues

**Ready for the next challenge?** Proceed to [Module 08: Disaster Recovery](../08-disaster-recovery/) to learn how to design and implement comprehensive business continuity and disaster recovery strategies that ensure system resilience and data protection.

### Skills Gained
✅ Comprehensive monitoring strategy design and implementation  
✅ Observability pipeline creation with metrics, logs, and traces  
✅ Intelligent alerting system configuration and management  
✅ Application performance monitoring and real user monitoring  
✅ Distributed tracing and request correlation  
✅ Custom metrics collection and analysis  
✅ Dashboard design and visualization best practices  
✅ SLA/SLO definition and monitoring  
✅ Troubleshooting complex monitoring scenarios  

### Career Impact
These monitoring and observability skills are essential for senior infrastructure and reliability roles:
- **Senior DevOps Engineer**: Implementing enterprise monitoring and alerting systems
- **Site Reliability Engineer**: Defining and monitoring service level objectives
- **Platform Engineer**: Building observability platforms for development teams  
- **Cloud Architect**: Designing observable and maintainable distributed systems
- **Principal Engineer**: Leading observability strategy and implementation across organizations