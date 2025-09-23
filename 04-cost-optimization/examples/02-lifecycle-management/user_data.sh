#!/bin/bash
yum update -y
yum install -y httpd aws-cli python3 pip3

# Install additional monitoring tools
pip3 install boto3 psutil

# Create the application directory
mkdir -p /opt/lifecycle-demo
cd /opt/lifecycle-demo

# Create a simple web application that demonstrates lifecycle management
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Lifecycle Management Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #17a2b8; color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .lifecycle-rule { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #007bff; }
        .cost-savings { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .automation { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007bff; }
        .metric-label { font-size: 12px; color: #6c757d; }
        .timeline { background: linear-gradient(90deg, #28a745 0%, #ffc107 30%, #fd7e14 60%, #dc3545 100%); height: 20px; border-radius: 10px; margin: 10px 0; }
        .timeline-labels { display: flex; justify-content: space-between; font-size: 12px; margin-top: 5px; }
    </style>
    <script>
        function updateDemoData() {
            // Simulate real-time data updates
            document.getElementById('timestamp').textContent = new Date().toISOString();
            document.getElementById('cpu-usage').textContent = Math.floor(Math.random() * 30 + 10);
            document.getElementById('instances-running').textContent = Math.floor(Math.random() * 3 + 1);
            document.getElementById('s3-objects').textContent = Math.floor(Math.random() * 1000 + 500);
            document.getElementById('cost-savings').textContent = Math.floor(Math.random() * 20 + 45);
        }
        
        setInterval(updateDemoData, 5000);
        window.onload = updateDemoData;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔄 Lifecycle Management Demo</h1>
            <p>Project: ${project_name} | Environment: ${environment}</p>
            <p>Automated Cost Optimization in Action</p>
        </div>

        <div class="section">
            <h2>📊 Real-Time Metrics</h2>
            <div class="metric">
                <div class="metric-value" id="cpu-usage">--</div>
                <div class="metric-label">CPU Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="instances-running">--</div>
                <div class="metric-label">Active Instances</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="s3-objects">--</div>
                <div class="metric-label">S3 Objects</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="cost-savings">--</div>
                <div class="metric-label">Cost Savings %</div>
            </div>
        </div>

        <div class="section">
            <h2>🗄️ S3 Lifecycle Management</h2>
            <p>Automated storage cost optimization through intelligent lifecycle policies:</p>
            
            <div class="timeline"></div>
            <div class="timeline-labels">
                <span>Standard (0-30d)</span>
                <span>Standard-IA (30-60d)</span>
                <span>Glacier (60-180d)</span>
                <span>Deep Archive (180d+)</span>
            </div>
            
            <div class="lifecycle-rule">
                <strong>📁 Current Objects:</strong> Standard → IA (30d) → Glacier (60d) → Deep Archive (180d)
                <br><small>Automatic tiering saves up to 75% on storage costs</small>
            </div>
            
            <div class="lifecycle-rule">
                <strong>📋 Log Files:</strong> Faster archiving with deletion after 1 year
                <br><small>IA (7d) → Glacier (30d) → Deep Archive (90d) → Delete (365d)</small>
            </div>
            
            <div class="lifecycle-rule">
                <strong>🗂️ Temporary Files:</strong> Automatic cleanup after 7 days
                <br><small>Prevents accumulation of unnecessary storage costs</small>
            </div>
            
            <div class="lifecycle-rule">
                <strong>💾 Backup Files:</strong> Long-term retention with immediate IA transition
                <br><small>Cost-optimized backup storage with 7-year retention</small>
            </div>
        </div>

        <div class="section">
            <h2>⚡ Compute Lifecycle Management</h2>
            
            <div class="cost-savings">
                <strong>🕒 Scheduled Scaling:</strong> Automatic scale-down at 6 PM, scale-up at 8 AM (weekdays)
                <br><small>Saves up to 75% on compute costs during off-hours</small>
            </div>
            
            <div class="cost-savings">
                <strong>💰 Spot Instances:</strong> Up to 90% cost savings for fault-tolerant workloads
                <br><small>Automatic fallback to On-Demand if spot capacity unavailable</small>
            </div>
            
            <div class="cost-savings">
                <strong>🔄 Instance Refresh:</strong> Rolling updates with zero downtime
                <br><small>Ensures latest cost-optimized instance types and AMIs</small>
            </div>
            
            <div class="cost-savings">
                <strong>📏 Right-Sizing:</strong> Cost-optimized instance types based on workload
                <br><small>Current: t3.micro instances for development workloads</small>
            </div>
        </div>

        <div class="section">
            <h2>🤖 Automated Cost Optimization</h2>
            
            <div class="automation">
                <strong>🔍 Daily Cost Analysis:</strong> Lambda function runs at 10 PM daily
                <br><small>Identifies unused resources, optimization opportunities, and cost anomalies</small>
            </div>
            
            <div class="automation">
                <strong>🏷️ Tag Compliance:</strong> Ensures all resources have proper cost allocation tags
                <br><small>Enables accurate cost tracking and chargeback reporting</small>
            </div>
            
            <div class="automation">
                <strong>📈 Usage Monitoring:</strong> CloudWatch metrics trigger scaling decisions
                <br><small>Proactive scaling based on actual utilization patterns</small>
            </div>
            
            <div class="automation">
                <strong>💾 Storage Optimization:</strong> Automated S3 storage class transitions
                <br><small>Objects automatically move to cheaper storage classes based on age</small>
            </div>
        </div>

        <div class="section">
            <h2>💡 Cost Optimization Best Practices</h2>
            <ul>
                <li><strong>Storage Tiering:</strong> Automatic movement to cost-effective storage classes</li>
                <li><strong>Compute Scheduling:</strong> Scale resources based on business hours</li>
                <li><strong>Resource Monitoring:</strong> Continuous tracking of utilization metrics</li>
                <li><strong>Automated Cleanup:</strong> Remove temporary files and incomplete uploads</li>
                <li><strong>Spot Instance Usage:</strong> Leverage spare capacity for cost savings</li>
                <li><strong>Lifecycle Automation:</strong> Event-driven cost optimization actions</li>
                <li><strong>Tag-Based Management:</strong> Organize and track costs by project/environment</li>
            </ul>
        </div>

        <div class="section">
            <h2>📋 Demo Information</h2>
            <p><strong>S3 Bucket:</strong> ${bucket_name}</p>
            <p><strong>Project:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Last Updated:</strong> <span id="timestamp"></span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Auto Scaling Group:</strong> <span id="asg-name">Loading...</span></p>
        </div>
    </div>

    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Not available');
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Health Check</title></head>
<body>
    <h1>OK</h1>
    <p>Instance is healthy and running</p>
    <p>Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")</p>
</body>
</html>
EOF

# Create a script to demonstrate S3 lifecycle management
cat > /opt/lifecycle-demo/s3_demo.py << 'EOF'
#!/usr/bin/env python3
import boto3
import json
import time
from datetime import datetime, timezone

def demonstrate_s3_lifecycle():
    s3 = boto3.client('s3')
    bucket_name = '${bucket_name}'
    
    # Create sample objects in different "folders" to demonstrate lifecycle policies
    sample_objects = [
        ('current/document1.txt', 'This is a current document'),
        ('logs/app.log', f'Log entry at {datetime.now()}'),
        ('temp/temporary_file.tmp', 'Temporary data for processing'),
        ('backups/backup-20240101.sql', 'Database backup file'),
    ]
    
    try:
        for key, content in sample_objects:
            s3.put_object(
                Bucket=bucket_name,
                Key=key,
                Body=content,
                Metadata={
                    'created': datetime.now(timezone.utc).isoformat(),
                    'lifecycle-demo': 'true'
                }
            )
            print(f"Created: s3://{bucket_name}/{key}")
        
        print(f"\nObjects created in bucket: {bucket_name}")
        print("These objects will follow the configured lifecycle policies:")
        print("- Current objects: Standard -> IA (30d) -> Glacier (60d) -> Deep Archive (180d)")
        print("- Log files: IA (7d) -> Glacier (30d) -> Deep Archive (90d) -> Delete (365d)")
        print("- Temp files: Delete (7d)")
        print("- Backup files: IA (1d) -> Glacier (7d)")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    demonstrate_s3_lifecycle()
EOF

chmod +x /opt/lifecycle-demo/s3_demo.py

# Create a script to monitor Auto Scaling Group
cat > /opt/lifecycle-demo/asg_monitor.py << 'EOF'
#!/usr/bin/env python3
import boto3
import json
from datetime import datetime

def monitor_asg():
    asg = boto3.client('autoscaling')
    ec2 = boto3.client('ec2')
    
    # Get ASG information
    response = asg.describe_auto_scaling_groups()
    
    for group in response['AutoScalingGroups']:
        if '${project_name}' in group['AutoScalingGroupName']:
            print(f"Auto Scaling Group: {group['AutoScalingGroupName']}")
            print(f"Desired Capacity: {group['DesiredCapacity']}")
            print(f"Min Size: {group['MinSize']}")
            print(f"Max Size: {group['MaxSize']}")
            print(f"Current Instances: {len(group['Instances'])}")
            
            # Get scheduled actions
            scheduled_actions = asg.describe_scheduled_actions(
                AutoScalingGroupName=group['AutoScalingGroupName']
            )
            
            if scheduled_actions['ScheduledUpdateGroupActions']:
                print("\nScheduled Actions:")
                for action in scheduled_actions['ScheduledUpdateGroupActions']:
                    print(f"- {action['ScheduledActionName']}: {action.get('Recurrence', 'One-time')}")
            
            print(f"\nLast Activity: {datetime.now()}")
            break

if __name__ == "__main__":
    monitor_asg()
EOF

chmod +x /opt/lifecycle-demo/asg_monitor.py

# Run the S3 demo script
python3 /opt/lifecycle-demo/s3_demo.py

# Create a cron job to periodically run monitoring scripts
(crontab -l 2>/dev/null; echo "*/15 * * * * python3 /opt/lifecycle-demo/asg_monitor.py >> /var/log/lifecycle-demo.log 2>&1") | crontab -

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Create a systemd service for lifecycle monitoring
cat > /etc/systemd/system/lifecycle-monitor.service << 'EOF'
[Unit]
Description=Lifecycle Management Monitor
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/lifecycle-demo
ExecStart=/usr/bin/python3 /opt/lifecycle-demo/asg_monitor.py
Restart=always
RestartSec=300

[Install]
WantedBy=multi-user.target
EOF

systemctl enable lifecycle-monitor
systemctl start lifecycle-monitor

# Log the deployment
echo "$(date): Lifecycle management demo deployed successfully" >> /var/log/deployment.log
echo "S3 Bucket: ${bucket_name}" >> /var/log/deployment.log
echo "Project: ${project_name}, Environment: ${environment}" >> /var/log/deployment.log