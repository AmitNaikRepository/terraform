# {MODULE_NAME} Module

## Description

{Provide a clear, concise description of what this module does and its purpose in the larger infrastructure architecture.}

## Features

- ✅ {Feature 1}
- ✅ {Feature 2}
- ✅ {Feature 3}
- ✅ Comprehensive tagging strategy
- ✅ Input validation
- ✅ Flexible configuration options

## Usage

### Basic Example

```hcl
module "{module_name}" {
  source = "./modules/{module-name}"

  project_name = "my-project"
  environment  = "dev"

  # Module-specific configuration
  example_setting = "option1"
  enable_feature  = true

  tags = {
    Owner     = "Platform Team"
    Component = "infrastructure"
  }
}
```

### Advanced Example

```hcl
module "{module_name}" {
  source = "./modules/{module-name}"

  project_name = "my-project"
  environment  = "prod"

  # Advanced configuration
  configuration_object = {
    setting1 = "production"
    setting2 = 100
    setting3 = true
  }

  optional_list = [
    "item1",
    "item2",
    "item3"
  ]

  tags = {
    Owner       = "Platform Team"
    Component   = "infrastructure"
    Environment = "production"
    CostCenter  = "engineering"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |
| random | ~> 3.4 |

## Resources

| Name | Type |
|------|------|
| [aws_s3_bucket.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [random_string.suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_name | Name of the project (used in resource naming) | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod) | `string` | n/a | yes |
| tags | Tags to apply to all resources created by this module | `map(string)` | `{}` | no |
| name_prefix | Prefix for naming resources (optional, will default to project-environment) | `string` | `null` | no |
| example_setting | Example configuration setting | `string` | `"default-value"` | no |
| enable_feature | Enable optional feature | `bool` | `false` | no |
| configuration_object | Complex configuration object | <pre>object({<br>    setting1 = string<br>    setting2 = number<br>    setting3 = bool<br>  })</pre> | <pre>{<br>  "setting1": "default",<br>  "setting2": 10,<br>  "setting3": true<br>}</pre> | no |
| optional_list | Optional list of items | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| module_name | Name of this module |
| resource_tags | Common tags applied to all resources |
| example_bucket_id | ID of the example S3 bucket |
| example_bucket_arn | ARN of the example S3 bucket |
| example_bucket_domain_name | Domain name of the example S3 bucket |
| bucket_config | Complete bucket configuration object |
| conditional_output | Output that's only present when feature is enabled |
| resource_list | List of created resource IDs |
| resource_map | Map of resource names to their IDs |

## Examples

### Integration with Other Modules

```hcl
# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
}

# This Module
module "{module_name}" {
  source = "./modules/{module-name}"

  project_name = var.project_name
  environment  = var.environment

  # Use outputs from other modules
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  tags = local.common_tags
}

# Application Module
module "application" {
  source = "./modules/application"

  project_name = var.project_name
  environment  = var.environment

  # Use outputs from this module
  bucket_config = module.{module_name}.bucket_config

  tags = local.common_tags
}
```

### Environment-Specific Configuration

```hcl
locals {
  environment_config = {
    dev = {
      example_setting = "development"
      enable_feature  = false
    }
    staging = {
      example_setting = "staging"
      enable_feature  = true
    }
    prod = {
      example_setting = "production"
      enable_feature  = true
    }
  }
}

module "{module_name}" {
  source = "./modules/{module-name}"

  project_name = var.project_name
  environment  = var.environment

  # Environment-specific configuration
  example_setting = local.environment_config[var.environment].example_setting
  enable_feature  = local.environment_config[var.environment].enable_feature

  tags = local.common_tags
}
```

## Best Practices

### Tagging Strategy
```hcl
# Consistent tagging across all environments
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "{MODULE_NAME}"
    Owner       = "Platform Team"
    Repository  = "terraform-fundamentals"
  }
}

module "{module_name}" {
  source = "./modules/{module-name}"

  project_name = var.project_name
  environment  = var.environment

  tags = local.common_tags
}
```

### Variable Validation
```hcl
# The module includes comprehensive validation
variable "environment" {
  description = "Environment name"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

## Security Considerations

- {List any security considerations specific to this module}
- All resources are tagged for compliance and cost tracking
- Input validation prevents misconfigurations
- {Add other security notes}

## Cost Optimization

- {List cost optimization features}
- Resource tagging enables cost allocation
- {Add other cost considerations}

## Troubleshooting

### Common Issues

1. **Issue**: {Common issue description}
   **Solution**: {Solution description}

2. **Issue**: {Another common issue}
   **Solution**: {Another solution}

### Debugging

```bash
# Check module inputs
terraform console
> var.project_name
> var.environment

# Validate configuration
terraform validate

# Plan with detailed output
terraform plan -detailed-exitcode
```

## Contributing

1. Update the module code
2. Update this README if inputs/outputs change
3. Add examples for new features
4. Test with multiple environments
5. Update version constraints if needed

## License

This module is part of the Terraform Fundamentals learning repository.

## Support

- **Documentation**: See the main repository README
- **Issues**: Report issues in the main repository
- **Examples**: Check the `examples/` directory