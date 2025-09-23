#!/bin/bash
yum update -y
yum install -y httpd aws-cli

# Create the right-sizing demo web application
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Right-Sizing Demo - ${tier} Tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #007bff; color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .tier-info { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #007bff; }
        .optimization { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .cost-info { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007bff; }
        .metric-label { font-size: 12px; color: #6c757d; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .utilization-bar { width: 100%; height: 20px; background: #e9ecef; border-radius: 10px; margin: 10px 0; overflow: hidden; }
        .utilization-fill { height: 100%; background: linear-gradient(90deg, #28a745 0%, #ffc107 70%, #dc3545 100%); transition: width 0.3s ease; }
    </style>
    <script>
        function updateMetrics() {
            // Simulate right-sizing metrics
            document.getElementById('timestamp').textContent = new Date().toISOString();
            
            // Web tier typically has lower CPU usage (15-25%)
            const cpu = Math.floor(Math.random() * 10 + 15); // 15-25%
            const memory = Math.floor(Math.random() * 20 + 40); // 40-60%
            const requests = Math.floor(Math.random() * 500 + 100); // 100-600 req/min
            const responseTime = Math.floor(Math.random() * 50 + 50); // 50-100ms
            
            document.getElementById('cpu-usage').textContent = cpu;
            document.getElementById('memory-usage').textContent = memory;
            document.getElementById('requests-per-min').textContent = requests;
            document.getElementById('response-time').textContent = responseTime;
            
            // Update utilization bars
            document.getElementById('cpu-bar').style.width = cpu + '%';
            document.getElementById('memory-bar').style.width = memory + '%';
            
            // Update optimization status
            const cpuStatus = cpu < 10 ? 'Underutilized' : cpu > 30 ? 'High Usage' : 'Optimal';
            const memoryStatus = memory < 30 ? 'Underutilized' : memory > 70 ? 'High Usage' : 'Optimal';
            
            document.getElementById('cpu-status').textContent = cpuStatus;
            document.getElementById('memory-status').textContent = memoryStatus;
            
            // Update colors based on status
            document.getElementById('cpu-bar').style.background = 
                cpu < 10 ? '#ffc107' : cpu > 30 ? '#dc3545' : '#28a745';
            document.getElementById('memory-bar').style.background = 
                memory < 30 ? '#ffc107' : memory > 70 ? '#dc3545' : '#28a745';
        }
        
        setInterval(updateMetrics, 5000);
        window.onload = updateMetrics;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Right-Sizing Demo - ${tier} Tier</h1>
            <p>Instance Type: ${instance_type} | Estimated Monthly Cost: $${estimated_cost}</p>
            <p>Optimized for: ${workload_type}</p>
        </div>

        <div class="section">
            <h2>🎯 Real-Time Performance Metrics</h2>
            
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
            <h2>📈 Utilization Analysis</h2>
            
            <div style="margin: 20px 0;">
                <strong>CPU Utilization:</strong> <span id="cpu-status">--</span>
                <div class="utilization-bar">
                    <div id="cpu-bar" class="utilization-fill" style="width: 0%;"></div>
                </div>
                <small>Target Range: ${cpu_target} (Web tier optimized for request handling)</small>
            </div>
            
            <div style="margin: 20px 0;">
                <strong>Memory Utilization:</strong> <span id="memory-status">--</span>
                <div class="utilization-bar">
                    <div id="memory-bar" class="utilization-fill" style="width: 0%;"></div>
                </div>
                <small>Target Range: ${memory_target} (Sufficient for web server processes)</small>
            </div>
        </div>

        <div class="section">
            <h2>🔧 Right-Sizing Configuration</h2>
            
            <div class="tier-info">
                <strong>Instance Type:</strong> ${instance_type}
                <br><strong>Workload Optimization:</strong> ${workload_type}
                <br><strong>Cost Optimization:</strong> ${optimization_notes}
                <br><strong>Target CPU:</strong> ${cpu_target}
                <br><strong>Target Memory:</strong> ${memory_target}
            </div>
            
            <div class="optimization">
                <strong>✅ Right-Sizing Benefits:</strong>
                <ul>
                    <li>Optimal performance-to-cost ratio for web serving workloads</li>
                    <li>Auto Scaling based on actual demand patterns</li>
                    <li>CloudWatch monitoring for continuous optimization</li>
                    <li>Load balancer distribution for efficient resource usage</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>💰 Cost Optimization Analysis</h2>
            
            <div class="cost-info">
                <strong>Current Instance Cost:</strong> $${estimated_cost}/month
                <br><strong>Right-Sizing Status:</strong> Optimized for web tier workloads
                <br><strong>Scaling Efficiency:</strong> Auto Scaling based on request patterns
            </div>
            
            <div class="optimization">
                <strong>💡 Optimization Recommendations:</strong>
                <ul>
                    <li><strong>Monitor Patterns:</strong> Track request volumes and response times</li>
                    <li><strong>Scale Efficiency:</strong> Ensure scaling triggers match workload patterns</li>
                    <li><strong>Resource Usage:</strong> Maintain ${cpu_target} CPU utilization</li>
                    <li><strong>Cost Monitoring:</strong> Review monthly costs vs performance metrics</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>🏗️ Web Tier Architecture</h2>
            <div class="tier-info">
                <strong>Role:</strong> HTTP/HTTPS request handling and static content serving
                <br><strong>Scaling Triggers:</strong> Request count and response time thresholds
                <br><strong>Load Balancing:</strong> Application Load Balancer with health checks
                <br><strong>Optimization Focus:</strong> Fast response times with cost efficiency
            </div>
            
            <div class="optimization">
                <strong>🎯 Performance Targets:</strong>
                <ul>
                    <li>Response Time: &lt; 200ms for dynamic content</li>
                    <li>CPU Utilization: ${cpu_target} average</li>
                    <li>Memory Usage: ${memory_target} to handle concurrent requests</li>
                    <li>Request Handling: 100-1000 requests/minute per instance</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>📋 Instance Information</h2>
            <p><strong>Tier:</strong> ${tier}</p>
            <p><strong>Instance Type:</strong> ${instance_type}</p>
            <p><strong>Estimated Monthly Cost:</strong> $${estimated_cost}</p>
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
OK
EOF

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Create a script to simulate web workload and monitor right-sizing
cat > /opt/rightsizing_monitor.sh << 'EOF'
#!/bin/bash

# Web tier right-sizing monitoring script
LOG_FILE="/var/log/rightsizing-web.log"

while true; do
    # Get current system metrics
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # Get HTTP metrics from Apache
    CONNECTIONS=$(netstat -an | grep :80 | grep ESTABLISHED | wc -l)
    
    # Log metrics
    echo "$(date): CPU=${CPU_USAGE}%, MEM=${MEM_USAGE}%, LOAD=${LOAD_AVG}, CONNECTIONS=${CONNECTIONS}" >> $LOG_FILE
    
    # Right-sizing analysis
    if (( $(echo "$CPU_USAGE < 5" | bc -l) )); then
        echo "$(date): RECOMMENDATION: CPU usage very low (${CPU_USAGE}%) - consider downsizing to t3.nano" >> $LOG_FILE
    elif (( $(echo "$CPU_USAGE > 40" | bc -l) )); then
        echo "$(date): RECOMMENDATION: CPU usage high (${CPU_USAGE}%) - consider upsizing to t3.small" >> $LOG_FILE
    fi
    
    if (( $(echo "$MEM_USAGE < 25" | bc -l) )); then
        echo "$(date): RECOMMENDATION: Memory usage low (${MEM_USAGE}%) - current size appropriate" >> $LOG_FILE
    elif (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
        echo "$(date): RECOMMENDATION: Memory usage high (${MEM_USAGE}%) - consider upsizing" >> $LOG_FILE
    fi
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/rightsizing_monitor.sh

# Start the monitoring script in background
nohup /opt/rightsizing_monitor.sh &

# Log the deployment
echo "$(date): Web tier right-sizing demo deployed on ${instance_type}" >> /var/log/deployment.log
echo "Tier: ${tier}, Cost: $${estimated_cost}/month" >> /var/log/deployment.log
echo "Workload: ${workload_type}" >> /var/log/deployment.log