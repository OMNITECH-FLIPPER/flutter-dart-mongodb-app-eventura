# Eventura App Environment Setup Script
# This script helps you configure environment variables for the Flutter app

Write-Host "=== Eventura App Environment Setup ===" -ForegroundColor Green
Write-Host ""

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter from https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Choose your database configuration:" -ForegroundColor Cyan
Write-Host "1. Local MongoDB (localhost:27017)" -ForegroundColor White
Write-Host "2. MongoDB Atlas (cloud)" -ForegroundColor White
Write-Host "3. Web development (mock mode)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1-3)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=== Local MongoDB Setup ===" -ForegroundColor Green
        
        # Check if MongoDB is running locally
        try {
            $mongoStatus = Get-Service -Name "MongoDB" -ErrorAction SilentlyContinue
            if ($mongoStatus -and $mongoStatus.Status -eq "Running") {
                Write-Host "✅ MongoDB service is running" -ForegroundColor Green
            } else {
                Write-Host "⚠️  MongoDB service not found or not running" -ForegroundColor Yellow
                Write-Host "Please install and start MongoDB locally" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "⚠️  Could not check MongoDB service status" -ForegroundColor Yellow
        }
        
        $mongoUrl = "mongodb://localhost:27017/eventura"
        Write-Host "Using MongoDB URL: $mongoUrl" -ForegroundColor Cyan
    }
    "2" {
        Write-Host ""
        Write-Host "=== MongoDB Atlas Setup ===" -ForegroundColor Green
        
        Write-Host "Please provide your MongoDB Atlas connection string:" -ForegroundColor Yellow
        Write-Host "Format: mongodb+srv://username:password@cluster.mongodb.net/database" -ForegroundColor Gray
        
        $mongoUrl = Read-Host "Enter your MongoDB Atlas connection string"
        
        if ($mongoUrl -eq "") {
            Write-Host "❌ No connection string provided" -ForegroundColor Red
            exit 1
        }
    }
    "3" {
        Write-Host ""
        Write-Host "=== Web Development Setup ===" -ForegroundColor Green
        Write-Host "Using mock mode for web development" -ForegroundColor Cyan
        $mongoUrl = "mongodb://localhost:27017/eventura"  # Will be ignored on web
    }
    default {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Environment Configuration ===" -ForegroundColor Green

# Create environment configuration
$envConfig = @"
# Eventura App Environment Configuration
# Generated on $(Get-Date)

# MongoDB Configuration
MONGO_URL=$mongoUrl
COLLECTION_NAME=users

# App Configuration
APP_NAME=Eventura
APP_VERSION=1.0.0

# API Configuration
API_BASE_URL=http://localhost:3000
CONNECTION_TIMEOUT=30000
REQUEST_TIMEOUT=10000

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
"@

# Save to file
$envConfig | Out-File -FilePath "env_config.txt" -Encoding UTF8
Write-Host "✅ Environment configuration saved to env_config.txt" -ForegroundColor Green

Write-Host ""
Write-Host "=== Running Flutter App ===" -ForegroundColor Green

# Change to the Flutter app directory
Set-Location "eventura_app_flutter_code"

# Get dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Cyan
flutter pub get

# Run the app with environment variables
Write-Host "Starting Flutter app..." -ForegroundColor Cyan
Write-Host "Use the following command to run with custom environment:" -ForegroundColor Yellow
Write-Host "flutter run --dart-define=MONGO_URL=`"$mongoUrl`"" -ForegroundColor White

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "You can now run the app using:" -ForegroundColor Cyan
Write-Host "flutter run" -ForegroundColor White
Write-Host "or" -ForegroundColor White
Write-Host "flutter run --dart-define=MONGO_URL=`"$mongoUrl`"" -ForegroundColor White 