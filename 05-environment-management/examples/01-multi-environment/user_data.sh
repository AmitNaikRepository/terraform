#!/bin/bash
yum update -y
yum install -y httpd aws-cli nodejs npm

# Install CloudWatch agent if monitoring is enabled
if [ "${monitoring_enabled}" = "true" ]; then
    yum install -y amazon-cloudwatch-agent
fi

# Create application directory
mkdir -p /opt/multi-env-demo
cd /opt/multi-env-demo

# Create environment-specific web application
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Multi-Environment Demo - ${environment} Environment</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { 
            padding: 20px; 
            border-radius: 8px; 
            text-align: center; 
            color: white; 
            background: ${environment == 'prod' ? '#dc3545' : (environment == 'staging' ? '#ffc107' : '#28a745')}; 
        }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .env-info { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #007bff; }
        .config { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .warning { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        .success { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .danger { background: #f8d7da; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #dc3545; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007bff; }
        .metric-label { font-size: 12px; color: #6c757d; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .badge { display: inline-block; padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; margin: 2px; }
        .badge-dev { background: #28a745; color: white; }
        .badge-staging { background: #ffc107; color: black; }
        .badge-prod { background: #dc3545; color: white; }
    </style>
    <script>
        function updateMetrics() {
            document.getElementById('timestamp').textContent = new Date().toISOString();
            
            // Environment-specific metrics simulation
            const env = '${environment}';
            let cpu, memory, requests, responseTime;
            
            if (env === 'dev') {
                cpu = Math.floor(Math.random() * 20 + 10); // 10-30%
                memory = Math.floor(Math.random() * 30 + 20); // 20-50%
                requests = Math.floor(Math.random() * 50 + 10); // 10-60 req/min
                responseTime = Math.floor(Math.random() * 100 + 50); // 50-150ms
            } else if (env === 'staging') {
                cpu = Math.floor(Math.random() * 30 + 20); // 20-50%
                memory = Math.floor(Math.random() * 40 + 30); // 30-70%
                requests = Math.floor(Math.random() * 200 + 100); // 100-300 req/min
                responseTime = Math.floor(Math.random() * 80 + 40); // 40-120ms
            } else { // prod
                cpu = Math.floor(Math.random() * 40 + 30); // 30-70%
                memory = Math.floor(Math.random() * 50 + 40); // 40-90%
                requests = Math.floor(Math.random() * 1000 + 500); // 500-1500 req/min
                responseTime = Math.floor(Math.random() * 60 + 30); // 30-90ms
            }
            
            document.getElementById('cpu-usage').textContent = cpu;
            document.getElementById('memory-usage').textContent = memory;
            document.getElementById('requests-per-min').textContent = requests;
            document.getElementById('response-time').textContent = responseTime;
        }
        
        setInterval(updateMetrics, 5000);
        window.onload = updateMetrics;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌍 Multi-Environment Demo</h1>
            <h2>${environment.upper()} Environment</h2>
            <p>Project: ${project_name} | Instance: ${instance_type}</p>
        </div>

        <div class="section">
            <h2>📊 Environment Metrics</h2>
            
            <div class="metric">
                <div class="metric-value" id="cpu-usage">--</div>
                <div class="metric-label">CPU Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="memory-usage">--</div>
                <div class="metric-label">Memory Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="requests-per-min">--</div>
                <div class="metric-label">Requests/Min</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="response-time">--</div>
                <div class="metric-label">Response Time (ms)</div>
            </div>
        </div>

        <div class="section">
            <h2>🏗️ Environment Configuration</h2>
            
            <div class="env-info">
                <strong>Environment:</strong> <span class="badge badge-${environment}">${environment.upper()}</span>
                <br><strong>Instance Type:</strong> ${instance_type}
                <br><strong>Monitoring:</strong> ${monitoring_enabled ? 'Enhanced' : 'Basic'}
                <br><strong>Backup:</strong> ${backup_enabled ? 'Enabled' : 'Disabled'}
                <br><strong>Retention:</strong> ${retention_days} days
            </div>
            
            ${environment == 'dev' ? '<div class="success"><strong>✅ Development Optimizations:</strong><br>• Cost-optimized with single AZ<br>• No NAT Gateway to reduce costs<br>• SSH access enabled for debugging<br>• Basic monitoring only<br>• No automated backups</div>' : ''}
            
            ${environment == 'staging' ? '<div class="warning"><strong>⚖️ Staging Balance:</strong><br>• Production-like setup with smaller scale<br>• Multi-AZ for availability testing<br>• Enhanced monitoring enabled<br>• 30-day backup retention<br>• Pre-production validation environment</div>' : ''}
            
            ${environment == 'prod' ? '<div class="danger"><strong>🛡️ Production Security:</strong><br>• High availability with Multi-AZ<br>• Full monitoring and logging<br>• 90-day backup retention<br>• Deletion protection enabled<br>• SSH access disabled</div>' : ''}
        </div>

        <div class="section">
            <h2>🔧 Infrastructure Components</h2>
            
            <div class="config">
                <strong>Network Architecture:</strong>
                <ul>
                    <li><strong>VPC CIDR:</strong> ${environment == 'prod' ? '10.0.0.0/16' : (environment == 'staging' ? '10.1.0.0/16' : '10.2.0.0/16')}</li>
                    <li><strong>Multi-AZ:</strong> ${environment != 'dev' ? 'Enabled' : 'Disabled (cost optimization)'}</li>
                    <li><strong>NAT Gateway:</strong> ${environment != 'dev' ? 'Enabled' : 'Disabled (cost optimization)'}</li>
                    <li><strong>SSL Policy:</strong> ${environment == 'prod' ? 'TLS 1.2+' : (environment == 'staging' ? 'TLS 1.2+' : 'Basic')}</li>
                </ul>
            </div>
            
            <div class="config">
                <strong>Auto Scaling Configuration:</strong>
                <ul>
                    <li><strong>Min Size:</strong> ${environment == 'prod' ? '3' : (environment == 'staging' ? '2' : '1')} instances</li>
                    <li><strong>Max Size:</strong> ${environment == 'prod' ? '10' : (environment == 'staging' ? '4' : '2')} instances</li>
                    <li><strong>Instance Type:</strong> ${instance_type}</li>
                    <li><strong>Health Checks:</strong> ${environment == 'prod' ? 'Strict (15s interval)' : 'Standard (30s interval)'}</li>
                </ul>
            </div>
            
            <div class="config">
                <strong>Database Configuration:</strong>
                <ul>
                    <li><strong>Instance Class:</strong> ${environment == 'prod' ? 'db.t3.medium' : (environment == 'staging' ? 'db.t3.small' : 'db.t3.micro')}</li>
                    <li><strong>Multi-AZ:</strong> ${environment != 'dev' ? 'Yes' : 'No'}</li>
                    <li><strong>Backup Retention:</strong> ${retention_days} days</li>
                    <li><strong>Encryption:</strong> ${environment == 'prod' ? 'Enabled' : 'Disabled'}</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>📈 Monitoring and Observability</h2>
            
            ${monitoring_enabled ? 
                '<div class="success"><strong>✅ Enhanced Monitoring Enabled:</strong><br>• CloudWatch detailed monitoring<br>• ALB access logs<br>• RDS performance insights<br>• Custom application metrics<br>• Automated alerting</div>' : 
                '<div class="warning"><strong>⚠️ Basic Monitoring:</strong><br>• Standard CloudWatch metrics<br>• Basic health checks<br>• Manual log review<br>• Cost-optimized approach</div>'
            }
            
            <div class="config">
                <strong>Log Management:</strong>
                <ul>
                    <li><strong>Application Logs:</strong> /aws/application/${project_name}-${environment}</li>
                    <li><strong>Retention Period:</strong> ${retention_days} days</li>
                    <li><strong>Access Logs:</strong> ${monitoring_enabled ? 'S3 bucket' : 'Disabled'}</li>
                    <li><strong>Database Logs:</strong> ${monitoring_enabled ? 'CloudWatch' : 'Local only'}</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>🔐 Security Configuration</h2>
            
            <div class="config">
                <strong>Access Control:</strong>
                <ul>
                    <li><strong>SSH Access:</strong> ${environment == 'prod' ? 'Disabled (security)' : 'Enabled (development)'}</li>
                    <li><strong>Database Access:</strong> Private subnets only</li>
                    <li><strong>HTTPS:</strong> Enforced with SSL certificate</li>
                    <li><strong>Security Groups:</strong> Principle of least privilege</li>
                </ul>
            </div>
            
            <div class="config">
                <strong>Data Protection:</strong>
                <ul>
                    <li><strong>EBS Encryption:</strong> ${environment == 'prod' ? 'Enabled' : 'Disabled'}</li>
                    <li><strong>RDS Encryption:</strong> ${environment == 'prod' ? 'Enabled' : 'Disabled'}</li>
                    <li><strong>Deletion Protection:</strong> ${environment == 'prod' ? 'Enabled' : 'Disabled'}</li>
                    <li><strong>Backup Encryption:</strong> ${environment == 'prod' ? 'Enabled' : 'Disabled'}</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>💰 Cost Optimization Strategy</h2>
            
            <div class="config">
                <strong>Environment-Specific Optimizations:</strong>
                <ul>
                    ${environment == 'dev' ? 
                        '<li>Single AZ deployment reduces NAT costs</li><li>No enhanced monitoring saves ~$20/month</li><li>No backups reduce storage costs</li><li>t3.micro instances minimize compute costs</li>' :
                        environment == 'staging' ?
                        '<li>Balanced approach: production features at smaller scale</li><li>Multi-AZ for testing but moderate retention</li><li>t3.small instances for realistic testing</li>' :
                        '<li>Optimized for reliability over cost</li><li>Multi-AZ for high availability</li><li>Enhanced monitoring for operational visibility</li><li>Long retention for compliance</li>'
                    }
                </ul>
            </div>
            
            <div class="env-info">
                <strong>Estimated Monthly Cost:</strong> 
                ${environment == 'dev' ? '$50-80 (cost optimized)' : 
                  environment == 'staging' ? '$150-200 (balanced)' : 
                  '$300-500 (reliability focused)'}
            </div>
        </div>

        <div class="section">
            <h2>🚀 Environment Promotion</h2>
            
            <div class="config">
                <strong>Promotion Path:</strong>
                <div style="text-align: center; margin: 20px 0;">
                    <span class="badge badge-dev">DEV</span> → 
                    <span class="badge badge-staging">STAGING</span> → 
                    <span class="badge badge-prod">PROD</span>
                </div>
                
                <ul>
                    <li><strong>Development:</strong> Feature development and unit testing</li>
                    <li><strong>Staging:</strong> Integration testing and performance validation</li>
                    <li><strong>Production:</strong> Live customer-facing environment</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>📋 Environment Details</h2>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Project:</strong> ${project_name}</p>
            <p><strong>Instance Type:</strong> ${instance_type}</p>
            <p><strong>Application Port:</strong> ${app_port}</p>
            <p><strong>Last Updated:</strong> <span id="timestamp"></span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="availability-zone">Loading...</span></p>
        </div>
    </div>

    <script>
        // Fetch instance metadata
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Not available');
            
        fetch('http://169.254.169.254/latest/meta-data/placement/availability-zone')
            .then(response => response.text())
            .then(data => document.getElementById('availability-zone').textContent = data)
            .catch(() => document.getElementById('availability-zone').textContent = 'Not available');
    </script>
</body>
</html>
EOF

# Create health check endpoint
cat > /var/www/html/health << 'EOF'
{
  "status": "healthy",
  "environment": "${environment}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "instance_type": "${instance_type}",
  "monitoring": "${monitoring_enabled}",
  "backup": "${backup_enabled}"
}
EOF

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Configure CloudWatch agent if monitoring is enabled
if [ "${monitoring_enabled}" = "true" ]; then
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "metrics": {
        "namespace": "MultiEnvironmentDemo/${environment.upper()}",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            },
            "netstat": {
                "measurement": [
                    "tcp_established",
                    "tcp_time_wait"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/access_log",
                        "log_group_name": "/aws/application/${project_name}-${environment}",
                        "log_stream_name": "apache-access",
                        "timezone": "UTC"
                    },
                    {
                        "file_path": "/var/log/httpd/error_log",
                        "log_group_name": "/aws/application/${project_name}-${environment}",
                        "log_stream_name": "apache-error",
                        "timezone": "UTC"
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
fi

# Create environment-specific monitoring script
cat > /opt/environment_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/environment-monitor.log"
ENVIRONMENT="${environment}"

while true; do
    # Get system metrics
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # Get application-specific metrics
    HTTPD_PROCESSES=$(pgrep httpd | wc -l)
    CONNECTIONS=$(netstat -an | grep :80 | grep ESTABLISHED | wc -l)
    
    # Log metrics with environment context
    echo "$(date): ENV=$ENVIRONMENT, CPU=${CPU_USAGE}%, MEM=${MEM_USAGE}%, DISK=${DISK_USAGE}%, LOAD=${LOAD_AVG}, HTTPD=${HTTPD_PROCESSES}, CONN=${CONNECTIONS}" >> $LOG_FILE
    
    # Environment-specific alerting logic
    if [ "$ENVIRONMENT" = "prod" ]; then
        # Production: strict thresholds
        if (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
            echo "$(date): PROD ALERT: High CPU usage (${CPU_USAGE}%) - immediate attention required" >> $LOG_FILE
        fi
        if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
            echo "$(date): PROD ALERT: High memory usage (${MEM_USAGE}%) - scale up recommended" >> $LOG_FILE
        fi
    elif [ "$ENVIRONMENT" = "staging" ]; then
        # Staging: moderate thresholds
        if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
            echo "$(date): STAGING ALERT: High CPU usage (${CPU_USAGE}%) - investigate load patterns" >> $LOG_FILE
        fi
    else
        # Dev: lenient thresholds, focus on cost
        if (( $(echo "$CPU_USAGE < 5" | bc -l) )); then
            echo "$(date): DEV INFO: Very low CPU usage (${CPU_USAGE}%) - consider downsizing" >> $LOG_FILE
        fi
    fi
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/environment_monitor.sh

# Start monitoring script in background
nohup /opt/environment_monitor.sh &

# Create environment-specific cron jobs
if [ "${backup_enabled}" = "true" ]; then
    # Add backup verification job for environments with backups
    (crontab -l 2>/dev/null; echo "0 6 * * * /opt/verify_backups.sh >> /var/log/backup-verify.log 2>&1") | crontab -
fi

# Log the deployment with environment context
echo "$(date): Multi-environment demo deployed successfully" >> /var/log/deployment.log
echo "Environment: ${environment}" >> /var/log/deployment.log
echo "Instance Type: ${instance_type}" >> /var/log/deployment.log
echo "Monitoring Enabled: ${monitoring_enabled}" >> /var/log/deployment.log
echo "Backup Enabled: ${backup_enabled}" >> /var/log/deployment.log
echo "Retention Days: ${retention_days}" >> /var/log/deployment.log