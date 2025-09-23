import json
import boto3
import logging
from datetime import datetime, timedelta
from typing import Dict, List

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """
    AWS Lambda function for automated cost optimization.
    
    This function performs various cost optimization tasks:
    1. Identifies underutilized EC2 instances
    2. Optimizes S3 storage through lifecycle policies
    3. Monitors Auto Scaling Group efficiency
    4. Checks for untagged resources
    5. Identifies cost optimization opportunities
    """
    
    try:
        project_name = context.environment['PROJECT_NAME']
        environment = context.environment['ENVIRONMENT']
        bucket_name = context.environment['BUCKET_NAME']
        
        logger.info(f"Starting cost optimization for {project_name}-{environment}")
        
        # Initialize AWS clients
        ec2 = boto3.client('ec2')
        cloudwatch = boto3.client('cloudwatch')
        autoscaling = boto3.client('autoscaling')
        s3 = boto3.client('s3')
        
        optimization_results = {
            'timestamp': datetime.utcnow().isoformat(),
            'project': project_name,
            'environment': environment,
            'optimizations': []
        }
        
        # 1. Check EC2 instance utilization
        instance_optimization = check_instance_utilization(ec2, cloudwatch, project_name, environment)
        optimization_results['optimizations'].append(instance_optimization)
        
        # 2. Check Auto Scaling Group efficiency
        asg_optimization = check_asg_efficiency(autoscaling, cloudwatch, project_name, environment)
        optimization_results['optimizations'].append(asg_optimization)
        
        # 3. Optimize S3 storage
        s3_optimization = optimize_s3_storage(s3, bucket_name)
        optimization_results['optimizations'].append(s3_optimization)
        
        # 4. Check resource tagging compliance
        tagging_optimization = check_tagging_compliance(ec2, s3, project_name, environment)
        optimization_results['optimizations'].append(tagging_optimization)
        
        # 5. Identify cost anomalies
        cost_anomalies = identify_cost_anomalies(cloudwatch, project_name, environment)
        optimization_results['optimizations'].append(cost_anomalies)
        
        logger.info(f"Cost optimization completed: {len(optimization_results['optimizations'])} checks performed")
        
        return {
            'statusCode': 200,
            'body': json.dumps(optimization_results, indent=2)
        }
        
    except Exception as e:
        logger.error(f"Error in cost optimization: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def check_instance_utilization(ec2, cloudwatch, project_name: str, environment: str) -> Dict:
    """Check EC2 instance utilization and identify underutilized instances."""
    
    optimization = {
        'category': 'EC2 Instance Utilization',
        'findings': [],
        'recommendations': [],
        'potential_savings': 0
    }
    
    try:
        # Get instances for this project
        response = ec2.describe_instances(
            Filters=[
                {'Name': 'tag:Project', 'Values': [project_name]},
                {'Name': 'tag:Environment', 'Values': [environment]},
                {'Name': 'instance-state-name', 'Values': ['running']}
            ]
        )
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                instance_type = instance['InstanceType']
                
                # Get CPU utilization for the last 7 days
                end_time = datetime.utcnow()
                start_time = end_time - timedelta(days=7)
                
                cpu_metrics = cloudwatch.get_metric_statistics(
                    Namespace='AWS/EC2',
                    MetricName='CPUUtilization',
                    Dimensions=[
                        {'Name': 'InstanceId', 'Value': instance_id}
                    ],
                    StartTime=start_time,
                    EndTime=end_time,
                    Period=86400,  # 1 day
                    Statistics=['Average']
                )
                
                if cpu_metrics['Datapoints']:
                    avg_cpu = sum(dp['Average'] for dp in cpu_metrics['Datapoints']) / len(cpu_metrics['Datapoints'])
                    
                    if avg_cpu < 10:
                        optimization['findings'].append(f"Instance {instance_id} ({instance_type}) has low CPU utilization: {avg_cpu:.1f}%")
                        optimization['recommendations'].append(f"Consider downsizing {instance_id} or using Spot instances")
                        
                        # Estimate potential savings (rough calculation)
                        if instance_type.startswith('t3.'):
                            optimization['potential_savings'] += 20  # $20/month for t3.micro -> nano
                    
                    elif avg_cpu > 80:
                        optimization['findings'].append(f"Instance {instance_id} ({instance_type}) has high CPU utilization: {avg_cpu:.1f}%")
                        optimization['recommendations'].append(f"Consider upsizing {instance_id} or adding more instances")
        
        if not optimization['findings']:
            optimization['findings'].append("All instances have appropriate utilization levels")
            
    except Exception as e:
        optimization['findings'].append(f"Error checking instance utilization: {str(e)}")
    
    return optimization

def check_asg_efficiency(autoscaling, cloudwatch, project_name: str, environment: str) -> Dict:
    """Check Auto Scaling Group efficiency and scaling patterns."""
    
    optimization = {
        'category': 'Auto Scaling Group Efficiency',
        'findings': [],
        'recommendations': [],
        'potential_savings': 0
    }
    
    try:
        # Get ASGs for this project
        response = autoscaling.describe_auto_scaling_groups()
        
        for asg in response['AutoScalingGroups']:
            asg_name = asg['AutoScalingGroupName']
            
            # Check if this ASG belongs to our project
            project_tag = next((tag for tag in asg.get('Tags', []) if tag['Key'] == 'Project'), None)
            if not project_tag or project_tag['Value'] != project_name:
                continue
            
            desired = asg['DesiredCapacity']
            min_size = asg['MinSize']
            max_size = asg['MaxSize']
            
            optimization['findings'].append(f"ASG {asg_name}: Desired={desired}, Min={min_size}, Max={max_size}")
            
            # Check if ASG is oversized
            if desired == max_size and max_size > 2:
                optimization['recommendations'].append(f"ASG {asg_name} might be oversized - review max capacity")
            
            # Check scheduled actions
            scheduled_actions = autoscaling.describe_scheduled_actions(
                AutoScalingGroupName=asg_name
            )
            
            if not scheduled_actions['ScheduledUpdateGroupActions']:
                optimization['recommendations'].append(f"Consider adding scheduled scaling to ASG {asg_name} for cost savings")
                optimization['potential_savings'] += 50  # Estimated monthly savings
            else:
                optimization['findings'].append(f"ASG {asg_name} has scheduled scaling configured")
        
    except Exception as e:
        optimization['findings'].append(f"Error checking ASG efficiency: {str(e)}")
    
    return optimization

def optimize_s3_storage(s3, bucket_name: str) -> Dict:
    """Analyze S3 storage and optimize storage classes."""
    
    optimization = {
        'category': 'S3 Storage Optimization',
        'findings': [],
        'recommendations': [],
        'potential_savings': 0
    }
    
    try:
        # Check bucket lifecycle configuration
        try:
            lifecycle = s3.get_bucket_lifecycle_configuration(Bucket=bucket_name)
            optimization['findings'].append(f"Bucket {bucket_name} has {len(lifecycle['Rules'])} lifecycle rules")
        except s3.exceptions.NoSuchLifecycleConfiguration:
            optimization['recommendations'].append(f"Add lifecycle policies to bucket {bucket_name}")
            optimization['potential_savings'] += 30  # Estimated monthly savings
        
        # Analyze storage usage
        response = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=1000)
        
        if 'Contents' in response:
            total_objects = len(response['Contents'])
            total_size = sum(obj['Size'] for obj in response['Contents'])
            
            optimization['findings'].append(f"Bucket contains {total_objects} objects, {total_size / (1024*1024):.1f} MB")
            
            # Check for old objects that could be archived
            old_objects = 0
            for obj in response['Contents']:
                age_days = (datetime.now(obj['LastModified'].tzinfo) - obj['LastModified']).days
                if age_days > 30:
                    old_objects += 1
            
            if old_objects > 0:
                optimization['recommendations'].append(f"{old_objects} objects are older than 30 days - verify lifecycle transitions")
        
    except Exception as e:
        optimization['findings'].append(f"Error analyzing S3 storage: {str(e)}")
    
    return optimization

def check_tagging_compliance(ec2, s3, project_name: str, environment: str) -> Dict:
    """Check resource tagging compliance for cost allocation."""
    
    optimization = {
        'category': 'Tagging Compliance',
        'findings': [],
        'recommendations': [],
        'potential_savings': 0
    }
    
    required_tags = ['Project', 'Environment', 'CostCenter', 'Owner']
    untagged_resources = []
    
    try:
        # Check EC2 instances
        response = ec2.describe_instances()
        
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instance_id = instance['InstanceId']
                tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                
                missing_tags = [tag for tag in required_tags if tag not in tags]
                if missing_tags:
                    untagged_resources.append(f"Instance {instance_id} missing tags: {', '.join(missing_tags)}")
        
        if untagged_resources:
            optimization['findings'].extend(untagged_resources)
            optimization['recommendations'].append("Apply missing cost allocation tags to resources")
        else:
            optimization['findings'].append("All resources have proper cost allocation tags")
        
    except Exception as e:
        optimization['findings'].append(f"Error checking tagging compliance: {str(e)}")
    
    return optimization

def identify_cost_anomalies(cloudwatch, project_name: str, environment: str) -> Dict:
    """Identify potential cost anomalies and optimization opportunities."""
    
    optimization = {
        'category': 'Cost Anomaly Detection',
        'findings': [],
        'recommendations': [],
        'potential_savings': 0
    }
    
    try:
        # This would integrate with AWS Cost Explorer API in a real implementation
        # For demo purposes, we'll simulate some cost analysis
        
        optimization['findings'].append("Simulated cost analysis complete")
        optimization['recommendations'].append("Review AWS Cost Explorer for detailed cost breakdown")
        optimization['recommendations'].append("Set up AWS Budgets for proactive cost monitoring")
        optimization['recommendations'].append("Consider Reserved Instances for predictable workloads")
        
        # Simulate some cost optimization opportunities
        current_time = datetime.utcnow().hour
        if current_time < 8 or current_time > 18:  # Outside business hours
            optimization['findings'].append("Running outside business hours - opportunity for shutdown")
            optimization['potential_savings'] += 25
        
    except Exception as e:
        optimization['findings'].append(f"Error in cost anomaly detection: {str(e)}")
    
    return optimization