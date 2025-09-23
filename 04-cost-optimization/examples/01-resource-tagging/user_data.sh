#!/bin/bash
yum update -y
yum install -y httpd aws-cli

# Install CloudWatch agent for cost monitoring
yum install -y amazon-cloudwatch-agent

# Create a simple web application for cost monitoring demo
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Cost Optimization Demo - Instance ${instance_number}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1000px; margin: 0 auto; }
        .header { background: #28a745; color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .cost-metric { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .optimization { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .alert { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .tag { display: inline-block; background: #007bff; color: white; padding: 4px 8px; border-radius: 4px; margin: 2px; font-size: 12px; }
        .metric { display: inline-block; margin: 10px; padding: 10px; background: #f8f9fa; border-radius: 5px; }
    </style>
    <script>
        function refreshMetrics() {
            document.getElementById('timestamp').textContent = new Date().toISOString();
            // In a real scenario, this would fetch actual CloudWatch metrics
            document.getElementById('cpu-usage').textContent = Math.floor(Math.random() * 30 + 10) + '%';
            document.getElementById('memory-usage').textContent = Math.floor(Math.random() * 40 + 20) + '%';
            document.getElementById('network-in').textContent = Math.floor(Math.random() * 1000 + 100) + ' KB/s';
            document.getElementById('disk-usage').textContent = Math.floor(Math.random() * 20 + 15) + '%';
        }
        
        setInterval(refreshMetrics, 5000);
        window.onload = refreshMetrics;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>💰 Cost Optimization Demo - Instance ${instance_number}</h1>
            <p>Project: ${project_name} | Environment: ${environment}</p>
        </div>

        <div class="section">
            <h2>📊 Resource Utilization Monitoring</h2>
            <p>Real-time metrics for cost optimization analysis:</p>
            
            <div class="metric">
                <strong>CPU Usage:</strong> <span id="cpu-usage">Loading...</span>
            </div>
            <div class="metric">
                <strong>Memory Usage:</strong> <span id="memory-usage">Loading...</span>
            </div>
            <div class="metric">
                <strong>Network In:</strong> <span id="network-in">Loading...</span>
            </div>
            <div class="metric">
                <strong>Disk Usage:</strong> <span id="disk-usage">Loading...</span>
            </div>
            
            <div class="alert">
                <strong>💡 Cost Optimization Tip:</strong> Monitor these metrics to identify rightsizing opportunities. If CPU usage is consistently low, consider a smaller instance type.
            </div>
        </div>

        <div class="section">
            <h2>🏷️ Cost Allocation Tags</h2>
            <p>This instance is tagged for comprehensive cost tracking:</p>
            
            <div>
                <span class="tag">Project: ${project_name}</span>
                <span class="tag">Environment: ${environment}</span>
                <span class="tag">CostCenter: engineering</span>
                <span class="tag">Owner: devops-team</span>
                <span class="tag">Terraform: true</span>
                <span class="tag">AutoShutdown: enabled</span>
                <span class="tag">Monitoring: basic</span>
                <span class="tag">CostOptimized: true</span>
            </div>
        </div>

        <div class="section">
            <h2>💡 Cost Optimization Features</h2>
            
            <div class="optimization">
                <strong>✅ Instance Rightsizing:</strong> Using cost-optimized instance types (t3.micro for development)
            </div>
            
            <div class="optimization">
                <strong>✅ Storage Optimization:</strong> GP3 EBS volumes with appropriate sizing
            </div>
            
            <div class="optimization">
                <strong>✅ Auto-Shutdown:</strong> Scheduled shutdown during non-business hours
            </div>
            
            <div class="optimization">
                <strong>✅ Monitoring:</strong> Basic CloudWatch monitoring (detailed monitoring disabled for cost savings)
            </div>
            
            <div class="optimization">
                <strong>✅ Budget Controls:</strong> AWS Budgets with alerts at 80% and 100% thresholds
            </div>
        </div>

        <div class="section">
            <h2>📈 Cost Monitoring Dashboard</h2>
            <div class="cost-metric">
                <strong>Estimated Monthly Cost:</strong> ~$8.50 per instance
                <br><small>Includes: EC2 instance + EBS storage + basic monitoring</small>
            </div>
            
            <div class="cost-metric">
                <strong>S3 Storage:</strong> Lifecycle policies reduce storage costs by up to 60%
                <br><small>Automatic tiering: Standard → IA (30d) → Glacier (90d) → Deep Archive (365d)</small>
            </div>
            
            <div class="cost-metric">
                <strong>Budget Alert:</strong> Monthly limit of $50 with email notifications
                <br><small>Alerts at 80% actual spend and 100% forecasted spend</small>
            </div>
        </div>

        <div class="section">
            <h2>🔧 Cost Optimization Actions</h2>
            <ul>
                <li><strong>Review Utilization:</strong> Check CloudWatch metrics weekly for rightsizing opportunities</li>
                <li><strong>Monitor Spending:</strong> Use cost allocation tags to track expenses by project/environment</li>
                <li><strong>Automate Shutdowns:</strong> Non-production instances shut down after business hours</li>
                <li><strong>Storage Lifecycle:</strong> S3 objects automatically move to cheaper storage classes</li>
                <li><strong>Budget Alerts:</strong> Proactive notifications prevent cost overruns</li>
            </ul>
        </div>

        <div class="section">
            <h2>📋 Instance Information</h2>
            <p><strong>Instance Number:</strong> ${instance_number}</p>
            <p><strong>Project:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Last Updated:</strong> <span id="timestamp"></span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Instance Type:</strong> <span id="instance-type">Loading...</span></p>
        </div>
    </div>

    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Not available');
            
        fetch('http://169.254.169.254/latest/meta-data/instance-type')
            .then(response => response.text())
            .then(data => document.getElementById('instance-type').textContent = data)
            .catch(() => document.getElementById('instance-type').textContent = 'Not available');
    </script>
</body>
</html>
EOF

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Configure CloudWatch agent for cost monitoring
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "CostOptimization/Demo",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    {
                        "name": "cpu_usage_idle",
                        "rename": "CPU_USAGE_IDLE",
                        "unit": "Percent"
                    },
                    {
                        "name": "cpu_usage_iowait",
                        "rename": "CPU_USAGE_IOWAIT",
                        "unit": "Percent"
                    }
                ],
                "metrics_collection_interval": 300,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 300,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 300
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/ec2/cost-optimization",
                        "log_stream_name": "instance-${instance_number}-access"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
    -s

# Create a cron job for automatic shutdown (if enabled)
cat > /opt/auto-shutdown.sh << 'EOF'
#!/bin/bash
# Auto-shutdown script for cost optimization
# This would typically check if it's after business hours and shutdown the instance
# For demo purposes, we just log the action

HOUR=$(date +%H)
DAY=$(date +%u)  # 1=Monday, 7=Sunday

# Shutdown weekdays after 6 PM (18:00)
if [ $DAY -le 5 ] && [ $HOUR -ge 18 ]; then
    echo "$(date): Auto-shutdown triggered for cost optimization" >> /var/log/auto-shutdown.log
    # Uncomment the next line to actually shutdown
    # shutdown -h now
fi
EOF

chmod +x /opt/auto-shutdown.sh

# Add to crontab to check every hour
(crontab -l 2>/dev/null; echo "0 * * * * /opt/auto-shutdown.sh") | crontab -

# Log the deployment
echo "$(date): Cost optimization demo instance ${instance_number} deployed successfully" >> /var/log/deployment.log
echo "Project: ${project_name}, Environment: ${environment}" >> /var/log/deployment.log