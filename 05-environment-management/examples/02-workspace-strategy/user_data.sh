#!/bin/bash
yum update -y
yum install -y httpd aws-cli jq

# Create application directory
mkdir -p /opt/workspace-demo
cd /opt/workspace-demo

# Create workspace-aware web application
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Workspace Strategy Demo - ${workspace} Workspace</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { 
            padding: 20px; 
            border-radius: 8px; 
            text-align: center; 
            color: white;
            background: ${workspace == 'prod' ? '#dc3545' : 
                        workspace == 'staging' ? '#ffc107' : 
                        workspace == 'test' ? '#6f42c1' : '#28a745'};
        }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .workspace-info { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #007bff; }
        .command { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; font-family: monospace; border-left: 4px solid #6c757d; }
        .success { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .warning { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        .danger { background: #f8d7da; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #dc3545; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007bff; }
        .metric-label { font-size: 12px; color: #6c757d; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .workspace-badge { display: inline-block; padding: 8px 16px; border-radius: 20px; font-size: 14px; font-weight: bold; margin: 5px; }
        .badge-default { background: #28a745; color: white; }
        .badge-dev { background: #28a745; color: white; }
        .badge-staging { background: #ffc107; color: black; }
        .badge-prod { background: #dc3545; color: white; }
        .badge-test { background: #6f42c1; color: white; }
        .state-path { background: #e9ecef; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; }
    </style>
    <script>
        function updateMetrics() {
            document.getElementById('timestamp').textContent = new Date().toISOString();
            
            // Workspace-specific metrics
            const workspace = '${workspace}';
            let cpu, memory, requests, instances;
            
            switch(workspace) {
                case 'prod':
                    cpu = Math.floor(Math.random() * 40 + 30); // 30-70%
                    memory = Math.floor(Math.random() * 50 + 40); // 40-90%
                    requests = Math.floor(Math.random() * 1000 + 500); // 500-1500
                    instances = Math.floor(Math.random() * 3 + 3); // 3-6
                    break;
                case 'staging':
                    cpu = Math.floor(Math.random() * 30 + 20); // 20-50%
                    memory = Math.floor(Math.random() * 40 + 30); // 30-70%
                    requests = Math.floor(Math.random() * 200 + 100); // 100-300
                    instances = Math.floor(Math.random() * 2 + 2); // 2-4
                    break;
                case 'test':
                    cpu = Math.floor(Math.random() * 15 + 5); // 5-20%
                    memory = Math.floor(Math.random() * 20 + 15); // 15-35%
                    requests = Math.floor(Math.random() * 20 + 5); // 5-25
                    instances = 1;
                    break;
                default: // dev or default
                    cpu = Math.floor(Math.random() * 20 + 10); // 10-30%
                    memory = Math.floor(Math.random() * 30 + 20); // 20-50%
                    requests = Math.floor(Math.random() * 50 + 10); // 10-60
                    instances = Math.floor(Math.random() * 1 + 1); // 1-2
            }
            
            document.getElementById('cpu-usage').textContent = cpu;
            document.getElementById('memory-usage').textContent = memory;
            document.getElementById('requests-per-min').textContent = requests;
            document.getElementById('active-instances').textContent = instances;
        }
        
        function showWorkspaceCommands(action) {
            const commands = {
                create: [
                    'terraform workspace new dev',
                    'terraform workspace new staging', 
                    'terraform workspace new prod',
                    'terraform workspace new test'
                ],
                switch: [
                    'terraform workspace select dev',
                    'terraform workspace select staging',
                    'terraform workspace select prod',
                    'terraform workspace select default'
                ],
                deploy: [
                    'terraform workspace select <workspace>',
                    'terraform plan',
                    'terraform apply'
                ]
            };
            
            const resultDiv = document.getElementById('command-result');
            resultDiv.innerHTML = '<strong>' + action.toUpperCase() + ' Commands:</strong><br>' + 
                                commands[action].map(cmd => '<code>' + cmd + '</code>').join('<br>');
        }
        
        setInterval(updateMetrics, 5000);
        window.onload = updateMetrics;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🌐 Terraform Workspace Strategy</h1>
            <h2>${workspace.upper()} Workspace</h2>
            <p>Environment: ${environment} | Project: ${project_name}</p>
        </div>

        <div class="section">
            <h2>📊 Workspace Metrics</h2>
            
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
                <div class="metric-value" id="active-instances">--</div>
                <div class="metric-label">Active Instances</div>
            </div>
        </div>

        <div class="section">
            <h2>🏷️ Current Workspace Details</h2>
            
            <div class="workspace-info">
                <strong>Workspace:</strong> <span class="workspace-badge badge-${workspace}">${workspace.upper()}</span>
                <br><strong>Environment:</strong> ${environment}
                <br><strong>VPC CIDR:</strong> ${vpc_cidr}
                <br><strong>Instance Type:</strong> ${instance_type}
                <br><strong>Monitoring:</strong> ${monitoring_enabled ? 'Enhanced' : 'Basic'}
            </div>

            <div class="workspace-info">
                <strong>State Management:</strong>
                <div class="state-path">
                    State Key: workspace-strategy/env:/${workspace}/terraform.tfstate
                </div>
                <small>Each workspace maintains completely isolated state</small>
            </div>
        </div>

        <div class="section">
            <h2>🔄 Workspace Strategy Overview</h2>
            
            <div class="success">
                <strong>✅ Workspace Benefits:</strong>
                <ul>
                    <li><strong>State Isolation:</strong> Each workspace has separate state files</li>
                    <li><strong>Resource Isolation:</strong> No conflicts between environments</li>
                    <li><strong>Consistent Configuration:</strong> Same Terraform code across environments</li>
                    <li><strong>Easy Switching:</strong> <code>terraform workspace select &lt;name&gt;</code></li>
                </ul>
            </div>

            <div class="workspace-info">
                <strong>Available Workspaces:</strong>
                <div style="margin: 10px 0;">
                    <span class="workspace-badge badge-default">DEFAULT</span>
                    <span class="workspace-badge badge-dev">DEV</span>
                    <span class="workspace-badge badge-staging">STAGING</span>
                    <span class="workspace-badge badge-prod">PROD</span>
                    <span class="workspace-badge badge-test">TEST</span>
                </div>
                <small>Each workspace deploys to isolated infrastructure</small>
            </div>
        </div>

        <div class="section">
            <h2>⚙️ Workspace Configuration Matrix</h2>
            
            <table style="width: 100%; border-collapse: collapse;">
                <tr style="background: #f8f9fa;">
                    <th style="padding: 10px; border: 1px solid #dee2e6;">Workspace</th>
                    <th style="padding: 10px; border: 1px solid #dee2e6;">Instance Type</th>
                    <th style="padding: 10px; border: 1px solid #dee2e6;">Scaling</th>
                    <th style="padding: 10px; border: 1px solid #dee2e6;">Multi-AZ</th>
                    <th style="padding: 10px; border: 1px solid #dee2e6;">NAT Gateway</th>
                    <th style="padding: 10px; border: 1px solid #dee2e6;">Monitoring</th>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #dee2e6;"><span class="workspace-badge badge-default">DEFAULT</span></td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">t3.micro</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">1-2</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">❌</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">❌</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">Basic</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #dee2e6;"><span class="workspace-badge badge-dev">DEV</span></td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">t3.micro</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">1-2</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">❌</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">❌</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">Basic</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #dee2e6;"><span class="workspace-badge badge-staging">STAGING</span></td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">t3.small</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">2-4</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">✅</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">✅</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">Enhanced</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #dee2e6;"><span class="workspace-badge badge-prod">PROD</span></td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">t3.medium</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">3-10</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">✅</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">✅</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">Full</td>
                </tr>
                <tr>
                    <td style="padding: 8px; border: 1px solid #dee2e6;"><span class="workspace-badge badge-test">TEST</span></td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">t3.micro</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">1</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">❌</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">❌</td>
                    <td style="padding: 8px; border: 1px solid #dee2e6;">Basic</td>
                </tr>
            </table>
        </div>

        <div class="section">
            <h2>💻 Workspace Management Commands</h2>
            
            <div style="text-align: center; margin: 20px 0;">
                <button onclick="showWorkspaceCommands('create')" style="background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; margin: 5px;">Create Workspaces</button>
                <button onclick="showWorkspaceCommands('switch')" style="background: #28a745; color: white; padding: 10px 20px; border: none; border-radius: 4px; margin: 5px;">Switch Workspaces</button>
                <button onclick="showWorkspaceCommands('deploy')" style="background: #ffc107; color: black; padding: 10px 20px; border: none; border-radius: 4px; margin: 5px;">Deploy Workflow</button>
            </div>
            
            <div class="command" id="command-result">
                Click buttons above to see workspace management commands
            </div>

            <div class="workspace-info">
                <strong>Current Status:</strong>
                <div class="command">
                    terraform workspace show → ${workspace}
                    <br>terraform workspace list → * ${workspace} (+ other workspaces)
                </div>
            </div>
        </div>

        <div class="section">
            <h2>🔒 State Management & Security</h2>
            
            <div class="success">
                <strong>✅ State Isolation Benefits:</strong>
                <ul>
                    <li><strong>Complete Separation:</strong> Each workspace has its own state file</li>
                    <li><strong>No Cross-Contamination:</strong> Changes in one workspace don't affect others</li>
                    <li><strong>Concurrent Development:</strong> Teams can work on different environments simultaneously</li>
                    <li><strong>Rollback Safety:</strong> Environment-specific state history</li>
                </ul>
            </div>

            <div class="workspace-info">
                <strong>State File Location:</strong>
                <div class="state-path">
                    S3 Key: workspace-strategy/env:/${workspace}/terraform.tfstate
                    <br>DynamoDB Lock: workspace-strategy/env:/${workspace}/terraform.tfstate
                </div>
            </div>

            ${workspace == 'prod' ? 
                '<div class="danger"><strong>🛡️ Production Protections:</strong><br>• Deletion protection enabled<br>• Instance scale-in protection<br>• SSH access disabled<br>• Enhanced monitoring and logging<br>• Encrypted storage</div>' :
                workspace == 'staging' ? 
                '<div class="warning"><strong>⚖️ Staging Features:</strong><br>• Production-like setup<br>• Enhanced monitoring for testing<br>• Multi-AZ for availability validation<br>• SSH access for debugging</div>' :
                '<div class="success"><strong>💡 Development Features:</strong><br>• Cost-optimized configuration<br>• SSH access enabled<br>• Single AZ deployment<br>• Basic monitoring<br>• Fast iteration cycles</div>'
            }
        </div>

        <div class="section">
            <h2>🚀 Deployment Workflow</h2>
            
            <div class="workspace-info">
                <strong>Environment Promotion Path:</strong>
                <div style="text-align: center; margin: 20px 0; font-size: 18px;">
                    <span class="workspace-badge badge-dev">DEV</span> →
                    <span class="workspace-badge badge-staging">STAGING</span> →
                    <span class="workspace-badge badge-prod">PROD</span>
                </div>
            </div>

            <div class="command">
                <strong>Typical Deployment Flow:</strong>
                <br>1. terraform workspace select dev
                <br>2. terraform plan && terraform apply
                <br>3. # Test and validate changes
                <br>4. terraform workspace select staging  
                <br>5. terraform plan && terraform apply
                <br>6. # Integration testing
                <br>7. terraform workspace select prod
                <br>8. terraform plan && terraform apply
            </div>

            <div class="success">
                <strong>✅ Best Practices:</strong>
                <ul>
                    <li>Always verify current workspace before applying changes</li>
                    <li>Use consistent naming conventions across workspaces</li>
                    <li>Implement workspace-specific validation rules</li>
                    <li>Tag resources with workspace information</li>
                    <li>Use workspace-aware CIDR blocks to prevent conflicts</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>💰 Cost Optimization by Workspace</h2>
            
            <div class="workspace-info">
                <strong>Current Workspace Cost Estimate:</strong>
                <div style="font-size: 18px; font-weight: bold; margin: 10px 0;">
                    ${workspace == 'prod' ? '$200-400/month' :
                      workspace == 'staging' ? '$100-200/month' :
                      workspace == 'test' ? '$20-40/month' : '$50-100/month'}
                </div>
                <small>Estimate includes compute, storage, networking, and monitoring costs</small>
            </div>

            <div class="success">
                <strong>💡 Cost Optimization Strategies:</strong>
                <ul>
                    <li><strong>Dev/Test:</strong> Single AZ, no NAT Gateway, basic monitoring</li>
                    <li><strong>Staging:</strong> Production-like features with smaller scale</li>
                    <li><strong>Production:</strong> Full redundancy and monitoring for reliability</li>
                    <li><strong>Workspace Cleanup:</strong> Easy to destroy entire environments when not needed</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>📋 Workspace Information</h2>
            <p><strong>Current Workspace:</strong> ${workspace}</p>
            <p><strong>Resolved Environment:</strong> ${environment}</p>
            <p><strong>Project Name:</strong> ${project_name}</p>
            <p><strong>VPC CIDR:</strong> ${vpc_cidr}</p>
            <p><strong>Instance Type:</strong> ${instance_type}</p>
            <p><strong>S3 Bucket:</strong> ${bucket_name}</p>
            <p><strong>Last Updated:</strong> <span id="timestamp"></span></p>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
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

# Create health check endpoint with workspace information
cat > /var/www/html/health << EOF
{
  "status": "healthy",
  "workspace": "${workspace}",
  "environment": "${environment}",
  "project": "${project_name}",
  "instance_type": "${instance_type}",
  "vpc_cidr": "${vpc_cidr}",
  "monitoring": "${monitoring_enabled}",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Create workspace-specific monitoring script
cat > /opt/workspace_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/workspace-monitor.log"
WORKSPACE="${workspace}"
ENVIRONMENT="${environment}"

while true; do
    # Get system metrics
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # Get workspace-specific metrics
    HTTPD_PROCESSES=$(pgrep httpd | wc -l)
    CONNECTIONS=$(netstat -an | grep :80 | grep ESTABLISHED | wc -l)
    
    # Log with workspace context
    echo "$(date): WORKSPACE=$WORKSPACE, ENV=$ENVIRONMENT, CPU=${CPU_USAGE}%, MEM=${MEM_USAGE}%, DISK=${DISK_USAGE}%, HTTPD=$HTTPD_PROCESSES, CONN=$CONNECTIONS" >> $LOG_FILE
    
    # Workspace-specific alerting
    case $WORKSPACE in
        "prod")
            if (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
                echo "$(date): PROD ALERT: High CPU ($CPU_USAGE%) in workspace $WORKSPACE" >> $LOG_FILE
            fi
            ;;
        "staging")
            if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
                echo "$(date): STAGING WARNING: High CPU ($CPU_USAGE%) in workspace $WORKSPACE" >> $LOG_FILE
            fi
            ;;
        "dev"|"default")
            if (( $(echo "$CPU_USAGE < 5" | bc -l) )); then
                echo "$(date): DEV INFO: Low CPU ($CPU_USAGE%) in workspace $WORKSPACE - consider downsizing" >> $LOG_FILE
            fi
            ;;
        "test")
            echo "$(date): TEST WORKSPACE: Monitoring disabled for cost optimization" >> $LOG_FILE
            ;;
    esac
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/workspace_monitor.sh

# Start monitoring in background
nohup /opt/workspace_monitor.sh &

# Create workspace information script
cat > /opt/workspace_info.sh << 'EOF'
#!/bin/bash

echo "=== Terraform Workspace Information ==="
echo "Current Workspace: ${workspace}"
echo "Environment: ${environment}"
echo "Project: ${project_name}"
echo "VPC CIDR: ${vpc_cidr}"
echo "Instance Type: ${instance_type}"
echo "Monitoring: ${monitoring_enabled}"
echo "S3 Bucket: ${bucket_name}"
echo ""
echo "=== Resource Naming Pattern ==="
echo "Name Prefix: ${project_name}-${workspace}"
echo "VPC: ${project_name}-${workspace}-vpc"
echo "ALB: ${project_name}-${workspace}-alb"
echo "ASG: ${project_name}-${workspace}-web-asg"
echo ""
echo "=== State Management ==="
echo "State Key: workspace-strategy/env:/${workspace}/terraform.tfstate"
echo "Backend: S3 with DynamoDB locking"
echo ""
echo "=== Workspace Commands ==="
echo "List workspaces: terraform workspace list"
echo "Show current: terraform workspace show"
echo "Switch workspace: terraform workspace select <name>"
echo "Create workspace: terraform workspace new <name>"
EOF

chmod +x /opt/workspace_info.sh

# Add workspace info to motd
echo "#!/bin/bash" > /etc/update-motd.d/90-workspace-info
echo "/opt/workspace_info.sh" >> /etc/update-motd.d/90-workspace-info
chmod +x /etc/update-motd.d/90-workspace-info

# Log deployment with workspace context
echo "$(date): Workspace strategy demo deployed successfully" >> /var/log/deployment.log
echo "Workspace: ${workspace}" >> /var/log/deployment.log
echo "Environment: ${environment}" >> /var/log/deployment.log
echo "Project: ${project_name}" >> /var/log/deployment.log
echo "VPC CIDR: ${vpc_cidr}" >> /var/log/deployment.log
echo "Instance Type: ${instance_type}" >> /var/log/deployment.log
echo "State Key: workspace-strategy/env:/${workspace}/terraform.tfstate" >> /var/log/deployment.log