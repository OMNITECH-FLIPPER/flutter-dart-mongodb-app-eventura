#!/usr/bin/env python3
"""
Environment Setup Script for Eventura Flutter App
This script helps set up the .env file with actual values.
"""

import os
import shutil
import sys
from pathlib import Path

def setup_environment():
    """Set up the environment configuration."""
    # Get the project root directory
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    
    # Source and destination files
    source_file = project_root / "env_actual_values.txt"
    dest_file = project_root / ".env"
    
    print("🚀 Setting up Eventura Environment Configuration")
    print("=" * 50)
    
    # Check if source file exists
    if not source_file.exists():
        print(f"❌ Error: {source_file} not found!")
        print("Please ensure env_actual_values.txt exists in the project root.")
        return False
    
    # Check if .env already exists
    if dest_file.exists():
        print(f"⚠️  Warning: {dest_file} already exists!")
        response = input("Do you want to overwrite it? (y/N): ").strip().lower()
        if response != 'y':
            print("Setup cancelled.")
            return False
    
    try:
        # Copy the file
        shutil.copy2(source_file, dest_file)
        print(f"✅ Successfully created {dest_file}")
        
        # Show next steps
        print("\n📋 Next Steps:")
        print("1. Edit the .env file and update the following values:")
        print("   - SMTP_PASSWORD: Your Gmail app password")
        print("   - FIREBASE_API_KEY: Your Firebase API key (removed - using MongoDB notifications)")
        print("   - PUSH_SERVER_KEY: Your FCM server key")
        print("   - GA_TRACKING_ID: Your Google Analytics tracking ID")
        print("   - MIXPANEL_TOKEN: Your Mixpanel token")
        
        print("\n2. Test the configuration:")
        print("   Windows: .\\scripts\\load_env.ps1 --show-env run")
        print("   Unix/Mac: ./scripts/load_env.sh --show-env run")
        print("   Python: python scripts/load_env.py --show-env run")
        
        print("\n3. Run the app:")
        print("   Windows: .\\scripts\\load_env.ps1 run")
        print("   Unix/Mac: ./scripts/load_env.sh run")
        print("   Python: python scripts/load_env.py run")
        
        print("\n🔒 Security Note:")
        print("- Never commit the .env file to version control")
        print("- Keep your credentials secure")
        print("- Use different credentials for development and production")
        
        return True
        
    except Exception as e:
        print(f"❌ Error creating .env file: {e}")
        return False

def show_current_config():
    """Show the current configuration values."""
    project_root = Path(__file__).parent.parent
    env_file = project_root / ".env"
    
    if not env_file.exists():
        print("❌ No .env file found. Run setup first.")
        return
    
    print("📋 Current Environment Configuration:")
    print("=" * 40)
    
    with open(env_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                # Mask sensitive values
                if any(sensitive in key.lower() for sensitive in ['password', 'secret', 'key', 'token']):
                    if len(value) > 8:
                        masked_value = value[:4] + '*' * (len(value) - 8) + value[-4:]
                    else:
                        masked_value = '****'
                    print(f"  {key}={masked_value}")
                else:
                    print(f"  {key}={value}")

def main():
    """Main function."""
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == "setup":
            setup_environment()
        elif command == "show":
            show_current_config()
        elif command == "help":
            print("Usage:")
            print("  python setup_env.py setup  - Set up .env file")
            print("  python setup_env.py show   - Show current config")
            print("  python setup_env.py help   - Show this help")
        else:
            print(f"Unknown command: {command}")
            print("Use 'python setup_env.py help' for usage information.")
    else:
        # Default action
        setup_environment()

if __name__ == "__main__":
    main() 