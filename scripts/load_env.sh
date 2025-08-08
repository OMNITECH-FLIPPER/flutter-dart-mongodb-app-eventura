#!/bin/bash

# Eventura Flutter App Environment Variable Loader for Unix/Linux/macOS
# This script reads a .env file and converts environment variables to Flutter's --dart-define format.

set -e

# Default values
ENV_FILE=".env"
SHOW_ENV=false

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] <flutter_command> [flutter_args...]"
    echo ""
    echo "Options:"
    echo "  --env-file FILE    Path to .env file (default: .env)"
    echo "  --show-env         Show loaded environment variables"
    echo "  -h, --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 run"
    echo "  $0 build apk"
    echo "  $0 --show-env run"
    echo "  $0 --env-file .env.production build apk"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        --show-env)
            SHOW_ENV=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check if Flutter command is provided
if [ $# -eq 0 ]; then
    echo "Error: Flutter command is required"
    show_usage
    exit 1
fi

# Get the project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE_PATH="$PROJECT_ROOT/$ENV_FILE"

# Function to load environment variables from .env file
load_env_file() {
    local env_file="$1"
    local env_vars=()
    
    if [ ! -f "$env_file" ]; then
        echo "Warning: $env_file not found. Using default values." >&2
        return
    fi
    
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Parse key=value pairs
        if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            value="${BASH_REMATCH[2]}"
            
            # Remove leading/trailing whitespace
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs)
            
            # Remove quotes if present
            if [[ "$value" =~ ^\"(.*)\"$ ]] || [[ "$value" =~ ^\'(.*)\'$ ]]; then
                value="${BASH_REMATCH[1]}"
            fi
            
            env_vars+=("$key=$value")
        fi
    done < "$env_file"
    
    echo "${env_vars[@]}"
}

# Function to build dart-define arguments
build_dart_define_args() {
    local env_vars=("$@")
    local dart_defines=()
    
    for env_var in "${env_vars[@]}"; do
        IFS='=' read -r key value <<< "$env_var"
        dart_defines+=("--dart-define=$key=$value")
    done
    
    echo "${dart_defines[@]}"
}

# Function to mask sensitive values
mask_sensitive_value() {
    local value="$1"
    local length=${#value}
    
    if [ $length -gt 8 ]; then
        echo "${value:0:4}${value: -4}" | sed 's/./*/g'
    else
        echo "****"
    fi
}

# Main execution
echo "Loading environment variables from: $ENV_FILE_PATH"

# Load environment variables
env_vars=($(load_env_file "$ENV_FILE_PATH"))

if [ "$SHOW_ENV" = true ]; then
    echo "Loaded environment variables:"
    for env_var in "${env_vars[@]}"; do
        IFS='=' read -r key value <<< "$env_var"
        
        # Mask sensitive values
        if [[ "$key" =~ password|secret|key ]]; then
            masked_value=$(mask_sensitive_value "$value")
            echo "  $key=$masked_value"
        else
            echo "  $key=$value"
        fi
    done
    echo ""
fi

# Convert to dart-define format
dart_defines=($(build_dart_define_args "${env_vars[@]}"))

# Build the full Flutter command
flutter_cmd=("flutter" "$@")
full_cmd=("${flutter_cmd[@]}" "${dart_defines[@]}")

echo "Running: ${full_cmd[*]}"

# Run Flutter command
if ! "${full_cmd[@]}"; then
    echo "Error: Flutter command failed" >&2
    exit 1
fi 