#!/bin/bash
yum update -y
yum install -y nodejs npm

# Create application directory
mkdir -p /opt/security-demo-app
cd /opt/security-demo-app

# Create a simple Node.js application
cat > app.js << 'EOF'
const express = require('express');
const app = express();
const port = ${app_port};

// Middleware
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    tier: 'application',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Security Groups Demo - Application Tier',
    tier: 'application',
    security_group: 'app-tier-sg',
    access_pattern: 'Receives traffic only from web tier',
    port: port,
    timestamp: new Date().toISOString(),
    security_features: [
      'Isolated in private subnet',
      'No direct internet access',
      'Accepts traffic only from web tier security group',
      'Can communicate with database tier on port 3306',
      'SSH access only via bastion host'
    ]
  });
});

// API endpoint
app.get('/api/security-info', (req, res) => {
  res.json({
    tier: 'application',
    security_controls: {
      network_isolation: 'Private subnet - no direct internet access',
      inbound_rules: [
        'Port ${app_port} from web tier security group only',
        'SSH (port 22) from bastion security group only'
      ],
      outbound_rules: [
        'MySQL (port 3306) to database tier security group',
        'HTTPS (port 443) for external API calls',
        'HTTP (port 80) for package updates'
      ]
    },
    architecture: {
      position: 'Middle tier in 3-tier architecture',
      upstream: 'Web tier (public subnet)',
      downstream: 'Database tier (isolated subnet)'
    }
  });
});

// Database simulation endpoint
app.get('/api/data', (req, res) => {
  res.json({
    message: 'This would query the database tier',
    note: 'Database connection would use security group reference on port 3306',
    security: 'Only this app tier can reach the database tier'
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Security Groups Demo App listening on port $${port}`);
  console.log('Tier: Application (Private Subnet)');
  console.log('Security: Protected by app-tier security group');
});
EOF

# Create package.json
cat > package.json << 'EOF'
{
  "name": "security-groups-demo-app",
  "version": "1.0.0",
  "description": "Application tier for security groups demonstration",
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

# Create systemd service
cat > /etc/systemd/system/security-demo-app.service << 'EOF'
[Unit]
Description=Security Groups Demo Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/security-demo-app
ExecStart=/usr/bin/node app.js
Environment=NODE_ENV=production
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/security-demo-app

# Start and enable the service
systemctl daemon-reload
systemctl enable security-demo-app
systemctl start security-demo-app

# Log the deployment
echo "$(date): Application tier security groups demo deployed on port ${app_port}" >> /var/log/security-demo.log