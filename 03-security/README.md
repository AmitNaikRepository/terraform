# Module 03: Security → Defense in Depth Strategies

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Implement Defense in Depth**: Apply layered security principles to infrastructure design
- **Design IAM Policies**: Create least-privilege access controls using AWS IAM
- **Configure Encryption**: Implement encryption at rest and in transit for all data
- **Secure Network Architecture**: Design VPCs with proper segmentation and access controls
- **Automate Security Scanning**: Integrate security validation into infrastructure pipelines
- **Apply Security by Design**: Incorporate security considerations from the initial architecture phase

## 🎯 Overview

Security in infrastructure is not a single feature but a comprehensive strategy that permeates every layer of your architecture. Just as software applications require secure coding practices, input validation, and threat modeling, infrastructure requires a defense-in-depth approach that protects against various attack vectors.

This module explores how to implement security best practices in Terraform, drawing parallels to software security principles and demonstrating how proper security architecture protects both infrastructure and the applications it supports.

## 📖 Core Concepts

### Defense in Depth Strategy

Defense in depth is a cybersecurity strategy that uses multiple layers of security controls to protect resources. If one layer fails, other layers continue to provide protection.

#### Infrastructure Security Layers

```
┌─────────────────────────────────────────┐
│           Edge Security                 │  ← WAF, DDoS Protection, CDN
├─────────────────────────────────────────┤
│         Network Security                │  ← VPC, Subnets, NACLs, Security Groups
├─────────────────────────────────────────┤
│        Identity & Access                │  ← IAM Policies, Roles, MFA
├─────────────────────────────────────────┤
│         Host Security                   │  ← Instance Hardening, Patching
├─────────────────────────────────────────┤
│       Application Security              │  ← Code Security, Input Validation
├─────────────────────────────────────────┤
│          Data Security                  │  ← Encryption, Key Management
└─────────────────────────────────────────┘
```

### Software Security Parallels

| Software Security | Infrastructure Security | Purpose |
|------------------|------------------------|---------|
| Input Validation | VPC/Subnet Design | Validate and filter incoming requests |
| Authentication | IAM Roles/Policies | Verify identity and permissions |
| Authorization | Resource-based Policies | Control access to resources |
| Secure Defaults | Security Groups | Deny by default, allow explicitly |
| Encryption | KMS/TLS | Protect data confidentiality |
| Logging & Monitoring | CloudTrail/CloudWatch | Detect and respond to threats |

### Security Design Principles

#### 1. Principle of Least Privilege
**Software Development:**
```typescript
// Grant minimum necessary permissions
class UserService {
  @RequireRole('USER_READ')
  getUser(id: string): User { ... }
  
  @RequireRole('USER_ADMIN')
  deleteUser(id: string): void { ... }
}
```

**Infrastructure Equivalent:**
```hcl
# IAM policy with minimal permissions
resource "aws_iam_policy" "s3_read_only" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::specific-bucket/*"]
    }]
  })
}
```

#### 2. Security by Design
**Software Development:**
```typescript
// Security considerations from the start
class PaymentProcessor {
  constructor(
    private encryption: EncryptionService,
    private audit: AuditLogger
  ) {}
  
  processPayment(card: string): void {
    const encrypted = this.encryption.encrypt(card);
    this.audit.log('payment_processed');
    // Process with encrypted data
  }
}
```

**Infrastructure Equivalent:**
```hcl
# Security built into the architecture
module "secure_application" {
  source = "./modules/secure-web-app"
  
  # Security requirements as first-class inputs
  encryption_enabled    = true
  audit_logging_enabled = true
  vpc_flow_logs_enabled = true
  security_scanning     = true
}
```

## 🛠️ Terraform Implementation

### 1. Network Security Foundation

Let's start with a secure VPC design implementing network segmentation:

```hcl
# examples/01-network-security/main.tf

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

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # Security-focused network design
  vpc_cidr = "10.0.0.0/16"
  
  # Network segmentation for security isolation
  network_config = {
    # Public subnets for load balancers and NAT gateways only
    public_subnets = [
      "10.0.1.0/24",  # AZ-a Public
      "10.0.2.0/24",  # AZ-b Public
      "10.0.3.0/24"   # AZ-c Public
    ]
    
    # Private subnets for application servers
    private_subnets = [
      "10.0.11.0/24", # AZ-a Private
      "10.0.12.0/24", # AZ-b Private
      "10.0.13.0/24"  # AZ-c Private
    ]
    
    # Database subnets with additional isolation
    database_subnets = [
      "10.0.21.0/24", # AZ-a Database
      "10.0.22.0/24", # AZ-b Database
      "10.0.23.0/24"  # AZ-c Database
    ]
  }
  
  # Security tagging for compliance
  security_tags = merge(var.default_tags, {
    SecurityLevel = "high"
    Compliance    = "required"
    DataClass     = "sensitive"
  })
}

# VPC with security-focused configuration
resource "aws_vpc" "secure" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Security: Enable VPC Flow Logs
  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-secure-vpc"
    Type = "vpc"
  })
}

# VPC Flow Logs for security monitoring
resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.secure.id

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-logs"
    Type = "security-monitoring"
  })
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name              = "/aws/vpc/flow-logs/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flow-log-group"
    Type = "logging"
  })
}

# IAM role for VPC Flow Logs
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

  tags = local.security_tags
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
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Internet Gateway (public access point)
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.secure.id

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
    Type = "gateway"
  })
}

# Public Subnets (DMZ - only for load balancers)
resource "aws_subnet" "public" {
  count = length(local.network_config.public_subnets)

  vpc_id                  = aws_vpc.secure.id
  cidr_block              = local.network_config.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false  # Security: No automatic public IPs

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    Tier = "dmz"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Private Subnets (Application Tier)
resource "aws_subnet" "private" {
  count = length(local.network_config.private_subnets)

  vpc_id            = aws_vpc.secure.id
  cidr_block        = local.network_config.private_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    Tier = "application"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Database Subnets (Data Tier)
resource "aws_subnet" "database" {
  count = length(local.network_config.database_subnets)

  vpc_id            = aws_vpc.secure.id
  cidr_block        = local.network_config.database_subnets[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-database-subnet-${count.index + 1}"
    Type = "database-subnet"
    Tier = "data"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# NAT Gateways for secure outbound access
resource "aws_eip" "nat" {
  count = length(aws_subnet.public)

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

resource "aws_nat_gateway" "main" {
  count = length(aws_subnet.public)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables with security-focused routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.secure.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

resource "aws_route_table" "private" {
  count = length(aws_subnet.private)

  vpc_id = aws_vpc.secure.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Database route table (no internet access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.secure.id

  # No default route - database tier is isolated

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-database-rt"
    Type = "route-table"
    Tier = "database"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count = length(aws_subnet.database)

  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# Network ACLs for additional security layer
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.secure.id
  subnet_ids = aws_subnet.private[*].id

  # Allow inbound traffic from public subnets (load balancers)
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.0.0/8"
    from_port  = 443
    to_port    = 443
  }

  # Allow ephemeral ports for return traffic
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # Allow all outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-private-nacl"
    Type = "network-acl"
    Tier = "private"
  })
}

resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.secure.id
  subnet_ids = aws_subnet.database[*].id

  # Allow inbound traffic only from private subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.11.0/24"  # Private subnet 1
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.12.0/24"  # Private subnet 2
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "10.0.13.0/24"  # Private subnet 3
    from_port  = 3306
    to_port    = 3306
  }

  # Allow outbound traffic to private subnets
  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.10.0/22"  # All private subnets
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.security_tags, {
    Name = "${var.project_name}-${var.environment}-database-nacl"
    Type = "network-acl"
    Tier = "database"
  })
}
```

### 2. IAM Security with Least Privilege

```hcl
# examples/02-iam-security/main.tf

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

  tags = merge(var.default_tags, {
    Name        = "${var.project_name}-${var.environment}-app-instance-role"
    Component   = "iam"
    SecurityLevel = "application"
  })
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "application" {
  name = "${var.project_name}-${var.environment}-app-instance-profile"
  role = aws_iam_role.application_instance.name

  tags = var.default_tags
}

# S3 Access Policy (Specific Bucket Only)
resource "aws_iam_policy" "s3_app_access" {
  name        = "${var.project_name}-${var.environment}-s3-app-access"
  description = "Minimal S3 access for application"

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
          aws_s3_bucket.application_data.arn
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
        Sid    = "ReadWriteApplicationData"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.application_data.arn}/${var.environment}/*",
          "${aws_s3_bucket.application_data.arn}/shared/*"
        ]
      }
    ]
  })

  tags = merge(var.default_tags, {
    Component = "iam"
    Purpose   = "s3-access"
  })
}

# CloudWatch Logging Policy
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.project_name}-${var.environment}-cloudwatch-logs"
  description = "Allow writing to specific CloudWatch log group"

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

  tags = merge(var.default_tags, {
    Component = "iam"
    Purpose   = "logging"
  })
}

# Secrets Manager Access Policy
resource "aws_iam_policy" "secrets_access" {
  name        = "${var.project_name}-${var.environment}-secrets-access"
  description = "Access to specific application secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.database_credentials.arn,
          aws_secretsmanager_secret.api_keys.arn
        ]
        Condition = {
          StringEquals = {
            "secretsmanager:VersionStage" = "AWSCURRENT"
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Component = "iam"
    Purpose   = "secrets-access"
  })
}

# Attach policies to instance role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.application_instance.name
  policy_arn = aws_iam_policy.s3_app_access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.application_instance.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

resource "aws_iam_role_policy_attachment" "secrets_access" {
  role       = aws_iam_role.application_instance.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# Deployment Role for CI/CD
resource "aws_iam_role" "deployment" {
  name = "${var.project_name}-${var.environment}-deployment-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_deployment_account_arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.deployment_external_id
          }
          IpAddress = {
            "aws:SourceIp" = var.allowed_deployment_ips
          }
        }
      }
    ]
  })

  tags = merge(var.default_tags, {
    Component = "iam"
    Purpose   = "deployment"
  })
}

# Deployment Policy with Time-Based Access
resource "aws_iam_policy" "deployment" {
  name        = "${var.project_name}-${var.environment}-deployment-policy"
  description = "Deployment permissions with time restrictions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2Deployment"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:CreateTags",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
          DateGreaterThan = {
            "aws:CurrentTime" = "2024-01-01T00:00:00Z"
          }
          DateLessThan = {
            "aws:CurrentTime" = "2025-12-31T23:59:59Z"
          }
        }
      },
      {
        Sid    = "S3Deployment"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.application_data.arn}/deployments/*"
        ]
      }
    ]
  })

  tags = merge(var.default_tags, {
    Component = "iam"
    Purpose   = "deployment"
  })
}

resource "aws_iam_role_policy_attachment" "deployment" {
  role       = aws_iam_role.deployment.name
  policy_arn = aws_iam_policy.deployment.arn
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(var.default_tags, {
    Component = "logging"
  })
}

# Application Data Bucket
resource "aws_s3_bucket" "application_data" {
  bucket = "${var.project_name}-${var.environment}-app-data-${random_string.bucket_suffix.result}"

  tags = merge(var.default_tags, {
    Component = "storage"
    DataClass = "application"
  })
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket Security Configuration
resource "aws_s3_bucket_versioning" "application_data" {
  bucket = aws_s3_bucket.application_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "application_data" {
  bucket = aws_s3_bucket.application_data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_encryption.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "application_data" {
  bucket = aws_s3_bucket.application_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3_encryption" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM root permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow S3 service"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.default_tags, {
    Component = "encryption"
    Purpose   = "s3"
  })
}

resource "aws_kms_alias" "s3_encryption" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3_encryption.key_id
}

# Secrets Manager
resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "${var.project_name}-${var.environment}-db-credentials"
  description             = "Database credentials for ${var.project_name}"
  recovery_window_in_days = 7

  kms_key_id = aws_kms_key.secrets_encryption.arn

  tags = merge(var.default_tags, {
    Component = "secrets"
    Purpose   = "database"
  })
}

resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${var.project_name}-${var.environment}-api-keys"
  description             = "API keys for ${var.project_name}"
  recovery_window_in_days = 7

  kms_key_id = aws_kms_key.secrets_encryption.arn

  tags = merge(var.default_tags, {
    Component = "secrets"
    Purpose   = "api"
  })
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets_encryption" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.default_tags, {
    Component = "encryption"
    Purpose   = "secrets"
  })
}

resource "aws_kms_alias" "secrets_encryption" {
  name          = "alias/${var.project_name}-${var.environment}-secrets"
  target_key_id = aws_kms_key.secrets_encryption.key_id
}

data "aws_caller_identity" "current" {}
```

### 3. Security Groups with Defense in Depth

```hcl
# examples/03-security-groups/main.tf

# Web Tier Security Group (DMZ)
resource "aws_security_group" "web_tier" {
  name        = "${var.project_name}-${var.environment}-web-tier-sg"
  description = "Security group for web tier (load balancers)"
  vpc_id      = var.vpc_id

  tags = merge(var.default_tags, {
    Name      = "${var.project_name}-${var.environment}-web-tier-sg"
    Component = "security"
    Tier      = "web"
  })
}

# Web Tier Rules - Only allow necessary traffic
resource "aws_security_group_rule" "web_tier_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.web_tier.id
  description       = "HTTP traffic from allowed CIDRs"
}

resource "aws_security_group_rule" "web_tier_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.web_tier.id
  description       = "HTTPS traffic from allowed CIDRs"
}

# Application Tier Security Group
resource "aws_security_group" "app_tier" {
  name        = "${var.project_name}-${var.environment}-app-tier-sg"
  description = "Security group for application tier"
  vpc_id      = var.vpc_id

  tags = merge(var.default_tags, {
    Name      = "${var.project_name}-${var.environment}-app-tier-sg"
    Component = "security"
    Tier      = "application"
  })
}

# Application Tier Rules - Only from web tier
resource "aws_security_group_rule" "app_tier_http_from_web" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_tier.id
  security_group_id        = aws_security_group.app_tier.id
  description              = "Application traffic from web tier"
}

resource "aws_security_group_rule" "app_tier_ssh_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.app_tier.id
  description              = "SSH access from bastion host"
}

# Database Tier Security Group
resource "aws_security_group" "db_tier" {
  name        = "${var.project_name}-${var.environment}-db-tier-sg"
  description = "Security group for database tier"
  vpc_id      = var.vpc_id

  tags = merge(var.default_tags, {
    Name      = "${var.project_name}-${var.environment}-db-tier-sg"
    Component = "security"
    Tier      = "database"
  })
}

# Database Tier Rules - Only from application tier
resource "aws_security_group_rule" "db_tier_mysql_from_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_tier.id
  security_group_id        = aws_security_group.db_tier.id
  description              = "MySQL traffic from application tier"
}

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-${var.environment}-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = var.vpc_id

  tags = merge(var.default_tags, {
    Name      = "${var.project_name}-${var.environment}-bastion-sg"
    Component = "security"
    Purpose   = "bastion"
  })
}

# Bastion Rules - Restricted SSH access
resource "aws_security_group_rule" "bastion_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  security_group_id = aws_security_group.bastion.id
  description       = "SSH access from admin networks"
}

# All outbound traffic for all security groups
resource "aws_security_group_rule" "web_tier_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web_tier.id
  description       = "All outbound traffic"
}

resource "aws_security_group_rule" "app_tier_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_tier.id
  description       = "All outbound traffic"
}

resource "aws_security_group_rule" "db_tier_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_tier.id
  description       = "All outbound traffic"
}

resource "aws_security_group_rule" "bastion_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion.id
  description       = "All outbound traffic"
}

# WAF for additional web application protection
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

    override_action {
      none {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }

    action {
      block {}
    }
  }

  # Known bad inputs rule
  rule {
    name     = "KnownBadInputsRule"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRule"
      sampled_requests_enabled   = true
    }

    action {
      block {}
    }
  }

  # SQL injection rule
  rule {
    name     = "SQLInjectionRule"
    priority = 3

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
      metric_name                = "SQLInjectionRule"
      sampled_requests_enabled   = true
    }

    action {
      block {}
    }
  }

  tags = merge(var.default_tags, {
    Component = "security"
    Purpose   = "waf"
  })

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-web-acl"
    sampled_requests_enabled   = true
  }
}
```

## 🔗 Software Engineering Connections

### Security Patterns in Infrastructure

#### 1. Input Validation Pattern
**Software Development:**
```typescript
function processUserInput(input: string): string {
  // Validate input
  if (!isValidInput(input)) {
    throw new Error('Invalid input');
  }
  
  // Sanitize input
  return sanitizeInput(input);
}
```

**Infrastructure Equivalent:**
```hcl
# Network input validation
resource "aws_security_group_rule" "web_ingress" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.allowed_cidr_blocks  # Validate source IPs
  
  # Additional validation through WAF
}

# WAF input validation
resource "aws_wafv2_web_acl" "input_validation" {
  rule {
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
  }
}
```

#### 2. Authentication and Authorization Pattern
**Software Development:**
```typescript
@Controller('/api/users')
class UserController {
  @RequireAuth()  // Authentication
  @RequireRole('ADMIN')  // Authorization
  async deleteUser(id: string) {
    // Business logic
  }
}
```

**Infrastructure Equivalent:**
```hcl
# IAM role-based access control
resource "aws_iam_policy" "user_management" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["iam:DeleteUser"]
      Resource = "*"
      Condition = {
        StringEquals = {
          "aws:PrincipalTag/Department" = "Security"
        }
      }
    }]
  })
}
```

#### 3. Secure Communication Pattern
**Software Development:**
```typescript
// Force HTTPS communication
app.use((req, res, next) => {
  if (!req.secure && req.get('x-forwarded-proto') !== 'https') {
    return res.redirect(`https://${req.get('host')}${req.url}`);
  }
  next();
});
```

**Infrastructure Equivalent:**
```hcl
# Force HTTPS at load balancer
resource "aws_lb_listener" "https_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# TLS configuration
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.main.arn
}
```

### Security Design Principles

#### 1. Fail Secure (Secure by Default)
**Software Development:**
```typescript
// Default to restrictive permissions
class UserPermissions {
  private permissions: Set<string> = new Set();  // Empty by default
  
  grantPermission(permission: string) {
    this.permissions.add(permission);
  }
}
```

**Infrastructure Equivalent:**
```hcl
# Security groups deny by default
resource "aws_security_group" "app" {
  name = "app-sg"
  # No ingress rules = deny all by default
  
  # Explicitly allow only what's needed
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]  # Only internal traffic
  }
}
```

#### 2. Defense in Depth
**Software Development:**
```typescript
// Multiple security layers
class PaymentService {
  @RateLimit(100)  // Layer 1: Rate limiting
  @ValidateInput() // Layer 2: Input validation
  @RequireAuth()   // Layer 3: Authentication
  @Encrypt()       // Layer 4: Encryption
  processPayment(data: PaymentData) {
    // Business logic
  }
}
```

**Infrastructure Equivalent:**
```hcl
# Multiple security layers
module "secure_application" {
  # Layer 1: Network isolation
  vpc_id     = module.secure_vpc.vpc_id
  subnet_ids = module.secure_vpc.private_subnet_ids
  
  # Layer 2: Security groups
  security_group_ids = [aws_security_group.app.id]
  
  # Layer 3: WAF protection
  waf_acl_arn = aws_wafv2_web_acl.main.arn
  
  # Layer 4: IAM permissions
  iam_role = aws_iam_role.least_privilege.arn
  
  # Layer 5: Encryption
  kms_key_id = aws_kms_key.app_encryption.arn
}
```

## 🎯 Hands-on Examples

### Exercise 1: Implement Network Segmentation

**Objective:** Create a three-tier architecture with proper network isolation

**Requirements:**
- Public subnet for load balancers only
- Private subnet for application servers
- Database subnet with no internet access
- Proper security group rules between tiers

**Steps:**
1. Design VPC with appropriate CIDR ranges
2. Create subnets with proper routing
3. Implement security groups with least privilege
4. Add network ACLs for additional protection
5. Test connectivity between tiers

### Exercise 2: Configure IAM with Least Privilege

**Objective:** Create IAM roles and policies following least privilege principle

**Requirements:**
- Application instance role with minimal S3 access
- Deployment role with time-based restrictions
- Secrets Manager access for application credentials
- CloudWatch logging permissions

**Steps:**
1. Define specific resource ARNs for policies
2. Add condition statements for additional security
3. Use separate policies for different access types
4. Test permissions with AWS Policy Simulator
5. Monitor access patterns with CloudTrail

### Exercise 3: Implement Encryption at Rest and in Transit

**Objective:** Encrypt all data using AWS KMS and enforce TLS

**Requirements:**
- KMS keys for different data types
- S3 bucket encryption with customer-managed keys
- RDS encryption enabled
- Secrets Manager encryption
- Force HTTPS for all web traffic

**Steps:**
1. Create KMS keys with proper policies
2. Configure S3 bucket encryption
3. Enable RDS encryption
4. Set up Secrets Manager with KMS
5. Configure load balancer SSL/TLS

## ✅ Best Practices

### 1. Network Security

#### Micro-Segmentation
```hcl
# Separate subnets for different application tiers
resource "aws_subnet" "web" {
  cidr_block = "10.0.1.0/24"
  # Web tier - public access through load balancer only
}

resource "aws_subnet" "app" {
  cidr_block = "10.0.11.0/24"
  # Application tier - private with NAT gateway access
}

resource "aws_subnet" "data" {
  cidr_block = "10.0.21.0/24"
  # Data tier - no internet access
}
```

#### Security Group Best Practices
```hcl
# Principle of least privilege
resource "aws_security_group_rule" "specific_access" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app_tier.id  # Not CIDR blocks
  security_group_id        = aws_security_group.db_tier.id
}
```

### 2. Identity and Access Management

#### Role-Based Access Control
```hcl
# Separate roles for different functions
resource "aws_iam_role" "application" {
  # Application runtime permissions
}

resource "aws_iam_role" "deployment" {
  # Deployment permissions with conditions
}

resource "aws_iam_role" "monitoring" {
  # Read-only monitoring permissions
}
```

#### Policy Conditions
```hcl
resource "aws_iam_policy" "restricted_access" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::mybucket/*"]
      Condition = {
        StringEquals = {
          "aws:RequestedRegion" = "us-west-2"
        }
        DateGreaterThan = {
          "aws:CurrentTime" = "2024-01-01T00:00:00Z"
        }
        IpAddress = {
          "aws:SourceIp" = ["203.0.113.0/24"]
        }
      }
    }]
  })
}
```

### 3. Encryption Strategy

#### Key Management
```hcl
# Separate keys for different data types
resource "aws_kms_key" "application_data" {
  description = "Application data encryption"
  enable_key_rotation = true
}

resource "aws_kms_key" "secrets" {
  description = "Secrets encryption"
  enable_key_rotation = true
}

resource "aws_kms_key" "logs" {
  description = "Log encryption"
  enable_key_rotation = true
}
```

#### Encryption in Transit
```hcl
# Force TLS for all connections
resource "aws_lb_listener" "https_only" {
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-2017-01"  # Strong TLS policy
  
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Secure connections only"
      status_code  = "403"
    }
  }
}
```

### 4. Monitoring and Auditing

#### Comprehensive Logging
```hcl
# Enable all security-relevant logs
resource "aws_cloudtrail" "security_audit" {
  name           = "security-audit-trail"
  s3_bucket_name = aws_s3_bucket.audit_logs.bucket
  
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::sensitive-bucket/*"]
    }
  }
}

resource "aws_flow_log" "vpc_flow_log" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
```

## ⚠️ Common Pitfalls

### 1. Overly Permissive Policies
**Problem:** Using wildcard permissions or overly broad resource access

**Bad Example:**
```hcl
resource "aws_iam_policy" "too_permissive" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = "*"              # Bad: All actions
      Resource = "*"            # Bad: All resources
    }]
  })
}
```

**Good Example:**
```hcl
resource "aws_iam_policy" "least_privilege" {
  policy = jsonencode({
    Statement = [{
      Effect = "Allow"
      Action = ["s3:GetObject"]                    # Specific action
      Resource = ["arn:aws:s3:::specific-bucket/*"] # Specific resource
    }]
  })
}
```

### 2. Security Group Misconfigurations
**Problem:** Allowing unrestricted access or using 0.0.0.0/0 unnecessarily

**Solution:**
- Use security group references instead of CIDR blocks
- Implement principle of least privilege
- Regular security group audits

### 3. Unencrypted Data
**Problem:** Storing sensitive data without encryption

**Solution:**
- Enable encryption by default for all storage services
- Use customer-managed KMS keys for sensitive data
- Implement encryption in transit for all communications

### 4. Missing Security Monitoring
**Problem:** Not implementing comprehensive logging and monitoring

**Solution:**
- Enable CloudTrail for all regions
- Configure VPC Flow Logs
- Set up security-focused CloudWatch alarms
- Implement automated security scanning

## 🔍 Troubleshooting

### IAM Permission Issues

**Problem:** Access denied errors despite seemingly correct policies

**Diagnosis:**
```bash
# Use AWS Policy Simulator
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/MyRole \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::mybucket/mykey
```

**Common Solutions:**
1. Check for explicit deny statements
2. Verify resource ARN format
3. Review condition statements
4. Check trust relationships for roles

### Security Group Connectivity Issues

**Problem:** Cannot connect between resources despite security group rules

**Diagnosis:**
```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-12345678

# Check network ACLs
aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values=subnet-12345678"
```

**Common Solutions:**
1. Verify security group rule directions (ingress/egress)
2. Check network ACL rules
3. Ensure proper subnet routing
4. Verify protocol and port configurations

### KMS Key Access Issues

**Problem:** Cannot access encrypted resources

**Diagnosis:**
```bash
# Test KMS key access
aws kms describe-key --key-id alias/my-key

# Check key policy
aws kms get-key-policy --key-id alias/my-key --policy-name default
```

**Solutions:**
1. Verify key policy permissions
2. Check IAM user/role permissions
3. Ensure proper key ARN references
4. Review encryption context requirements

## 📚 Further Reading

### Official Documentation
- [AWS Security Best Practices](https://docs.aws.amazon.com/security/)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [VPC Security](https://docs.aws.amazon.com/vpc/latest/userguide/security.html)

### Security Frameworks
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Controls](https://www.cisecurity.org/controls/)

### Advanced Security Topics
- [AWS Config for Compliance](https://docs.aws.amazon.com/config/)
- [AWS Systems Manager for Patch Management](https://docs.aws.amazon.com/systems-manager/)
- [AWS Inspector for Vulnerability Assessment](https://docs.aws.amazon.com/inspector/)

## 🎯 Next Steps

Congratulations! You've mastered implementing comprehensive security measures using defense-in-depth strategies. You now understand how to:

- Design secure network architectures with proper segmentation
- Implement IAM policies following least privilege principles
- Configure encryption for data at rest and in transit
- Set up comprehensive security monitoring and auditing

**Ready for the next challenge?** Proceed to [Module 04: Cost Optimization](../04-cost-optimization/) to learn how to optimize infrastructure costs while maintaining security and performance.

### Skills Gained
✅ Defense-in-depth security architecture  
✅ IAM policy design and implementation  
✅ Network security and segmentation  
✅ Encryption strategy and key management  
✅ Security monitoring and compliance  
✅ Automated security validation  

### Career Impact
These security skills are essential for any infrastructure role and directly translate to:
- **Security Engineer**: Implementing infrastructure security controls
- **Cloud Security Architect**: Designing secure cloud architectures
- **DevSecOps Engineer**: Integrating security into CI/CD pipelines
- **Compliance Manager**: Ensuring regulatory compliance through infrastructure