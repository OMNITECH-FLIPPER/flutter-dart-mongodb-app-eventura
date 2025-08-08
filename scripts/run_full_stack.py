#!/usr/bin/env python3
"""
Full Stack Runner for Eventura App
This script runs both the Node.js backend server and Flutter app together.
"""

import os
import sys
import subprocess
import time
import signal
import threading
from pathlib import Path

class FullStackRunner:
    def __init__(self):
        self.project_root = Path(__file__).parent.parent
        self.server_process = None
        self.flutter_process = None
        self.running = True
        
    def install_dependencies(self):
        """Install Node.js dependencies."""
        print("📦 Installing Node.js dependencies...")
        try:
            subprocess.run(['npm', 'install'], cwd=self.project_root, check=True)
            print("✅ Node.js dependencies installed successfully")
        except subprocess.CalledProcessError as e:
            print(f"❌ Error installing Node.js dependencies: {e}")
            return False
        except FileNotFoundError:
            print("❌ npm not found. Please install Node.js and npm.")
            return False
        return True
    
    def start_server(self):
        """Start the Node.js server."""
        print("🚀 Starting Node.js server...")
        try:
            self.server_process = subprocess.Popen(
                ['npm', 'start'],
                cwd=self.project_root,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            # Wait a bit for server to start
            time.sleep(3)
            
            if self.server_process.poll() is None:
                print("✅ Node.js server started successfully on port 3000")
                return True
            else:
                print("❌ Failed to start Node.js server")
                return False
                
        except Exception as e:
            print(f"❌ Error starting server: {e}")
            return False
    
    def start_flutter_app(self):
        """Start the Flutter app with environment variables."""
        print("📱 Starting Flutter app...")
        try:
            # Use the load_env script to start Flutter with environment variables
            flutter_script = self.project_root / 'scripts' / 'load_env.py'
            
            self.flutter_process = subprocess.Popen(
                [sys.executable, str(flutter_script), 'run'],
                cwd=self.project_root,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )
            
            print("✅ Flutter app started successfully")
            return True
            
        except Exception as e:
            print(f"❌ Error starting Flutter app: {e}")
            return False
    
    def monitor_processes(self):
        """Monitor both processes and print their output."""
        def monitor_server():
            if self.server_process:
                for line in self.server_process.stdout:
                    if self.running:
                        print(f"[SERVER] {line.rstrip()}")
                    else:
                        break
        
        def monitor_flutter():
            if self.flutter_process:
                for line in self.flutter_process.stdout:
                    if self.running:
                        print(f"[FLUTTER] {line.rstrip()}")
                    else:
                        break
        
        # Start monitoring threads
        server_thread = threading.Thread(target=monitor_server)
        flutter_thread = threading.Thread(target=monitor_flutter)
        
        server_thread.daemon = True
        flutter_thread.daemon = True
        
        server_thread.start()
        flutter_thread.start()
    
    def stop_processes(self):
        """Stop both processes gracefully."""
        print("\n🛑 Stopping processes...")
        self.running = False
        
        if self.server_process:
            self.server_process.terminate()
            try:
                self.server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.server_process.kill()
        
        if self.flutter_process:
            self.flutter_process.terminate()
            try:
                self.flutter_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.flutter_process.kill()
        
        print("✅ All processes stopped")
    
    def run(self):
        """Main run method."""
        print("🎯 Eventura Full Stack Runner")
        print("=" * 40)
        
        # Install dependencies
        if not self.install_dependencies():
            return False
        
        # Start server
        if not self.start_server():
            return False
        
        # Start Flutter app
        if not self.start_flutter_app():
            self.stop_processes()
            return False
        
        # Monitor processes
        self.monitor_processes()
        
        print("\n🎉 Full stack is running!")
        print("📊 Server: http://localhost:3000/health")
        print("🔗 API: http://localhost:3000/api")
        print("📱 Flutter app should open automatically")
        print("\nPress Ctrl+C to stop all processes")
        
        try:
            # Keep the main thread alive
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n🛑 Received interrupt signal")
        finally:
            self.stop_processes()
        
        return True

def main():
    runner = FullStackRunner()
    
    # Set up signal handlers
    def signal_handler(signum, frame):
        print(f"\n🛑 Received signal {signum}")
        runner.stop_processes()
        sys.exit(0)
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    success = runner.run()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main() 