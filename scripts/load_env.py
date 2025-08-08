#!/usr/bin/env python3
"""
Environment Variable Loader for Eventura Flutter App
This script reads a .env file and converts environment variables to Flutter's --dart-define format.
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path

def load_env_file(env_file_path):
    """Load environment variables from .env file."""
    env_vars = {}
    
    if not os.path.exists(env_file_path):
        print(f"Warning: {env_file_path} not found. Using default values.")
        return env_vars
    
    with open(env_file_path, 'r') as file:
        for line in file:
            line = line.strip()
            # Skip empty lines and comments
            if not line or line.startswith('#'):
                continue
            
            # Parse key=value pairs
            if '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip()
                
                # Remove quotes if present
                if (value.startswith('"') and value.endswith('"')) or \
                   (value.startswith("'") and value.endswith("'")):
                    value = value[1:-1]
                
                env_vars[key] = value
    
    return env_vars

def build_dart_define_args(env_vars):
    """Convert environment variables to --dart-define arguments."""
    dart_defines = []
    
    for key, value in env_vars.items():
        # Convert to Dart define format
        dart_defines.append(f"--dart-define={key}={value}")
    
    return dart_defines

def run_flutter_command(command, dart_defines):
    """Run Flutter command with dart-define arguments."""
    full_command = ['flutter'] + command + dart_defines
    print(f"Running: {' '.join(full_command)}")
    
    try:
        subprocess.run(full_command, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error running Flutter command: {e}")
        sys.exit(1)
    except FileNotFoundError:
        print("Error: Flutter not found. Make sure Flutter is installed and in your PATH.")
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Load environment variables and run Flutter commands')
    parser.add_argument('command', nargs='+', help='Flutter command to run (e.g., run, build apk)')
    parser.add_argument('--env-file', default='.env', help='Path to .env file (default: .env)')
    parser.add_argument('--show-env', action='store_true', help='Show loaded environment variables')
    
    args = parser.parse_args()
    
    # Get the project root directory
    project_root = Path(__file__).parent.parent
    env_file_path = project_root / args.env_file
    
    # Load environment variables
    env_vars = load_env_file(env_file_path)
    
    if args.show_env:
        print("Loaded environment variables:")
        for key, value in env_vars.items():
            # Mask sensitive values
            if 'password' in key.lower() or 'secret' in key.lower() or 'key' in key.lower():
                masked_value = value[:4] + '*' * (len(value) - 8) + value[-4:] if len(value) > 8 else '****'
                print(f"  {key}={masked_value}")
            else:
                print(f"  {key}={value}")
        print()
    
    # Convert to dart-define format
    dart_defines = build_dart_define_args(env_vars)
    
    # Run Flutter command
    run_flutter_command(args.command, dart_defines)

if __name__ == '__main__':
    main() 