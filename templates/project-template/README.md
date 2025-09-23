# {PROJECT_NAME} Infrastructure

This project template provides a complete, production-ready infrastructure setup using Terraform. It follows best practices for modularity, security, and maintainability.

## 🏗️ Architecture Overview

This template creates a multi-tier architecture with the following components:

```
┌─────────────────────────────────────────────────────────────┐
│                     Internet Gateway                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
    ┌─────────────────▼─────────────────┐
    │           Load Balancer           │  ← Public Subnets
    │        (Application Layer)        │
    └─────────────────┬─────────────────┘
                      │
    ┌─────────────────▼─────────────────┐
    │        Application Servers        │  ← Private Subnets
    │         (Auto Scaling)            │
    └─────────────────┬─────────────────┘
                      │
    ┌─────────────────▼─────────────────┐
    │            Database               │  ← Database Subnets
    │         (Multi-AZ RDS)            │
    └───────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate permissions
- An AWS account with sufficient permissions

### 1. Clone and Setup

```bash
# Copy the project template
cp -r templates/project-template my-new-project
cd my-new-project

# Create your variables file
cp terraform.tfvars.example terraform.tfvars
```

### 2. Configure Variables

Edit `terraform.tfvars` with your specific configuration:

```hcl
project_name = "my-awesome-app"
environment  = "dev"
aws_region   = "us-west-2"
owner        = "Your Team"

# Restrict access to your IP ranges
allowed_cidr_blocks = ["YOUR.IP.RANGE/24"]

# Enable optional features
enable_database  = true
enable_monitoring = true
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the deployment plan
terraform plan

# Deploy the infrastructure
terraform apply
```

### 4. Access Your Application

After deployment, your application will be available at:
```
http://{load_balancer_dns_name}
```

The DNS name will be shown in the Terraform outputs.

## 📚 Features

### 🔒 Security First
- **VPC with proper network segmentation**
- **Security groups with least privilege access**
- **IAM roles with minimal permissions**
- **Encryption at rest and in transit**
- **WAF protection for web applications**

### 🏗️ Modular Architecture
- **Reusable modules for each component**
- **Clear separation of concerns**
- **Environment-specific configurations**
- **Consistent naming and tagging**

### 📊 Observability
- **CloudWatch monitoring and alerting**
- **Centralized logging**
- **Custom dashboards**
- **Performance metrics**

### 💰 Cost Optimization
- **Auto scaling based on demand**
- **Spot instances for non-production**
- **Resource scheduling**
- **Lifecycle policies for storage**

### 🔄 High Availability
- **Multi-AZ deployment**
- **Auto scaling groups**
- **Load balancing**
- **Automated failover**

## 🗂️ Project Structure

```
project/
├── main.tf                    # Main infrastructure composition
├── variables.tf               # Input variables with validation
├── outputs.tf                 # Infrastructure outputs
├── terraform.tfvars.example   # Example configuration
├── README.md                  # This file
└── modules/                   # Reusable infrastructure modules
    ├── vpc/                   # VPC and networking
    ├── security/              # Security groups and IAM
    ├── compute/               # EC2 and auto scaling
    ├── load-balancer/         # Application load balancer
    ├── database/              # RDS database
    ├── monitoring/            # CloudWatch and alerting
    └── iam/                   # IAM roles and policies
```

## 🔧 Configuration

### Environment-Specific Settings

The template automatically configures resources based on the environment:

| Environment | VPC CIDR | Instance Type | Min/Max Instances | Private Subnets |
|-------------|----------|---------------|-------------------|-----------------|
| dev         | 10.0.0.0/16 | t3.micro   | 1/2               | No              |
| staging     | 10.1.0.0/16 | t3.small   | 1/3               | Yes             |
| prod        | 10.2.0.0/16 | t3.medium  | 2/10              | Yes             |

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `project_name` | Name of your project | `"my-app"` |
| `environment` | Environment name | `"dev"` |
| `aws_region` | AWS region | `"us-west-2"` |

### Optional Features

Enable optional features by setting these variables to `true`:

- `enable_database` - RDS database with automated backups
- `enable_monitoring` - CloudWatch dashboards and alerts
- `enable_backup` - Automated backup policies

## 🔐 Security Considerations

### Network Security
- **Private subnets** for application and database tiers
- **NAT Gateways** for secure outbound internet access
- **Security Groups** with least privilege rules
- **Network ACLs** for additional protection

### Identity and Access Management
- **Instance roles** with minimal required permissions
- **Cross-account access** with external ID validation
- **Time-based access controls** for deployment roles
- **Resource-specific policies** instead of wildcards

### Data Protection
- **Encryption at rest** using AWS KMS
- **Encryption in transit** with TLS
- **Secrets management** with AWS Secrets Manager
- **Database encryption** with automated key rotation

## 📊 Monitoring and Alerting

### CloudWatch Metrics
- Application performance metrics
- Infrastructure health checks
- Cost tracking and optimization
- Security event monitoring

### Automated Alerts
- High CPU utilization
- Memory pressure
- Database connection errors
- Security group changes

### Dashboards
- Application performance overview
- Infrastructure resource utilization
- Cost and billing analysis
- Security posture monitoring

## 💰 Cost Optimization

### Automatic Scaling
- **Auto Scaling Groups** adjust capacity based on demand
- **Scheduled scaling** for predictable load patterns
- **Spot instances** for non-production environments

### Storage Optimization
- **S3 lifecycle policies** for automated archiving
- **EBS volume optimization** based on usage patterns
- **Database right-sizing** recommendations

### Cost Monitoring
- **Resource tagging** for cost allocation
- **Budget alerts** for spend monitoring
- **Cost anomaly detection** for unexpected charges

## 🚀 Deployment

### Development Environment
```bash
# Quick development deployment
terraform workspace new dev
terraform plan -var="environment=dev"
terraform apply -auto-approve
```

### Production Environment
```bash
# Production deployment with approval
terraform workspace new prod
terraform plan -var="environment=prod" -out=prod.tfplan
terraform apply prod.tfplan
```

### CI/CD Integration
```yaml
# Example GitHub Actions workflow
name: Deploy Infrastructure
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
      - name: Terraform Plan
        run: terraform plan
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

## 🔍 Troubleshooting

### Common Issues

#### Permission Denied Errors
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names ec2:DescribeInstances
```

#### Resource Creation Failures
```bash
# Check resource limits
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A  # Running On-Demand instances

# Verify VPC limits
aws ec2 describe-account-attributes \
  --attribute-names supported-platforms
```

#### State File Issues
```bash
# Refresh state
terraform refresh

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Remove resources from state
terraform state rm aws_instance.example
```

### Debug Mode
```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Detailed error information
terraform plan -detailed-exitcode
```

## 📚 Next Steps

### Production Readiness Checklist
- [ ] Configure remote state backend
- [ ] Set up automated backups
- [ ] Implement SSL/TLS certificates
- [ ] Configure custom domain names
- [ ] Set up monitoring alerts
- [ ] Document runbooks and procedures
- [ ] Test disaster recovery procedures
- [ ] Implement security scanning
- [ ] Configure log aggregation
- [ ] Set up cost budgets and alerts

### Advanced Features
- [ ] Blue-green deployments
- [ ] Container orchestration
- [ ] Service mesh implementation
- [ ] Advanced security controls
- [ ] Multi-region setup
- [ ] Disaster recovery automation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

This project template is part of the Terraform Fundamentals learning repository.

## 🆘 Support

- **Documentation**: See module-specific README files
- **Issues**: Report issues in the main repository
- **Examples**: Check the `examples/` directory
- **Community**: Join discussions in GitHub Discussions

---

**🎉 Happy Infrastructure Coding!** This template provides everything you need to get started with production-ready infrastructure on AWS.