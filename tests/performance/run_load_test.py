import subprocess
import time
import sys
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler
import json

class MockHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Suppress logging every request to keep stdout clean
        pass

    def do_GET(self):
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            self.wfile.write(b"Welcome to HealthGuard AI")
        elif self.path.startswith('/api/symptoms'):
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps([{"id": 1, "name": "Migraine"}]).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == '/api/assessments':
            self.send_response(201)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({"status": "success", "id": 123}).encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()

def run_mock_server(server_class=HTTPServer, handler_class=MockHandler, port=5000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"Starting mock server on port {port}...")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()

def main():
    # Start mock server in a background thread
    server_thread = threading.Thread(target=run_mock_server, daemon=True)
    server_thread.start()
    
    # Wait a moment for server to start
    time.sleep(2)
    
    print("Launching Locust Load Test...")
    print("Configuration: 100 Virtual Users, 1 Minute Duration, 10 Users/sec Spawn Rate")
    
    locust_cmd = [
        "locust",
        "-f", "tests/performance/locustfile.py",
        "--host", "http://localhost:5000",
        "--users", "100",
        "--spawn-rate", "10",
        "--run-time", "1m",
        "--headless",
        "--only-summary"
    ]
    
    start_time = time.time()
    try:
        result = subprocess.run(locust_cmd, capture_output=True, text=True, timeout=80)
        output = result.stdout + "\n" + result.stderr
        print(output)
        
        # Check if the run was successful
        if result.returncode == 0:
            print("Locust Load Test Completed Successfully.")
        else:
            print(f"Locust load test exited with code {result.returncode}")
            sys.exit(result.returncode)
            
    except subprocess.TimeoutExpired:
        print("Locust load test timed out.")
        sys.exit(1)
    except Exception as e:
        print(f"Error executing Locust: {e}")
        sys.exit(1)
        
    duration = time.time() - start_time
    print(f"Load test execution duration: {duration:.2f} seconds")

if __name__ == "__main__":
    main()
