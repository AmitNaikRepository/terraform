#!/bin/bash
yum update -y
yum install -y httpd

# Install Node.js for a simple application
curl -sL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Create a simple web application
mkdir -p /opt/webapp
cat > /opt/webapp/app.js << 'EOF'
const express = require('express');
const app = express();
const port = ${application_port};

// Health check endpoint
app.get('${health_check_path}', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development'
  });
});

// Main application endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Terraform-managed infrastructure!',
    instance_id: process.env.INSTANCE_ID || 'unknown',
    port: port,
    timestamp: new Date().toISOString()
  });
});

// API endpoint
app.get('/api/info', (req, res) => {
  res.json({
    application: 'terraform-fundamentals-demo',
    version: '1.0.0',
    architecture: 'modular',
    modules: ['vpc', 'security', 'compute'],
    features: [
      'Auto Scaling',
      'Load Balancing', 
      'Health Checks',
      'Modular Design'
    ]
  });
});

app.listen(port, () => {
  console.log(`Application listening on port $${port}`);
});
EOF

# Create package.json
cat > /opt/webapp/package.json << 'EOF'
{
  "name": "terraform-fundamentals-demo",
  "version": "1.0.0",
  "description": "Demo application for Terraform Fundamentals",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
EOF

# Install dependencies and start application
cd /opt/webapp
npm install

# Create systemd service
cat > /etc/systemd/system/webapp.service << 'EOF'
[Unit]
Description=Terraform Fundamentals Demo Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/webapp
ExecStart=/usr/bin/node app.js
Environment=NODE_ENV=production
Environment=INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start and enable the service
systemctl daemon-reload
systemctl enable webapp
systemctl start webapp

# Configure Apache as reverse proxy (optional)
cat > /etc/httpd/conf.d/proxy.conf << 'EOF'
<VirtualHost *:80>
    ProxyPreserveHost On
    ProxyPass / http://localhost:${application_port}/
    ProxyPassReverse / http://localhost:${application_port}/
    
    # Health check endpoint for load balancer
    ProxyPass ${health_check_path} http://localhost:${application_port}${health_check_path}
    ProxyPassReverse ${health_check_path} http://localhost:${application_port}${health_check_path}
</VirtualHost>
EOF

# Enable Apache modules
systemctl enable httpd
systemctl start httpd

# Set proper permissions
chown -R ec2-user:ec2-user /opt/webapp

# Log the deployment
echo "$(date): Terraform Fundamentals Demo Application deployed successfully" >> /var/log/deployment.log
echo "Application running on port ${application_port}" >> /var/log/deployment.log
echo "Health check available at ${health_check_path}" >> /var/log/deployment.log