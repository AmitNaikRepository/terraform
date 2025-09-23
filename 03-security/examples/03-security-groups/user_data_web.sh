#!/bin/bash
yum update -y
yum install -y httpd

# Create a simple web page
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Security Groups Demo - Web Tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 800px; margin: 0 auto; }
        .tier { background: #e6f3ff; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .security-info { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; }
        h1 { color: #2c5aa0; }
        h2 { color: #1e3d72; }
        .port { color: #007bff; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ Security Groups Demo - Web Tier</h1>
        
        <div class="tier">
            <h2>Current Tier: Web (Public)</h2>
            <p>This server is in the <strong>public subnet</strong> and protected by the <strong>web tier security group</strong>.</p>
        </div>

        <div class="security-info">
            <h3>Security Group Rules:</h3>
            <ul>
                <li><strong>Inbound:</strong></li>
                <ul>
                    <li>HTTP (port <span class="port">80</span>) from <span class="port">0.0.0.0/0</span></li>
                    <li>HTTPS (port <span class="port">443</span>) from <span class="port">0.0.0.0/0</span></li>
                    <li>SSH (port <span class="port">22</span>) from management network only</li>
                </ul>
                <li><strong>Outbound:</strong></li>
                <ul>
                    <li>To application tier on port <span class="port">${app_port}</span></li>
                    <li>HTTPS (port <span class="port">443</span>) for updates</li>
                    <li>HTTP (port <span class="port">80</span>) for updates</li>
                </ul>
            </ul>
        </div>

        <div class="tier">
            <h3>Architecture Overview:</h3>
            <p><strong>Internet</strong> → <strong style="color: #28a745;">Web Tier (You are here)</strong> → App Tier → Database Tier</p>
        </div>

        <div class="security-info">
            <h3>Security Best Practices Demonstrated:</h3>
            <ul>
                <li>✅ Principle of least privilege</li>
                <li>✅ Network segmentation</li>
                <li>✅ Explicit inbound and outbound rules</li>
                <li>✅ Security group references instead of IP ranges</li>
                <li>✅ Restricted management access</li>
            </ul>
        </div>

        <p><strong>Instance Metadata:</strong></p>
        <ul>
            <li>Instance ID: <span id="instance-id">Loading...</span></li>
            <li>Local IP: <span id="local-ip">Loading...</span></li>
            <li>Timestamp: <span id="timestamp"></span></li>
        </ul>
    </div>

    <script>
        // Display current timestamp
        document.getElementById('timestamp').textContent = new Date().toISOString();
        
        // Fetch instance metadata (if available)
        fetch('http://169.254.169.254/latest/meta-data/instance-id')
            .then(response => response.text())
            .then(data => document.getElementById('instance-id').textContent = data)
            .catch(() => document.getElementById('instance-id').textContent = 'Not available');
            
        fetch('http://169.254.169.254/latest/meta-data/local-ipv4')
            .then(response => response.text())
            .then(data => document.getElementById('local-ip').textContent = data)
            .catch(() => document.getElementById('local-ip').textContent = 'Not available');
    </script>
</body>
</html>
EOF

# Start and enable Apache
systemctl enable httpd
systemctl start httpd

# Log the deployment
echo "$(date): Web tier security groups demo deployed" >> /var/log/security-demo.log