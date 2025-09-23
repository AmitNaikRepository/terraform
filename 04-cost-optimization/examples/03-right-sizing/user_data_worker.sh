#!/bin/bash
yum update -y
yum install -y python3 pip3 aws-cli htop

# Install Python packages for worker processing
pip3 install boto3 psutil celery redis

# Create worker application directory
mkdir -p /opt/worker-tier-demo
cd /opt/worker-tier-demo

# Create Python worker application
cat > worker_app.py << 'EOF'
#!/usr/bin/env python3
import time
import json
import random
import threading
import queue
import hashlib
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import socketserver

class WorkerDemoHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b'OK')
            
        elif self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            html_content = self.generate_worker_dashboard()
            self.wfile.write(html_content.encode())
            
        elif self.path == '/api/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            status = {
                'tier': 'worker',
                'instance_type': '${instance_type}',
                'estimated_cost': ${estimated_cost},
                'workload_type': '${workload_type}',
                'optimization_notes': '${optimization_notes}',
                'target_cpu': '${cpu_target}',
                'target_memory': '${memory_target}',
                'active_jobs': worker_processor.get_active_jobs(),
                'completed_jobs': worker_processor.get_completed_jobs(),
                'queue_size': worker_processor.get_queue_size(),
                'timestamp': datetime.now().isoformat()
            }
            
            self.wfile.write(json.dumps(status, indent=2).encode())
            
        elif self.path == '/api/process-job':
            # Trigger a background processing job
            job_id = worker_processor.add_job('cpu_intensive', {'duration': 10})
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            response = {
                'message': 'Background job started',
                'job_id': job_id,
                'job_type': 'cpu_intensive'
            }
            
            self.wfile.write(json.dumps(response).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def generate_worker_dashboard(self):
        return '''
<!DOCTYPE html>
<html>
<head>
    <title>Right-Sizing Demo - Worker Tier</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f8ff; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #6f42c1; color: white; padding: 20px; border-radius: 8px; text-align: center; }
        .section { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .tier-info { background: #e6f3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #007bff; }
        .optimization { background: #d4edda; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .cost-info { background: #fff3cd; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        .metric { display: inline-block; margin: 10px; padding: 15px; background: #f8f9fa; border-radius: 8px; text-align: center; min-width: 120px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #6f42c1; }
        .metric-label { font-size: 12px; color: #6c757d; }
        .job-button { background: #6f42c1; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; margin: 5px; }
        .job-button:hover { background: #5a2d91; }
        .job-result { background: #f8f9fa; padding: 10px; border-radius: 4px; margin: 10px 0; font-family: monospace; font-size: 12px; }
        h1 { margin: 0; }
        h2 { color: #2c5aa0; border-bottom: 2px solid #e9ecef; padding-bottom: 10px; }
        .utilization-bar { width: 100%; height: 20px; background: #e9ecef; border-radius: 10px; margin: 10px 0; overflow: hidden; }
        .utilization-fill { height: 100%; background: linear-gradient(90deg, #28a745 0%, #ffc107 70%, #dc3545 100%); transition: width 0.3s ease; }
        .queue-status { background: #e7e3ff; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #6f42c1; }
    </style>
    <script>
        function updateMetrics() {
            fetch('/api/status')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('timestamp').textContent = data.timestamp;
                    document.getElementById('active-jobs').textContent = data.active_jobs;
                    document.getElementById('completed-jobs').textContent = data.completed_jobs;
                    document.getElementById('queue-size').textContent = data.queue_size;
                })
                .catch(error => console.error('Error:', error));
            
            // Simulate worker tier metrics (higher CPU usage expected)
            const cpu = Math.floor(Math.random() * 20 + 60); // 60-80%
            const memory = Math.floor(Math.random() * 20 + 40); // 40-60%
            const processed = Math.floor(Math.random() * 50 + 100); // 100-150 jobs/hour
            
            document.getElementById('cpu-usage').textContent = cpu;
            document.getElementById('memory-usage').textContent = memory;
            document.getElementById('jobs-processed').textContent = processed;
            
            // Update utilization bars
            document.getElementById('cpu-bar').style.width = cpu + '%';
            document.getElementById('memory-bar').style.width = memory + '%';
            
            // Update status
            const cpuStatus = cpu < 40 ? 'Underutilized' : cpu > 85 ? 'High Usage' : 'Optimal';
            const memoryStatus = memory < 30 ? 'Underutilized' : memory > 70 ? 'High Usage' : 'Optimal';
            
            document.getElementById('cpu-status').textContent = cpuStatus;
            document.getElementById('memory-status').textContent = memoryStatus;
            
            // Update colors
            document.getElementById('cpu-bar').style.background = 
                cpu < 40 ? '#ffc107' : cpu > 85 ? '#dc3545' : '#28a745';
            document.getElementById('memory-bar').style.background = 
                memory < 30 ? '#ffc107' : memory > 70 ? '#dc3545' : '#28a745';
        }
        
        function startJob() {
            const resultDiv = document.getElementById('job-result');
            resultDiv.textContent = 'Starting background job...';
            
            fetch('/api/process-job')
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
            <h1>⚙️ Right-Sizing Demo - Worker Tier</h1>
            <p>Instance Type: ${instance_type} | Estimated Monthly Cost: $${estimated_cost}</p>
            <p>Optimized for: ${workload_type}</p>
        </div>

        <div class="section">
            <h2>🔧 Worker Processing Metrics</h2>
            
            <div class="metric">
                <div class="metric-value" id="cpu-usage">--</div>
                <div class="metric-label">CPU Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="memory-usage">--</div>
                <div class="metric-label">Memory Usage %</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="jobs-processed">--</div>
                <div class="metric-label">Jobs/Hour</div>
            </div>
            <div class="metric">
                <div class="metric-value" id="queue-size">--</div>
                <div class="metric-label">Queue Size</div>
            </div>
        </div>

        <div class="section">
            <h2>📊 Right-Sizing Analysis</h2>
            
            <div style="margin: 20px 0;">
                <strong>CPU Utilization:</strong> <span id="cpu-status">--</span>
                <div class="utilization-bar">
                    <div id="cpu-bar" class="utilization-fill" style="width: 0%;"></div>
                </div>
                <small>Target Range: ${cpu_target} (Background processing optimized)</small>
            </div>
            
            <div style="margin: 20px 0;">
                <strong>Memory Utilization:</strong> <span id="memory-status">--</span>
                <div class="utilization-bar">
                    <div id="memory-bar" class="utilization-fill" style="width: 0%;"></div>
                </div>
                <small>Target Range: ${memory_target} (Efficient for batch processing)</small>
            </div>
        </div>

        <div class="section">
            <h2>📋 Job Queue Status</h2>
            
            <div class="queue-status">
                <strong>Active Jobs:</strong> <span id="active-jobs">--</span>
                <br><strong>Completed Jobs:</strong> <span id="completed-jobs">--</span>
                <br><strong>Queue Length:</strong> <span id="queue-size">--</span>
            </div>
            
            <button class="job-button" onclick="startJob()">Start Background Job</button>
            
            <div class="job-result" id="job-result">
                Click "Start Background Job" to test worker processing capabilities.
            </div>
        </div>

        <div class="section">
            <h2>⚙️ Worker Tier Configuration</h2>
            
            <div class="tier-info">
                <strong>Instance Type:</strong> ${instance_type}
                <br><strong>Workload Optimization:</strong> ${workload_type}
                <br><strong>Right-Sizing Notes:</strong> ${optimization_notes}
                <br><strong>Target CPU:</strong> ${cpu_target}
                <br><strong>Target Memory:</strong> ${memory_target}
            </div>
            
            <div class="optimization">
                <strong>✅ Worker Tier Optimizations:</strong>
                <ul>
                    <li>Higher CPU utilization targets for batch processing efficiency</li>
                    <li>Memory optimized for data processing and temporary storage</li>
                    <li>Auto Scaling based on queue depth and processing time</li>
                    <li>Cost-effective processing of background tasks</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>💰 Processing Cost Analysis</h2>
            
            <div class="cost-info">
                <strong>Monthly Cost:</strong> $${estimated_cost} per instance
                <br><strong>Processing Profile:</strong> CPU-intensive background processing
                <br><strong>Scaling Strategy:</strong> Scale based on queue depth and processing patterns
            </div>
            
            <div class="optimization">
                <strong>🎯 Worker Right-Sizing Best Practices:</strong>
                <ul>
                    <li><strong>High CPU Utilization:</strong> Target ${cpu_target} for efficient processing</li>
                    <li><strong>Queue Monitoring:</strong> Scale based on job backlog and processing time</li>
                    <li><strong>Batch Processing:</strong> Optimize job batching for better resource utilization</li>
                    <li><strong>Scheduled Scaling:</strong> Scale down during low-activity periods</li>
                </ul>
            </div>
        </div>

        <div class="section">
            <h2>🏗️ Worker Architecture Role</h2>
            <div class="tier-info">
                <strong>Primary Function:</strong> Background processing, batch jobs, and queue processing
                <br><strong>Scaling Triggers:</strong> Queue depth, processing time, and CPU utilization
                <br><strong>Performance Focus:</strong> Maximum throughput with cost efficiency
                <br><strong>Resource Optimization:</strong> High CPU utilization with moderate memory usage
            </div>
        </div>

        <div class="section">
            <h2>📋 Instance Details</h2>
            <p><strong>Tier:</strong> Worker</p>
            <p><strong>Instance Type:</strong> ${instance_type}</p>
            <p><strong>Estimated Monthly Cost:</strong> $${estimated_cost}</p>
            <p><strong>Worker Endpoint:</strong> http://localhost:5000</p>
            <p><strong>Last Updated:</strong> <span id="timestamp">--</span></p>
        </div>
    </div>
</body>
</html>
        '''

class WorkerProcessor:
    def __init__(self):
        self.job_queue = queue.Queue()
        self.active_jobs = 0
        self.completed_jobs = 0
        self.workers = []
        
        # Start worker threads
        for i in range(2):
            worker_thread = threading.Thread(target=self.worker_loop, daemon=True)
            worker_thread.start()
            self.workers.append(worker_thread)
    
    def worker_loop(self):
        while True:
            try:
                job = self.job_queue.get(timeout=1)
                self.active_jobs += 1
                
                # Process the job based on type
                if job['type'] == 'cpu_intensive':
                    self.process_cpu_intensive_job(job)
                elif job['type'] == 'data_processing':
                    self.process_data_job(job)
                
                self.active_jobs -= 1
                self.completed_jobs += 1
                self.job_queue.task_done()
                
            except queue.Empty:
                continue
            except Exception as e:
                print(f"Worker error: {e}")
                self.active_jobs -= 1
    
    def process_cpu_intensive_job(self, job):
        # Simulate CPU-intensive processing
        duration = job.get('duration', 5)
        start_time = time.time()
        
        # CPU-intensive calculation
        result = 0
        iterations = 1000000 * duration
        for i in range(iterations):
            result += hashlib.md5(str(i).encode()).hexdigest()
        
        processing_time = time.time() - start_time
        print(f"CPU intensive job completed in {processing_time:.2f} seconds")
    
    def process_data_job(self, job):
        # Simulate data processing
        data_size = job.get('data_size', 1000000)
        
        # Create and process data
        data = [random.random() for _ in range(data_size)]
        
        # Sort, filter, and aggregate
        sorted_data = sorted(data)
        filtered_data = [x for x in sorted_data if x > 0.5]
        aggregated = sum(filtered_data)
        
        print(f"Data processing job completed: {len(filtered_data)} items, sum: {aggregated:.2f}")
    
    def add_job(self, job_type, params=None):
        job_id = f"job_{int(time.time())}_{random.randint(1000, 9999)}"
        job = {
            'id': job_id,
            'type': job_type,
            'timestamp': datetime.now().isoformat()
        }
        
        if params:
            job.update(params)
        
        self.job_queue.put(job)
        return job_id
    
    def get_active_jobs(self):
        return self.active_jobs
    
    def get_completed_jobs(self):
        return self.completed_jobs
    
    def get_queue_size(self):
        return self.job_queue.qsize()

# Initialize worker processor
worker_processor = WorkerProcessor()

# Continuously add sample jobs
def job_generator():
    while True:
        time.sleep(30)  # Add a job every 30 seconds
        job_type = random.choice(['cpu_intensive', 'data_processing'])
        worker_processor.add_job(job_type)

job_thread = threading.Thread(target=job_generator, daemon=True)
job_thread.start()

if __name__ == '__main__':
    # Start the HTTP server
    server = HTTPServer(('0.0.0.0', 5000), WorkerDemoHandler)
    print("Worker tier demo server starting on port 5000...")
    print(f"Instance type: ${instance_type}")
    print(f"Estimated monthly cost: $${estimated_cost}")
    server.serve_forever()
EOF

chmod +x /opt/worker-tier-demo/worker_app.py

# Create systemd service for worker app
cat > /etc/systemd/system/worker-demo.service << 'EOF'
[Unit]
Description=Worker Tier Right-Sizing Demo
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/worker-tier-demo
ExecStart=/usr/bin/python3 worker_app.py
Environment=PYTHONPATH=/opt/worker-tier-demo
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
chown -R ec2-user:ec2-user /opt/worker-tier-demo

# Start and enable the service
systemctl daemon-reload
systemctl enable worker-demo
systemctl start worker-demo

# Create right-sizing monitoring script for worker tier
cat > /opt/worker_rightsizing_monitor.sh << 'EOF'
#!/bin/bash

LOG_FILE="/var/log/rightsizing-worker.log"

while true; do
    # Get system metrics
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    MEM_USAGE=$(free | grep Mem | awk '{printf "%.1f", ($3/$2) * 100.0}')
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # Get worker-specific metrics
    PYTHON_PROCESSES=$(pgrep -f "python3 worker_app.py" | wc -l)
    
    # Log metrics
    echo "$(date): CPU=${CPU_USAGE}%, MEM=${MEM_USAGE}%, LOAD=${LOAD_AVG}, WORKER_PROC=${PYTHON_PROCESSES}" >> $LOG_FILE
    
    # Worker tier right-sizing analysis
    if (( $(echo "$CPU_USAGE < 30" | bc -l) )); then
        echo "$(date): RECOMMENDATION: CPU usage low (${CPU_USAGE}%) for worker tier - consider downsizing to t3.small or review workload" >> $LOG_FILE
    elif (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
        echo "$(date): RECOMMENDATION: CPU usage very high (${CPU_USAGE}%) - consider upsizing to t3.large or adding more workers" >> $LOG_FILE
    elif (( $(echo "$CPU_USAGE >= 60 && $CPU_USAGE <= 80" | bc -l) )); then
        echo "$(date): OPTIMAL: CPU usage (${CPU_USAGE}%) is in optimal range for worker processing" >> $LOG_FILE
    fi
    
    if (( $(echo "$MEM_USAGE < 25" | bc -l) )); then
        echo "$(date): RECOMMENDATION: Memory usage low (${MEM_USAGE}%) - current instance size may be oversized" >> $LOG_FILE
    elif (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
        echo "$(date): RECOMMENDATION: Memory usage high (${MEM_USAGE}%) - consider upsizing or optimizing memory usage" >> $LOG_FILE
    fi
    
    # Check load average for queue processing efficiency
    if (( $(echo "$LOAD_AVG > 2.0" | bc -l) )); then
        echo "$(date): RECOMMENDATION: High load average (${LOAD_AVG}) - consider scaling up or optimizing job processing" >> $LOG_FILE
    fi
    
    sleep 300  # Check every 5 minutes
done
EOF

chmod +x /opt/worker_rightsizing_monitor.sh
nohup /opt/worker_rightsizing_monitor.sh &

# Create a sample batch job script
cat > /opt/sample_batch_job.py << 'EOF'
#!/usr/bin/env python3
"""
Sample batch job for demonstrating worker tier processing
"""
import time
import random
import hashlib
from datetime import datetime

def cpu_intensive_task(duration=10):
    """Simulate CPU-intensive processing"""
    print(f"Starting CPU-intensive task for {duration} seconds...")
    start_time = time.time()
    
    result = 0
    while time.time() - start_time < duration:
        # Perform CPU-intensive operations
        for i in range(10000):
            result += hashlib.sha256(str(random.random()).encode()).hexdigest()
    
    print(f"CPU-intensive task completed. Processed {len(str(result))} characters.")
    return result

def memory_intensive_task(data_size=1000000):
    """Simulate memory-intensive processing"""
    print(f"Starting memory-intensive task with {data_size} data points...")
    
    # Generate large dataset
    data = [random.random() for _ in range(data_size)]
    
    # Process data
    sorted_data = sorted(data)
    filtered_data = [x for x in sorted_data if x > 0.3 and x < 0.7]
    aggregated_result = {
        'mean': sum(filtered_data) / len(filtered_data) if filtered_data else 0,
        'count': len(filtered_data),
        'min': min(filtered_data) if filtered_data else 0,
        'max': max(filtered_data) if filtered_data else 0
    }
    
    print(f"Memory-intensive task completed. Processed {len(data)} items, filtered to {len(filtered_data)}")
    return aggregated_result

if __name__ == "__main__":
    print(f"Batch job started at {datetime.now()}")
    
    # Run both types of processing
    cpu_result = cpu_intensive_task(5)
    memory_result = memory_intensive_task(500000)
    
    print(f"Batch job completed at {datetime.now()}")
    print(f"Results: CPU hash length: {len(str(cpu_result))}, Memory stats: {memory_result}")
EOF

chmod +x /opt/sample_batch_job.py

# Log the deployment
echo "$(date): Worker tier right-sizing demo deployed on ${instance_type}" >> /var/log/deployment.log
echo "Worker endpoint: http://localhost:5000" >> /var/log/deployment.log
echo "Estimated monthly cost: $${estimated_cost}" >> /var/log/deployment.log
echo "Optimization: ${optimization_notes}" >> /var/log/deployment.log