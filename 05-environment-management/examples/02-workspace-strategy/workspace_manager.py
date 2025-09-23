import json
import boto3
import logging
from datetime import datetime, timezone
from typing import Dict, List, Any

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context) -> Dict[str, Any]:
    """
    AWS Lambda function for Terraform workspace management and monitoring.
    
    This function provides workspace-aware infrastructure management:
    1. Monitors workspace-specific resources
    2. Validates workspace configuration
    3. Provides workspace status and health checks
    4. Manages workspace-specific operations
    """
    
    try:
        # Get environment variables
        workspace = context.environment.get('WORKSPACE', 'unknown')
        environment = context.environment.get('ENVIRONMENT', 'unknown')
        project_name = context.environment.get('PROJECT_NAME', 'unknown')
        vpc_id = context.environment.get('VPC_ID', '')
        bucket_name = context.environment.get('BUCKET_NAME', '')
        log_group = context.environment.get('LOG_GROUP', '')
        
        logger.info(f"Workspace manager invoked for workspace: {workspace}")
        
        # Initialize AWS clients
        ec2 = boto3.client('ec2')
        autoscaling = boto3.client('autoscaling')
        s3 = boto3.client('s3')
        ssm = boto3.client('ssm')
        cloudwatch = boto3.client('cloudwatch')
        
        # Gather workspace information
        workspace_info = {
            'workspace': workspace,
            'environment': environment,
            'project_name': project_name,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'function_name': context.function_name,
            'resources': {},
            'health_checks': {},
            'recommendations': []
        }
        
        # Check VPC resources
        if vpc_id:
            vpc_info = check_vpc_resources(ec2, vpc_id, workspace)
            workspace_info['resources']['vpc'] = vpc_info
            workspace_info['health_checks']['vpc'] = validate_vpc_health(vpc_info)
        
        # Check Auto Scaling Groups
        asg_info = check_workspace_asgs(autoscaling, project_name, workspace)
        workspace_info['resources']['autoscaling'] = asg_info
        workspace_info['health_checks']['autoscaling'] = validate_asg_health(asg_info, workspace)
        
        # Check S3 resources
        if bucket_name:
            s3_info = check_s3_resources(s3, bucket_name, workspace)
            workspace_info['resources']['s3'] = s3_info
            workspace_info['health_checks']['s3'] = validate_s3_health(s3_info)
        
        # Check SSM parameters
        ssm_info = check_ssm_parameters(ssm, project_name, workspace)
        workspace_info['resources']['ssm'] = ssm_info
        
        # Generate workspace-specific recommendations
        workspace_info['recommendations'] = generate_recommendations(workspace_info, workspace)
        
        # Store workspace status in SSM
        store_workspace_status(ssm, workspace_info, project_name, workspace)
        
        logger.info(f"Workspace management completed for {workspace}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(workspace_info, indent=2, default=str)
        }
        
    except Exception as e:
        logger.error(f"Error in workspace manager: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e),
                'workspace': workspace,
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }

def check_vpc_resources(ec2, vpc_id: str, workspace: str) -> Dict[str, Any]:
    """Check VPC and related networking resources."""
    
    vpc_info = {
        'vpc_id': vpc_id,
        'subnets': [],
        'security_groups': [],
        'route_tables': [],
        'internet_gateways': [],
        'nat_gateways': []
    }
    
    try:
        # Get VPC details
        vpcs = ec2.describe_vpcs(VpcIds=[vpc_id])
        if vpcs['Vpcs']:
            vpc = vpcs['Vpcs'][0]
            vpc_info['cidr_block'] = vpc['CidrBlock']
            vpc_info['state'] = vpc['State']
        
        # Get subnets
        subnets = ec2.describe_subnets(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]},
                {'Name': 'tag:Workspace', 'Values': [workspace]}
            ]
        )
        
        for subnet in subnets['Subnets']:
            subnet_info = {
                'subnet_id': subnet['SubnetId'],
                'cidr_block': subnet['CidrBlock'],
                'availability_zone': subnet['AvailabilityZone'],
                'available_ip_count': subnet['AvailableIpAddressCount'],
                'state': subnet['State']
            }
            
            # Determine subnet type from tags
            for tag in subnet.get('Tags', []):
                if tag['Key'] == 'Type':
                    subnet_info['type'] = tag['Value']
                    break
            
            vpc_info['subnets'].append(subnet_info)
        
        # Get security groups
        security_groups = ec2.describe_security_groups(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]},
                {'Name': 'tag:Workspace', 'Values': [workspace]}
            ]
        )
        
        for sg in security_groups['SecurityGroups']:
            sg_info = {
                'group_id': sg['GroupId'],
                'group_name': sg['GroupName'],
                'description': sg['Description'],
                'ingress_rules': len(sg['IpPermissions']),
                'egress_rules': len(sg['IpPermissionsEgress'])
            }
            vpc_info['security_groups'].append(sg_info)
        
        # Get NAT Gateways
        nat_gateways = ec2.describe_nat_gateways(
            Filters=[
                {'Name': 'vpc-id', 'Values': [vpc_id]},
                {'Name': 'tag:Workspace', 'Values': [workspace]}
            ]
        )
        
        for nat in nat_gateways['NatGateways']:
            nat_info = {
                'nat_gateway_id': nat['NatGatewayId'],
                'subnet_id': nat['SubnetId'],
                'state': nat['State'],
                'public_ip': nat['NatGatewayAddresses'][0]['PublicIp'] if nat['NatGatewayAddresses'] else None
            }
            vpc_info['nat_gateways'].append(nat_info)
        
    except Exception as e:
        logger.error(f"Error checking VPC resources: {str(e)}")
        vpc_info['error'] = str(e)
    
    return vpc_info

def check_workspace_asgs(autoscaling, project_name: str, workspace: str) -> Dict[str, Any]:
    """Check Auto Scaling Groups for the workspace."""
    
    asg_info = {
        'auto_scaling_groups': [],
        'total_instances': 0,
        'healthy_instances': 0
    }
    
    try:
        # Get ASGs for this workspace
        response = autoscaling.describe_auto_scaling_groups()
        
        for asg in response['AutoScalingGroups']:
            # Check if ASG belongs to this workspace
            workspace_match = False
            for tag in asg.get('Tags', []):
                if tag['Key'] == 'Workspace' and tag['Value'] == workspace:
                    workspace_match = True
                    break
            
            if workspace_match:
                asg_details = {
                    'name': asg['AutoScalingGroupName'],
                    'min_size': asg['MinSize'],
                    'max_size': asg['MaxSize'],
                    'desired_capacity': asg['DesiredCapacity'],
                    'current_instances': len(asg['Instances']),
                    'healthy_instances': len([i for i in asg['Instances'] if i['HealthStatus'] == 'Healthy']),
                    'availability_zones': asg['AvailabilityZones'],
                    'launch_template': asg.get('LaunchTemplate', {}).get('LaunchTemplateName', 'N/A')
                }
                
                asg_info['auto_scaling_groups'].append(asg_details)
                asg_info['total_instances'] += len(asg['Instances'])
                asg_info['healthy_instances'] += len([i for i in asg['Instances'] if i['HealthStatus'] == 'Healthy'])
        
    except Exception as e:
        logger.error(f"Error checking ASGs: {str(e)}")
        asg_info['error'] = str(e)
    
    return asg_info

def check_s3_resources(s3, bucket_name: str, workspace: str) -> Dict[str, Any]:
    """Check S3 bucket resources for the workspace."""
    
    s3_info = {
        'bucket_name': bucket_name,
        'exists': False,
        'versioning': 'Unknown',
        'encryption': 'Unknown',
        'object_count': 0,
        'total_size_bytes': 0
    }
    
    try:
        # Check if bucket exists
        s3.head_bucket(Bucket=bucket_name)
        s3_info['exists'] = True
        
        # Get versioning status
        versioning = s3.get_bucket_versioning(Bucket=bucket_name)
        s3_info['versioning'] = versioning.get('Status', 'Suspended')
        
        # Get encryption status
        try:
            encryption = s3.get_bucket_encryption(Bucket=bucket_name)
            s3_info['encryption'] = 'Enabled'
        except s3.exceptions.NoSuchBucket:
            s3_info['encryption'] = 'Disabled'
        except Exception:
            s3_info['encryption'] = 'Unknown'
        
        # Get object count and size (sample)
        objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000)
        if 'Contents' in objects:
            s3_info['object_count'] = len(objects['Contents'])
            s3_info['total_size_bytes'] = sum(obj['Size'] for obj in objects['Contents'])
        
    except Exception as e:
        logger.error(f"Error checking S3 resources: {str(e)}")
        s3_info['error'] = str(e)
    
    return s3_info

def check_ssm_parameters(ssm, project_name: str, workspace: str) -> Dict[str, Any]:
    """Check SSM parameters for the workspace."""
    
    ssm_info = {
        'parameters': [],
        'workspace_config_exists': False
    }
    
    try:
        # Check for workspace configuration parameter
        config_param_name = f"/{project_name}/{workspace}/config"
        
        try:
            param = ssm.get_parameter(Name=config_param_name)
            ssm_info['workspace_config_exists'] = True
            ssm_info['config_last_modified'] = param['Parameter']['LastModifiedDate']
            ssm_info['config_version'] = param['Parameter']['Version']
            
            # Parse configuration
            try:
                config_data = json.loads(param['Parameter']['Value'])
                ssm_info['config_data'] = config_data
            except json.JSONDecodeError:
                ssm_info['config_data'] = 'Invalid JSON'
                
        except ssm.exceptions.ParameterNotFound:
            ssm_info['workspace_config_exists'] = False
        
        # List other parameters for this workspace
        parameters = ssm.describe_parameters(
            ParameterFilters=[
                {
                    'Key': 'Name',
                    'Option': 'BeginsWith',
                    'Values': [f"/{project_name}/{workspace}/"]
                }
            ]
        )
        
        for param in parameters['Parameters']:
            param_info = {
                'name': param['Name'],
                'type': param['Type'],
                'last_modified': param['LastModifiedDate'],
                'version': param['Version']
            }
            ssm_info['parameters'].append(param_info)
        
    except Exception as e:
        logger.error(f"Error checking SSM parameters: {str(e)}")
        ssm_info['error'] = str(e)
    
    return ssm_info

def validate_vpc_health(vpc_info: Dict[str, Any]) -> Dict[str, Any]:
    """Validate VPC health and configuration."""
    
    health = {
        'status': 'healthy',
        'issues': [],
        'warnings': []
    }
    
    # Check VPC state
    if vpc_info.get('state') != 'available':
        health['issues'].append(f"VPC state is {vpc_info.get('state')}, expected 'available'")
        health['status'] = 'unhealthy'
    
    # Check subnet availability
    subnets_by_type = {}
    for subnet in vpc_info.get('subnets', []):
        subnet_type = subnet.get('type', 'unknown')
        if subnet_type not in subnets_by_type:
            subnets_by_type[subnet_type] = []
        subnets_by_type[subnet_type].append(subnet)
        
        # Check for low IP availability
        if subnet['available_ip_count'] < 10:
            health['warnings'].append(f"Subnet {subnet['subnet_id']} has low available IPs: {subnet['available_ip_count']}")
    
    # Validate subnet types
    expected_types = ['public', 'private']
    for expected_type in expected_types:
        if expected_type not in subnets_by_type:
            health['warnings'].append(f"No {expected_type} subnets found")
    
    return health

def validate_asg_health(asg_info: Dict[str, Any], workspace: str) -> Dict[str, Any]:
    """Validate Auto Scaling Group health."""
    
    health = {
        'status': 'healthy',
        'issues': [],
        'warnings': []
    }
    
    if not asg_info.get('auto_scaling_groups'):
        health['issues'].append("No Auto Scaling Groups found for this workspace")
        health['status'] = 'unhealthy'
        return health
    
    for asg in asg_info['auto_scaling_groups']:
        # Check if all instances are healthy
        if asg['healthy_instances'] < asg['current_instances']:
            health['warnings'].append(f"ASG {asg['name']} has unhealthy instances: {asg['current_instances'] - asg['healthy_instances']}")
        
        # Check if desired capacity is met
        if asg['current_instances'] != asg['desired_capacity']:
            health['warnings'].append(f"ASG {asg['name']} current instances ({asg['current_instances']}) doesn't match desired ({asg['desired_capacity']})")
        
        # Workspace-specific checks
        if workspace == 'prod':
            if asg['min_size'] < 2:
                health['warnings'].append(f"Production ASG {asg['name']} should have min_size >= 2 for HA")
            if len(asg['availability_zones']) < 2:
                health['warnings'].append(f"Production ASG {asg['name']} should span multiple AZs")
    
    return health

def validate_s3_health(s3_info: Dict[str, Any]) -> Dict[str, Any]:
    """Validate S3 bucket health."""
    
    health = {
        'status': 'healthy',
        'issues': [],
        'warnings': []
    }
    
    if not s3_info.get('exists'):
        health['issues'].append("S3 bucket does not exist")
        health['status'] = 'unhealthy'
        return health
    
    if s3_info.get('encryption') == 'Disabled':
        health['warnings'].append("S3 bucket encryption is disabled")
    
    return health

def generate_recommendations(workspace_info: Dict[str, Any], workspace: str) -> List[str]:
    """Generate workspace-specific recommendations."""
    
    recommendations = []
    
    # VPC recommendations
    vpc_info = workspace_info.get('resources', {}).get('vpc', {})
    if vpc_info:
        nat_gateways = vpc_info.get('nat_gateways', [])
        if workspace in ['dev', 'test'] and nat_gateways:
            recommendations.append("Consider removing NAT Gateways in dev/test environments to reduce costs")
        elif workspace == 'prod' and not nat_gateways:
            recommendations.append("Production environment should have NAT Gateways for private subnet internet access")
    
    # ASG recommendations
    asg_info = workspace_info.get('resources', {}).get('autoscaling', {})
    if asg_info:
        total_instances = asg_info.get('total_instances', 0)
        if workspace in ['dev', 'test'] and total_instances > 2:
            recommendations.append("Consider reducing instance count in dev/test environments for cost optimization")
        elif workspace == 'prod' and total_instances < 3:
            recommendations.append("Production environment should have at least 3 instances for high availability")
    
    # S3 recommendations
    s3_info = workspace_info.get('resources', {}).get('s3', {})
    if s3_info:
        if workspace == 'prod' and s3_info.get('versioning') != 'Enabled':
            recommendations.append("Enable S3 versioning for production environments")
        elif workspace in ['dev', 'test'] and s3_info.get('versioning') == 'Enabled':
            recommendations.append("Consider disabling S3 versioning in dev/test to reduce storage costs")
    
    # General workspace recommendations
    if workspace == 'default':
        recommendations.append("Consider creating dedicated workspaces (dev, staging, prod) instead of using default")
    
    return recommendations

def store_workspace_status(ssm, workspace_info: Dict[str, Any], project_name: str, workspace: str):
    """Store workspace status in SSM for monitoring."""
    
    try:
        status_param_name = f"/{project_name}/{workspace}/status"
        
        # Create a summary status
        status_summary = {
            'workspace': workspace,
            'last_check': workspace_info['timestamp'],
            'overall_health': 'healthy',
            'resource_counts': {
                'vpc_subnets': len(workspace_info.get('resources', {}).get('vpc', {}).get('subnets', [])),
                'security_groups': len(workspace_info.get('resources', {}).get('vpc', {}).get('security_groups', [])),
                'auto_scaling_groups': len(workspace_info.get('resources', {}).get('autoscaling', {}).get('auto_scaling_groups', [])),
                'total_instances': workspace_info.get('resources', {}).get('autoscaling', {}).get('total_instances', 0)
            },
            'recommendations_count': len(workspace_info.get('recommendations', []))
        }
        
        # Check for any unhealthy status
        health_checks = workspace_info.get('health_checks', {})
        for check_name, check_result in health_checks.items():
            if check_result.get('status') == 'unhealthy':
                status_summary['overall_health'] = 'unhealthy'
                break
        
        ssm.put_parameter(
            Name=status_param_name,
            Value=json.dumps(status_summary, default=str),
            Type='String',
            Overwrite=True,
            Description=f"Workspace status for {workspace}"
        )
        
    except Exception as e:
        logger.error(f"Error storing workspace status: {str(e)}")