#!/bin/bash
yum update -y
yum install -y nodejs npm aws-cli python3 pip3

# Install additional tools for application processing
pip3 install boto3 psutil

# Create application directory
mkdir -p /opt/app-tier-demo
cd /opt/app-tier-demo

# Create a Node.js application that demonstrates app tier workloads
cat > app.js << 'EOF'
const express = require('express');
const app = express();
const port = 8080;

// Middleware
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// API endpoint that simulates business logic processing
app.get('/api/process', (req, res) => {
    const startTime = Date.now();
    
    // Simulate CPU-intensive business logic
    let result = 0;
    for (let i = 0; i < 1000000; i++) {
        result += Math.sqrt(i) * Math.random();
    }
    
    const processingTime = Date.now() - startTime;
    
    res.json({
        message: 'Application tier processing complete',
        tier: 'application',
        instance_type: '${instance_type}',
        processing_time_ms: processingTime,
        cpu_intensive_result: Math.round(result),
        workload_type: '${workload_type}',
        optimization_notes: '${optimization_notes}',
        target_cpu: '${cpu_target}',
        target_memory: '${memory_target}',
        estimated_monthly_cost: '${estimated_cost}'
    });
});

// Database simulation endpoint
app.get('/api/database', (req, res) => {
    // Simulate database queries with delays
    const queries = ['users', 'products', 'orders', 'analytics'];
    const results = {};
    
    queries.forEach(query => {
        // Simulate query processing time
        const records = Math.floor(Math.random() * 1000) + 100;
        results[query] = {
            records: records,
            query_time_ms: Math.floor(Math.random() * 50) + 10
        };
    });
    
    res.json({
        message: 'Database operations simulation',
        tier: 'application',
        queries_executed: queries.length,
        results: results,
        total_records: Object.values(results).reduce((sum, result) => sum + result.records, 0)
    });
});

// Memory-intensive operation
app.get('/api/memory-test', (req, res) => {
    const startTime = Date.now();
    
    // Create arrays to simulate memory usage
    const arrays = [];
    for (let i = 0; i < 100; i++) {
        arrays.push(new Array(10000).fill(Math.random()));
    }
    
    // Process the arrays
    let sum = 0;
    arrays.forEach(arr => {
        sum += arr.reduce((a, b) => a + b, 0);
    });
    
    const processingTime = Date.now() - startTime;
    
    res.json({
        message: 'Memory-intensive processing complete',
        tier: 'application',
        arrays_processed: arrays.length,
        total_elements: arrays.length * 10000,
        processing_time_ms: processingTime,
        memory_usage_simulation: 'Complete'
    });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`Application tier demo listening on port ${port}`);
    console.log('Instance type: ${instance_type}');
    console.log('Estimated monthly cost: $${estimated_cost}');
    console.log('Workload optimization: ${workload_type}');
});
EOF

# Create package.json
cat > package.json << 'EOF'
{
  "name": "rightsizing-app-tier",
  "version": "1.0.0",
  "description": "Application tier for right-sizing demonstration",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# Install dependencies
npm install

# Create web interface for application tier
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Right-Sizing Demo - ${tier} Tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #28a745; color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .tier-info { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #007bff; }
        .optimization { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .cost-info { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #28a745; }
        .metric-label { font-size: 12px; color: #6c757d; }
        .api-test { background: #e9ecef; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .api-button { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin: 5px; }
        .api-button:hover { background: #0056b3; }
        .api-result { background: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0; font-family: monospace; font-size: 12px; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .utilization-bar { width: 100%; height: 20px; background: #e9ecef; border-radius: 10px; margin: 10px 0; overflow: hidden; }
        .utilization-fill { height: 100%; background: linear-gradient(90deg, #28a745 0%, #ffc107 70%, #dc3545 100%); transition: width 0.3s ease; }
    </style>
    <script>
        function updateMetrics() {
            document.getElementById('timestamp').textContent = new Date().toISOString();
            
            // App tier typically has moderate CPU usage (30-50%)
            const cpu = Math.floor(Math.random() * 20 + 30); // 30-50%
            const memory = Math.floor(Math.random() * 20 + 50); // 50-70%
            const dbConnections = Math.floor(Math.random() * 20 + 10); // 10-30 connections
            const apiRequests = Math.floor(Math.random() * 100 + 50); // 50-150 req/min
            
            document.getElementById('cpu-usage').textContent = cpu;
            document.getElementById('memory-usage').textContent = memory;
            document.getElementById('db-connections').textContent = dbConnections;
            document.getElementById('api-requests').textContent = apiRequests;
            
            // Update utilization bars
            document.getElementById('cpu-bar').style.width = cpu + '%';
            document.getElementById('memory-bar').style.width = memory + '%';
            
            // Update optimization status
            const cpuStatus = cpu < 20 ? 'Underutilized' : cpu > 60 ? 'High Usage' : 'Optimal';
            const memoryStatus = memory < 40 ? 'Underutilized' : memory > 80 ? 'High Usage' : 'Optimal';
            
            document.getElementById('cpu-status').textContent = cpuStatus;
            document.getElementById('memory-status').textContent = memoryStatus;
            
            // Update colors
            document.getElementById('cpu-bar').style.background = 
                cpu < 20 ? '#ffc107' : cpu > 60 ? '#dc3545' : '#28a745';
            document.getElementById('memory-bar').style.background = 
                memory < 40 ? '#ffc107' : memory > 80 ? '#dc3545' : '#28a745';
        }
        
        function testAPI(endpoint) {
            const resultDiv = document.getElementById('api-result');
            resultDiv.textContent = 'Testing API endpoint...';
            
            fetch('http://localhost:8080' + endpoint)
                .then(response => response.json())
                .then(data => {
                    resultDiv.textContent = JSON.stringify(data, null, 2);
                })
                .catch(error => {
                    resultDiv.textContent = 'Error: ' + error.message;
                });
        }
        
        setInterval(updateMetrics, 5000);
        window.onload = updateMetrics;
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>⚙️ Right-Sizing Demo - ${tier} Tier</h1>
            <p>Instance Type: ${instance_type} | Estimated Monthly Cost: $${estimated_cost}</p>
            <p>Optimized for: ${workload_type}</p>
        </div>

        <div class="section">
            <h2>📊 Application Performance Metrics</h2>
            
            <div class="metric">
                <div class="metric-value" id="cpu-usage">--</div>
                <div class="metric-label">CPU Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="memory-usage">--</div>
                <div class="metric-label">Memory Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="db-connections">--</div>
                <div class="metric-label">DB Connections</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="api-requests">--</div>
                <div class="metric-label">API Requests/Min</div>
            </div>
        </div>

        <div class="section">
            <h2>🎯 Right-Sizing Analysis</h2>
            
            <div style="margin: 20px 0;">
                <strong>CPU Utilization:</strong> <span id="cpu-status">--</span>
                <div class="utilization-bar">
                    <div id="cpu-bar" class="utilization-fill" style="width: 0%;"></div>
                </div>
                <small>Target Range: ${cpu_target} (Business logic processing)</small>
            </div>
            
            <div style="margin: 20px 0;">
                <strong>Memory Utilization:</strong> <span id="memory-status">--</span>
                <div class="utilization-bar">
                    <div id="memory-bar" class="utilization-fill" style="width: 0%;"></div>
                </div>
                <small>Target Range: ${memory_target} (Application data and caching)</small>
            </div>
        </div>

        <div class="section">
            <h2>🧪 API Performance Testing</h2>
            <p>Test different application workloads to see how the ${instance_type} instance handles business logic processing:</p>
            
            <div class="api-test">
                <button class="api-button" onclick="testAPI('/api/process')">Test Business Logic</button>
                <button class="api-button" onclick="testAPI('/api/database')">Test Database Operations</button>
                <button class="api-button" onclick="testAPI('/api/memory-test')">Test Memory Processing</button>
                <button class="api-button" onclick="testAPI('/health')">Health Check</button>
                
                <div class="api-result" id="api-result">
                    Click a button above to test API endpoints and see processing performance.
                </div>
            </div>
        </div>

        <div class="section">
            <h2>⚙️ Application Tier Configuration</h2>
            
            <div class="tier-info">
                <strong>Instance Type:</strong> ${instance_type}
                <br><strong>Workload Optimization:</strong> ${workload_type}
                <br><strong>Right-Sizing Notes:</strong> ${optimization_notes}
                <br><strong>Target CPU:</strong> ${cpu_target}
                <br><strong>Target Memory:</strong> ${memory_target}
            </div>
            
            <div class="optimization">
                <strong>✅ Application Tier Optimizations:</strong>
                <ul>
                    <li>Instance type selected for business logic processing workloads</li>
                    <li>Memory sized for application data and database connections</li>
                    <li>CPU capacity appropriate for API request processing</li>
                    <li>Auto Scaling based on CPU and memory utilization patterns</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>💰 Cost vs Performance Analysis</h2>
            
            <div class="cost-info">
                <strong>Monthly Cost:</strong> $${estimated_cost} per instance
                <br><strong>Performance Profile:</strong> Balanced CPU and memory for business logic
                <br><strong>Scaling Strategy:</strong> Scale based on application load patterns
            </div>
            
            <div class="optimization">
                <strong>🎯 Right-Sizing Recommendations:</strong>
                <ul>
                    <li><strong>Monitor API Response Times:</strong> Ensure consistent performance under load</li>
                    <li><strong>Database Connection Pooling:</strong> Optimize memory usage for connections</li>
                    <li><strong>CPU Utilization:</strong> Target ${cpu_target} for optimal performance/cost ratio</li>
                    <li><strong>Memory Management:</strong> Monitor for memory leaks and optimize caching</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>🏗️ Application Architecture Role</h2>
            <div class="tier-info">
                <strong>Primary Function:</strong> Business logic processing and API request handling
                <br><strong>Scaling Triggers:</strong> CPU utilization and API response time thresholds
                <br><strong>Performance Focus:</strong> Consistent API response times with cost efficiency
                <br><strong>Resource Balance:</strong> CPU and memory optimized for application workloads
            </div>
        </div>

        <div class="section">
            <h2>📋 Instance Details</h2>
            <p><strong>Tier:</strong> ${tier}</p>
            <p><strong>Instance Type:</strong> ${instance_type}</p>
            <p><strong>Estimated Monthly Cost:</strong> $${estimated_cost}</p>
            <p><strong>API Endpoint:</strong> http://localhost:8080</p>
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

# Install and configure Apache for the web interface
yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Create systemd service for the Node.js app
cat > /etc/systemd/system/app-tier-demo.service << 'EOF'
[Unit]
Description=Application Tier Right-Sizing Demo
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app-tier-demo
ExecStart=/usr/bin/node app.js
Environment=NODE_ENV=production
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/app-tier-demo

# Start and enable the service
systemctl daemon-reload
systemctl enable app-tier-demo
systemctl start app-tier-demo

# Create right-sizing monitoring script for app tier
cat > /opt/app_rightsizing_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/rightsizing-app.log"

while true; do
    # Get system metrics
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
    
    # Get application-specific metrics
    APP_PROCESSES=$(pgrep -f "node app.js" | wc -l)
    DB_CONNECTIONS=$(netstat -an | grep :3306 | grep ESTABLISHED | wc -l)
    
    # Log metrics
    echo "$(date): CPU=${CPU_USAGE}%, MEM=${MEM_USAGE}%, APP_PROC=${APP_PROCESSES}, DB_CONN=${DB_CONNECTIONS}" >> $LOG_FILE
    
    # Application tier right-sizing analysis
    if (( $(echo "$CPU_USAGE < 15" | bc -l) )); then
        echo "$(date): RECOMMENDATION: CPU usage low (${CPU_USAGE}%) - consider downsizing to t3.micro" >> $LOG_FILE
    elif (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
        echo "$(date): RECOMMENDATION: CPU usage high (${CPU_USAGE}%) - consider upsizing to t3.medium" >> $LOG_FILE
    fi
    
    if (( $(echo "$MEM_USAGE < 30" | bc -l) )); then
        echo "$(date): RECOMMENDATION: Memory usage low (${MEM_USAGE}%) - current size may be oversized" >> $LOG_FILE
    elif (( $(echo "$MEM_USAGE > 85" | bc -l) )); then
        echo "$(date): RECOMMENDATION: Memory usage high (${MEM_USAGE}%) - consider upsizing or optimizing app" >> $LOG_FILE
    fi
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/app_rightsizing_monitor.sh
nohup /opt/app_rightsizing_monitor.sh &

# Log the deployment
echo "$(date): Application tier right-sizing demo deployed on ${instance_type}" >> /var/log/deployment.log
echo "API endpoint: http://localhost:8080" >> /var/log/deployment.log
echo "Estimated monthly cost: $${estimated_cost}" >> /var/log/deployment.log