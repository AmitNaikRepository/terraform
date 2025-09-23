# Module 02: Project Structure → Software Architecture Principles

## 📚 Learning Objectives

By the end of this module, you will be able to:

- **Design Modular Infrastructure**: Create reusable, composable Terraform modules following clean architecture principles
- **Implement Separation of Concerns**: Organize code with clear boundaries between different infrastructure layers
- **Apply DRY Principles**: Eliminate code duplication through effective module design and composition
- **Establish Naming Conventions**: Implement consistent naming strategies across resources and modules
- **Create Abstraction Layers**: Build higher-level modules that hide complexity and provide simple interfaces
- **Apply Software Architecture Patterns**: Use established patterns like layered architecture and dependency injection in infrastructure code

## 🎯 Overview

Just as software applications benefit from well-organized architecture, Terraform projects require thoughtful structure to remain maintainable, scalable, and comprehensible. This module explores how software engineering principles like modularity, separation of concerns, and clean architecture apply to infrastructure as code.

We'll examine how to structure Terraform projects from simple scripts to enterprise-scale infrastructures, drawing parallels to software architecture patterns and demonstrating how good organizational practices enable team collaboration and long-term maintainability.

## 📖 Core Concepts

### Software Architecture Principles in Infrastructure

#### 1. Separation of Concerns
**Software Development:**
```
├── controllers/     # Handle HTTP requests
├── services/        # Business logic
├── repositories/    # Data access
└── models/          # Data structures
```

**Terraform Equivalent:**
```
├── networking/      # VPC, subnets, routing
├── compute/         # EC2, ASG, load balancers
├── data/           # RDS, DynamoDB, S3
└── security/       # IAM, security groups, KMS
```

#### 2. Dependency Inversion
**Software Development:**
```typescript
// High-level module depends on abstraction
class OrderService {
  constructor(private paymentGateway: PaymentGateway) {}
}
```

**Terraform Equivalent:**
```hcl
# High-level module depends on input variables
module "application" {
  source = "./modules/application"
  
  vpc_id           = var.vpc_id           # Abstraction
  database_url     = var.database_url     # Abstraction
  security_groups  = var.security_groups  # Abstraction
}
```

#### 3. Single Responsibility Principle
**Software Development:**
```typescript
class UserValidator {  // Only validates users
  validate(user: User): boolean { ... }
}

class UserRepository { // Only handles user data
  save(user: User): void { ... }
}
```

**Terraform Equivalent:**
```hcl
# VPC module only handles networking
module "vpc" {
  source = "./modules/vpc"
  # Only VPC-related configuration
}

# Database module only handles data layer
module "database" {
  source = "./modules/database"
  # Only database-related configuration
}
```

### Terraform Module Design Patterns

#### 1. Layered Architecture Pattern
```
├── foundation/      # Core infrastructure (VPC, IAM)
├── platform/        # Shared services (monitoring, logging)
├── application/     # Application-specific resources
└── edge/           # CDN, WAF, DNS
```

#### 2. Composition Pattern
```hcl
# Compose higher-level functionality from smaller modules
module "web_application" {
  source = "./modules/web-application"
  
  # Composed of multiple concerns
  networking_config = module.vpc.config
  security_config   = module.security.config
  database_config   = module.database.config
}
```

#### 3. Factory Pattern
```hcl
# Environment factory that creates consistent environments
module "environment" {
  source = "./modules/environment-factory"
  
  environment_name = "production"
  # Factory creates all necessary resources
}
```

## 🛠️ Terraform Implementation

### 1. Basic Project Structure

Let's start with a simple but well-organized project structure:

```
examples/01-basic-structure/
├── main.tf              # Root configuration
├── variables.tf         # Input variables
├── outputs.tf          # Output values
├── terraform.tfvars    # Variable values
├── versions.tf         # Provider requirements
└── README.md           # Documentation
```

```hcl
# examples/01-basic-structure/versions.tf

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}
```

```hcl
# examples/01-basic-structure/main.tf

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
  # Computed values and data transformation
  az_count = min(length(data.aws_availability_zones.available.names), 3)
  
  # Subnet CIDR calculation
  subnet_cidrs = [
    for i in range(local.az_count) : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  # Common tags merged with resource-specific tags
  common_tags = merge(var.default_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  })
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
    Type = "networking"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-igw"
    Type = "networking"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = local.az_count

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    AZ   = data.aws_availability_zones.available.names[count.index]
  })
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
    Type = "route-table"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for Web Servers
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  description = "Security group for web servers"
  vpc_id      = aws_vpc.main.id

  # HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (restricted to VPC)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # All outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-web-sg"
    Type = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}
```

```hcl
# examples/01-basic-structure/variables.tf

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region name."
  }
}

variable "project_name" {
  description = "Name of the project (used in resource naming)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform = "true"
    Owner     = "DevOps Team"
  }
}
```

```hcl
# examples/01-basic-structure/outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = aws_subnet.public[*].availability_zone
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "web_security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}

output "route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

# Output for use by other modules
output "networking_config" {
  description = "Networking configuration for use by other modules"
  value = {
    vpc_id              = aws_vpc.main.id
    public_subnet_ids   = aws_subnet.public[*].id
    security_group_ids  = [aws_security_group.web.id]
    availability_zones  = aws_subnet.public[*].availability_zone
  }
}
```

### 2. Modular Architecture

Now let's implement a modular structure following software architecture principles:

```
examples/02-modular-structure/
├── main.tf                    # Root module composition
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs
├── terraform.tfvars          # Environment-specific values
└── modules/                   # Reusable modules
    ├── vpc/                   # VPC module
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    ├── security/              # Security module
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    └── compute/               # Compute module
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

```hcl
# examples/02-modular-structure/modules/vpc/main.tf

locals {
  # Calculate subnet CIDRs automatically
  public_subnet_cidrs = [
    for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i)
  ]
  
  private_subnet_cidrs = [
    for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 10)
  ]
  
  # Common tags for all VPC resources
  vpc_tags = merge(var.tags, {
    Component = "networking"
    Module    = "vpc"
  })
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-vpc"
    Type = "vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-igw"
    Type = "internet-gateway"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-public-subnet-${count.index + 1}"
    Type = "public-subnet"
    AZ   = var.availability_zones[count.index]
    Tier = "public"
  })
}

# Private Subnets (if enabled)
resource "aws_subnet" "private" {
  count = var.enable_private_subnets ? length(var.availability_zones) : 0

  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-private-subnet-${count.index + 1}"
    Type = "private-subnet"
    AZ   = var.availability_zones[count.index]
    Tier = "private"
  })
}

# Elastic IPs for NAT Gateways (if private subnets enabled)
resource "aws_eip" "nat" {
  count = var.enable_private_subnets && var.enable_nat_gateway ? length(var.availability_zones) : 0

  domain = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-nat-eip-${count.index + 1}"
    Type = "elastic-ip"
    AZ   = var.availability_zones[count.index]
  })
}

# NAT Gateways (if private subnets enabled)
resource "aws_nat_gateway" "main" {
  count = var.enable_private_subnets && var.enable_nat_gateway ? length(var.availability_zones) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-nat-gateway-${count.index + 1}"
    Type = "nat-gateway"
    AZ   = var.availability_zones[count.index]
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-public-rt"
    Type = "route-table"
    Tier = "public"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for high availability)
resource "aws_route_table" "private" {
  count = var.enable_private_subnets ? length(var.availability_zones) : 0

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(local.vpc_tags, {
    Name = "${var.name_prefix}-private-rt-${count.index + 1}"
    Type = "route-table"
    Tier = "private"
    AZ   = var.availability_zones[count.index]
  })
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = var.enable_private_subnets ? length(aws_subnet.private) : 0

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
```

```hcl
# examples/02-modular-structure/modules/vpc/variables.tf

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "Name prefix must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 1 && length(var.availability_zones) <= 6
    error_message = "Must specify between 1 and 6 availability zones."
  }
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on instance launch in public subnets"
  type        = bool
  default     = true
}

variable "enable_private_subnets" {
  description = "Create private subnets"
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Create NAT gateways for private subnets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

```hcl
# examples/02-modular-structure/modules/vpc/outputs.tf

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "public_subnet_arns" {
  description = "ARNs of the public subnets"
  value       = aws_subnet.public[*].arn
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "private_subnet_arns" {
  description = "ARNs of the private subnets"
  value       = aws_subnet.private[*].arn
}

output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_ips" {
  description = "Public IP addresses of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Structured output for easy consumption by other modules
output "network_config" {
  description = "Complete network configuration object"
  value = {
    vpc = {
      id         = aws_vpc.main.id
      cidr_block = aws_vpc.main.cidr_block
      arn        = aws_vpc.main.arn
    }
    public_subnets = {
      ids        = aws_subnet.public[*].id
      cidrs      = aws_subnet.public[*].cidr_block
      arns       = aws_subnet.public[*].arn
      azs        = aws_subnet.public[*].availability_zone
    }
    private_subnets = {
      ids        = aws_subnet.private[*].id
      cidrs      = aws_subnet.private[*].cidr_block
      arns       = aws_subnet.private[*].arn
      azs        = aws_subnet.private[*].availability_zone
    }
    gateways = {
      internet_gateway_id = aws_internet_gateway.main.id
      nat_gateway_ids     = aws_nat_gateway.main[*].id
      nat_gateway_ips     = aws_eip.nat[*].public_ip
    }
  }
}
```

```hcl
# examples/02-modular-structure/main.tf

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

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# Local values for configuration
locals {
  # Environment-specific configuration
  environment_config = {
    dev = {
      vpc_cidr              = "10.0.0.0/16"
      enable_private_subnets = false
      enable_nat_gateway     = false
      instance_type         = "t3.micro"
    }
    staging = {
      vpc_cidr              = "10.1.0.0/16"
      enable_private_subnets = true
      enable_nat_gateway     = true
      instance_type         = "t3.small"
    }
    prod = {
      vpc_cidr              = "10.2.0.0/16"
      enable_private_subnets = true
      enable_nat_gateway     = true
      instance_type         = "t3.medium"
    }
  }

  # Select configuration for current environment
  current_config = local.environment_config[var.environment]

  # Common naming prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Use up to 3 AZs for high availability
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 3)

  # Common tags for all resources
  common_tags = merge(var.default_tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "terraform-fundamentals"
  })
}

# VPC Module - Network Foundation Layer
module "vpc" {
  source = "./modules/vpc"

  name_prefix            = local.name_prefix
  vpc_cidr              = local.current_config.vpc_cidr
  availability_zones    = local.availability_zones
  enable_private_subnets = local.current_config.enable_private_subnets
  enable_nat_gateway     = local.current_config.enable_nat_gateway

  tags = merge(local.common_tags, {
    Layer = "foundation"
    Type  = "networking"
  })
}

# Security Module - Security Foundation Layer
module "security" {
  source = "./modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr_block

  # Security configuration
  allowed_cidr_blocks = var.allowed_cidr_blocks
  enable_ssh_access   = var.enable_ssh_access

  tags = merge(local.common_tags, {
    Layer = "foundation"
    Type  = "security"
  })
}

# Compute Module - Application Layer
module "compute" {
  source = "./modules/compute"

  name_prefix        = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  security_group_ids = [module.security.web_security_group_id]

  # Compute configuration
  instance_type    = local.current_config.instance_type
  min_size        = var.min_size
  max_size        = var.max_size
  desired_capacity = var.desired_capacity

  # Application configuration
  application_port = var.application_port
  health_check_path = var.health_check_path

  tags = merge(local.common_tags, {
    Layer = "application"
    Type  = "compute"
  })
}
```

### 3. Enterprise Structure with Composition

For large-scale projects, we need even more sophisticated organization:

```
examples/03-enterprise-structure/
├── environments/              # Environment-specific configurations
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── modules/                   # Reusable modules
│   ├── foundation/            # Core infrastructure modules
│   │   ├── vpc/
│   │   ├── security/
│   │   └── iam/
│   ├── platform/             # Platform services
│   │   ├── monitoring/
│   │   ├── logging/
│   │   └── backup/
│   ├── application/          # Application-specific modules
│   │   ├── web-app/
│   │   ├── api/
│   │   └── database/
│   └── composition/          # High-level composition modules
│       ├── complete-environment/
│       ├── web-application-stack/
│       └── data-platform/
└── shared/                   # Shared resources and data
    ├── data-sources/
    ├── locals/
    └── remote-state/
```

```hcl
# examples/03-enterprise-structure/modules/composition/web-application-stack/main.tf

# Web Application Stack Composition Module
# This module composes multiple foundation modules to create a complete web application infrastructure

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  # Compute naming prefix for all resources
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Environment-specific configurations
  environment_defaults = {
    dev = {
      vpc_cidr           = "10.0.0.0/16"
      instance_type      = "t3.micro"
      min_size          = 1
      max_size          = 2
      desired_capacity  = 1
      multi_az          = false
      backup_retention  = 7
    }
    staging = {
      vpc_cidr           = "10.1.0.0/16"
      instance_type      = "t3.small"
      min_size          = 1
      max_size          = 3
      desired_capacity  = 2
      multi_az          = true
      backup_retention  = 14
    }
    prod = {
      vpc_cidr           = "10.2.0.0/16"
      instance_type      = "t3.medium"
      min_size          = 2
      max_size          = 10
      desired_capacity  = 3
      multi_az          = true
      backup_retention  = 30
    }
  }
  
  # Merge environment defaults with provided configuration
  config = merge(
    local.environment_defaults[var.environment],
    var.stack_configuration
  )
  
  # Common tags for all resources in the stack
  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    Stack       = "web-application"
    ManagedBy   = "Terraform"
  })
}

# Foundation Layer - Networking
module "networking" {
  source = "../../foundation/vpc"

  name_prefix            = local.name_prefix
  vpc_cidr              = local.config.vpc_cidr
  availability_zones    = var.availability_zones
  enable_private_subnets = local.config.multi_az
  enable_nat_gateway     = local.config.multi_az

  tags = merge(local.common_tags, {
    Layer     = "foundation"
    Component = "networking"
  })
}

# Foundation Layer - Security
module "security" {
  source = "../../foundation/security"

  name_prefix         = local.name_prefix
  vpc_id             = module.networking.vpc_id
  vpc_cidr           = module.networking.vpc_cidr_block
  allowed_cidr_blocks = var.allowed_cidr_blocks

  # Application-specific security rules
  application_ports = var.application_ports
  enable_ssh_access = var.enable_ssh_access

  tags = merge(local.common_tags, {
    Layer     = "foundation"
    Component = "security"
  })
}

# Foundation Layer - IAM
module "iam" {
  source = "../../foundation/iam"

  name_prefix   = local.name_prefix
  project_name  = var.project_name
  environment   = var.environment

  # IAM configuration for the application
  create_instance_role     = true
  create_deployment_role   = true
  additional_policies      = var.additional_iam_policies

  tags = merge(local.common_tags, {
    Layer     = "foundation"
    Component = "iam"
  })
}

# Platform Layer - Monitoring
module "monitoring" {
  source = "../../platform/monitoring"

  name_prefix    = local.name_prefix
  vpc_id         = module.networking.vpc_id

  # Monitoring configuration
  enable_detailed_monitoring = var.enable_monitoring
  alarm_endpoints           = var.alarm_endpoints
  log_retention_days        = local.config.backup_retention

  tags = merge(local.common_tags, {
    Layer     = "platform"
    Component = "monitoring"
  })
}

# Platform Layer - Backup
module "backup" {
  source = "../../platform/backup"

  name_prefix = local.name_prefix

  # Backup configuration
  backup_retention_days = local.config.backup_retention
  backup_schedule      = var.backup_schedule
  enable_cross_region  = var.environment == "prod"

  tags = merge(local.common_tags, {
    Layer     = "platform"
    Component = "backup"
  })
}

# Application Layer - Database
module "database" {
  source = "../../application/database"

  name_prefix    = local.name_prefix
  vpc_id         = module.networking.vpc_id
  subnet_ids     = local.config.multi_az ? module.networking.private_subnet_ids : module.networking.public_subnet_ids
  security_group_ids = [module.security.database_security_group_id]

  # Database configuration
  engine_version     = var.database_config.engine_version
  instance_class     = var.database_config.instance_class
  allocated_storage  = var.database_config.allocated_storage
  multi_az          = local.config.multi_az
  backup_retention  = local.config.backup_retention

  # Security configuration
  master_username = var.database_config.master_username
  manage_master_user_password = true

  tags = merge(local.common_tags, {
    Layer     = "application"
    Component = "database"
  })
}

# Application Layer - Web Application
module "web_application" {
  source = "../../application/web-app"

  name_prefix        = local.name_prefix
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.public_subnet_ids
  security_group_ids = [module.security.web_security_group_id]

  # Compute configuration
  instance_type     = local.config.instance_type
  min_size         = local.config.min_size
  max_size         = local.config.max_size
  desired_capacity = local.config.desired_capacity

  # Application configuration
  application_port    = var.application_ports[0]
  health_check_path   = var.health_check_path
  instance_profile_name = module.iam.instance_profile_name

  # Database connection
  database_endpoint = module.database.endpoint
  database_port     = module.database.port

  # Monitoring integration
  enable_detailed_monitoring = var.enable_monitoring
  cloudwatch_log_group      = module.monitoring.application_log_group_name

  tags = merge(local.common_tags, {
    Layer     = "application"
    Component = "web-application"
  })
}

# Application Layer - Content Delivery
module "cdn" {
  count  = var.enable_cdn ? 1 : 0
  source = "../../application/cdn"

  name_prefix = local.name_prefix

  # CDN configuration
  origin_domain_name = module.web_application.load_balancer_dns_name
  price_class       = var.cdn_price_class
  enable_logging    = var.enable_monitoring

  # Security configuration
  viewer_protocol_policy = "redirect-to-https"
  allowed_methods       = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

  tags = merge(local.common_tags, {
    Layer     = "application"
    Component = "cdn"
  })
}
```

## 🔗 Software Engineering Connections

### Design Patterns in Infrastructure

#### 1. Module Pattern (Similar to Class Design)
**Software Development:**
```typescript
class DatabaseService {
  constructor(private config: DatabaseConfig) {}
  
  public connect(): Connection { ... }
  public query(sql: string): Result { ... }
}
```

**Terraform Equivalent:**
```hcl
module "database" {
  source = "./modules/database"
  
  # Configuration (constructor parameters)
  engine         = var.engine
  instance_class = var.instance_class
  
  # Dependencies (dependency injection)
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids
}
```

#### 2. Factory Pattern
**Software Development:**
```typescript
class EnvironmentFactory {
  createEnvironment(type: string): Environment {
    switch(type) {
      case 'dev': return new DevEnvironment();
      case 'prod': return new ProdEnvironment();
    }
  }
}
```

**Terraform Equivalent:**
```hcl
module "environment" {
  source = "./modules/environment-factory"
  
  environment_type = var.environment  # Factory parameter
  
  # Factory creates appropriate configuration
}
```

#### 3. Composition Pattern
**Software Development:**
```typescript
class WebApplication {
  constructor(
    private database: DatabaseService,
    private cache: CacheService,
    private logger: LoggingService
  ) {}
}
```

**Terraform Equivalent:**
```hcl
module "web_application" {
  source = "./modules/web-application"
  
  # Composed dependencies
  database_config = module.database.connection_config
  cache_config    = module.cache.endpoint_config
  logging_config  = module.logging.log_group_config
}
```

### Code Organization Principles

#### 1. Single Responsibility Principle
**Good:**
```hcl
# VPC module handles only networking
module "vpc" { ... }

# Security module handles only security groups and policies
module "security" { ... }

# Database module handles only database resources
module "database" { ... }
```

**Bad:**
```hcl
# Monolithic module handling everything
module "everything" {
  # VPC, security, database, compute all mixed together
}
```

#### 2. Interface Segregation
**Good:**
```hcl
# Specific interfaces for different consumers
output "database_config" {
  value = {
    endpoint = aws_db_instance.main.endpoint
    port     = aws_db_instance.main.port
  }
}

output "monitoring_config" {
  value = {
    log_group = aws_cloudwatch_log_group.main.name
    metrics   = aws_cloudwatch_dashboard.main.dashboard_arn
  }
}
```

#### 3. Dependency Inversion
**Good:**
```hcl
# High-level module depends on abstractions (variables)
module "application" {
  source = "./modules/application"
  
  # Abstract dependencies
  vpc_config      = var.vpc_config
  database_config = var.database_config
  security_config = var.security_config
}
```

## 🎯 Hands-on Examples

### Exercise 1: Refactor Monolithic Configuration

**Objective:** Break down a monolithic configuration into modular components

**Starting Point:**
```hcl
# monolithic.tf - Everything in one file
resource "aws_vpc" "main" { ... }
resource "aws_subnet" "public" { ... }
resource "aws_security_group" "web" { ... }
resource "aws_instance" "web" { ... }
resource "aws_db_instance" "main" { ... }
# ... 50+ resources
```

**Target Architecture:**
```
modules/
├── vpc/           # Networking resources
├── security/      # Security groups and IAM
├── compute/       # EC2 and Auto Scaling
└── database/      # RDS resources
```

**Steps:**
1. Identify related resources and group them by responsibility
2. Create module directories with proper structure
3. Extract resources into appropriate modules
4. Define clear interfaces between modules
5. Update root configuration to use modules

### Exercise 2: Build Reusable Environment Factory

**Objective:** Create a factory module that can deploy consistent environments

**Requirements:**
- Support dev, staging, and prod environments
- Automatically size resources based on environment
- Apply appropriate security policies
- Configure monitoring and alerting

**Implementation:**
```hcl
module "environment" {
  source = "./modules/environment-factory"
  
  environment_name = "dev"
  # Factory handles all environment-specific configuration
}
```

### Exercise 3: Implement Layered Architecture

**Objective:** Organize modules into logical layers

**Architecture:**
```
Layer 1: Foundation (VPC, IAM, Security)
Layer 2: Platform (Monitoring, Logging, Backup)
Layer 3: Application (Web, API, Database)
Layer 4: Edge (CDN, WAF, DNS)
```

**Dependencies:** Higher layers depend on lower layers, never the reverse

## ✅ Best Practices

### 1. Module Design Principles

#### Clear Interfaces
```hcl
# Good: Clear, documented interface
variable "vpc_config" {
  description = "VPC configuration object"
  type = object({
    cidr_block         = string
    availability_zones = list(string)
    enable_dns         = bool
  })
  
  validation {
    condition     = can(cidrhost(var.vpc_config.cidr_block, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}
```

#### Composition Over Inheritance
```hcl
# Good: Compose functionality from smaller modules
module "web_application" {
  source = "./modules/web-application"
  
  vpc_config      = module.vpc.network_config
  security_config = module.security.policies_config
  database_config = module.database.connection_config
}

# Avoid: Large monolithic modules trying to do everything
```

#### Consistent Naming Conventions
```hcl
# Resource naming pattern: {project}-{environment}-{component}-{resource_type}
resource "aws_vpc" "main" {
  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# Module naming: descriptive and hierarchical
modules/
├── foundation/networking/
├── foundation/security/
├── platform/monitoring/
└── application/web-app/
```

### 2. File Organization

#### Module Structure
```
module/
├── main.tf          # Primary resource definitions
├── variables.tf     # Input variables with validation
├── outputs.tf       # Output values with descriptions
├── versions.tf      # Provider requirements
├── locals.tf        # Local value computations (optional)
├── data.tf          # Data source definitions (optional)
└── README.md        # Module documentation
```

#### Root Configuration Structure
```
project/
├── main.tf              # Module composition
├── variables.tf         # Root-level variables
├── outputs.tf          # Root-level outputs
├── terraform.tfvars    # Variable values
├── versions.tf         # Provider requirements
├── backend.tf          # Backend configuration
└── README.md           # Project documentation
```

### 3. Configuration Management

#### Environment-Specific Configuration
```hcl
# Use locals for environment-specific settings
locals {
  environment_config = {
    dev = {
      instance_type = "t3.micro"
      min_size     = 1
      max_size     = 2
    }
    prod = {
      instance_type = "t3.large"
      min_size     = 3
      max_size     = 10
    }
  }
  
  current_config = local.environment_config[var.environment]
}
```

#### Variable Validation
```hcl
variable "environment" {
  description = "Environment name"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

### 4. Documentation Standards

#### Module Documentation
```markdown
# Module: VPC

## Description
Creates a VPC with public and optional private subnets across multiple AZs.

## Usage
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix        = "myproject-dev"
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-west-2a", "us-west-2b"]
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name_prefix | Prefix for resource names | string | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
```

## ⚠️ Common Pitfalls

### 1. Over-Modularization
**Problem:** Creating too many small modules that add complexity without value

**Solution:**
- Group related resources that are always deployed together
- Avoid modules with only 1-2 resources unless they're highly reusable
- Focus on logical boundaries and dependencies

### 2. Circular Dependencies
**Problem:** Modules depending on each other in circular fashion

**Example:**
```hcl
module "vpc" {
  security_group_id = module.security.web_sg_id  # Bad!
}

module "security" {
  vpc_id = module.vpc.vpc_id
}
```

**Solution:**
- Design clear dependency hierarchy
- Use data sources to break circular dependencies
- Consider module composition patterns

### 3. Tight Coupling
**Problem:** Modules that know too much about each other's internals

**Solution:**
- Use well-defined interfaces (variables and outputs)
- Avoid referencing internal resource attributes across modules
- Create structured outputs for complex data

### 4. Inconsistent Module Interfaces
**Problem:** Similar modules with different variable names and structures

**Solution:**
- Establish module interface standards
- Use consistent naming conventions
- Create module templates and examples

### 5. Poor Error Handling
**Problem:** Unclear error messages when module composition fails

**Solution:**
- Add comprehensive variable validation
- Use descriptive error messages
- Include validation for complex objects and relationships

## 🔍 Troubleshooting

### Module Resolution Issues

**Problem:** Terraform cannot find or initialize modules

**Diagnosis:**
```bash
terraform init
terraform get
```

**Common Solutions:**
1. Check module source paths
2. Ensure module directories exist
3. Run `terraform get` to download modules
4. Verify module syntax and structure

### Variable Type Mismatches

**Problem:** Type conflicts between modules

**Diagnosis:**
```bash
terraform plan
# Look for type conversion errors
```

**Solutions:**
1. Check variable type definitions
2. Use type conversion functions
3. Validate complex object structures
4. Add explicit type constraints

### Output Reference Errors

**Problem:** Cannot reference module outputs

**Diagnosis:**
```bash
terraform show
terraform output
```

**Solutions:**
1. Verify output definitions in modules
2. Check output naming consistency
3. Ensure modules are properly instantiated
4. Use `terraform refresh` to update state

## 📚 Further Reading

### Official Documentation
- [Terraform Modules](https://www.terraform.io/docs/language/modules/index.html)
- [Module Composition](https://www.terraform.io/docs/language/modules/composition.html)
- [Module Development](https://www.terraform.io/docs/language/modules/develop/index.html)

### Advanced Topics
- [Module Versioning Strategies](https://www.terraform.io/docs/language/modules/sources.html)
- [Private Module Registries](https://www.terraform.io/docs/cloud/registry/index.html)
- [Testing Terraform Modules](https://www.terraform.io/docs/extend/testing/index.html)

### Software Architecture Resources
- Clean Architecture principles by Robert Martin
- Domain-Driven Design concepts
- Microservices architecture patterns
- Dependency injection patterns

## 🎯 Next Steps

You've now mastered the art of organizing Terraform code using proven software architecture principles. You can:

- Design modular, reusable infrastructure components
- Apply separation of concerns to infrastructure code
- Create clear interfaces and abstractions
- Implement composition patterns for complex systems

**Ready for the next challenge?** Proceed to [Module 03: Security](../03-security/) to learn how to implement comprehensive security measures using defense-in-depth strategies.

### Skills Gained
✅ Modular infrastructure design  
✅ Clean architecture principles  
✅ Code organization and reusability  
✅ Interface design and abstraction  
✅ Composition and dependency management  
✅ Documentation and maintenance strategies  

### Career Impact
These architectural skills are highly valued in enterprise environments:
- **Senior DevOps Engineer**: Designing scalable infrastructure architectures
- **Platform Engineer**: Building reusable infrastructure platforms
- **Cloud Architect**: Creating enterprise-scale cloud solutions
- **Technical Lead**: Establishing infrastructure standards and practices