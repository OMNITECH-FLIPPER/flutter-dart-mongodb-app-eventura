# Full Stack Runner for Eventura App (Windows)
# This script runs both the Node.js backend server and Flutter app together.

param(
    [switch]$InstallOnly,
    [switch]$ServerOnly,
    [switch]$FlutterOnly
)

# Get the project root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Global variables
$ServerProcess = $null
$FlutterProcess = $null
$Running = $true

function Install-Dependencies {
    Write-Host "📦 Installing Node.js dependencies..." -ForegroundColor Cyan
    try {
        Set-Location $ProjectRoot
        npm install
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Node.js dependencies installed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Error installing Node.js dependencies" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error: $_" -ForegroundColor Red
        return $false
    }
}

function Start-Server {
    Write-Host "🚀 Starting Node.js server..." -ForegroundColor Cyan
    try {
        Set-Location $ProjectRoot
        $ServerProcess = Start-Process -FilePath "npm" -ArgumentList "start" -PassThru -NoNewWindow
        
        # Wait a bit for server to start
        Start-Sleep -Seconds 3
        
        if (-not $ServerProcess.HasExited) {
            Write-Host "✅ Node.js server started successfully on port 3000" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Failed to start Node.js server" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error starting server: $_" -ForegroundColor Red
        return $false
    }
}

function Start-FlutterApp {
    Write-Host "📱 Starting Flutter app..." -ForegroundColor Cyan
    try {
        Set-Location $ProjectRoot
        $FlutterScript = Join-Path $ProjectRoot "scripts\load_env.ps1"
        
        $FlutterProcess = Start-Process -FilePath "powershell" -ArgumentList "-File", $FlutterScript, "run" -PassThru -NoNewWindow
        
        Write-Host "✅ Flutter app started successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Error starting Flutter app: $_" -ForegroundColor Red
        return $false
    }
}

function Stop-Processes {
    Write-Host "`n🛑 Stopping processes..." -ForegroundColor Yellow
    $script:Running = $false
    
    if ($ServerProcess -and -not $ServerProcess.HasExited) {
        $ServerProcess.Kill()
        Write-Host "✅ Server process stopped" -ForegroundColor Green
    }
    
    if ($FlutterProcess -and -not $FlutterProcess.HasExited) {
        $FlutterProcess.Kill()
        Write-Host "✅ Flutter process stopped" -ForegroundColor Green
    }
}

function Show-Usage {
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  .\run_full_stack.ps1              - Run both server and Flutter app" -ForegroundColor White
    Write-Host "  .\run_full_stack.ps1 -InstallOnly - Install dependencies only" -ForegroundColor White
    Write-Host "  .\run_full_stack.ps1 -ServerOnly  - Run server only" -ForegroundColor White
    Write-Host "  .\run_full_stack.ps1 -FlutterOnly - Run Flutter app only" -ForegroundColor White
}

# Main execution
try {
    Write-Host "🎯 Eventura Full Stack Runner (Windows)" -ForegroundColor Green
    Write-Host "=========================================" -ForegroundColor Green
    
    if ($InstallOnly) {
        Install-Dependencies
        exit 0
    }
    
    if ($ServerOnly) {
        if (Install-Dependencies) {
            Start-Server
            Write-Host "`n🎉 Server is running!" -ForegroundColor Green
            Write-Host "📊 Health check: http://localhost:3000/health" -ForegroundColor Cyan
            Write-Host "🔗 API: http://localhost:3000/api" -ForegroundColor Cyan
            Write-Host "`nPress Ctrl+C to stop the server" -ForegroundColor Yellow
            
            try {
                while ($Running) {
                    Start-Sleep -Seconds 1
                }
            }
            catch {
                Write-Host "`n🛑 Stopping server..." -ForegroundColor Yellow
            }
            finally {
                Stop-Processes
            }
        }
        exit 0
    }
    
    if ($FlutterOnly) {
        Start-FlutterApp
        exit 0
    }
    
    # Full stack mode
    if (-not (Install-Dependencies)) {
        exit 1
    }
    
    if (-not (Start-Server)) {
        exit 1
    }
    
    if (-not (Start-FlutterApp)) {
        Stop-Processes
        exit 1
    }
    
    Write-Host "`n🎉 Full stack is running!" -ForegroundColor Green
    Write-Host "📊 Server: http://localhost:3000/health" -ForegroundColor Cyan
    Write-Host "🔗 API: http://localhost:3000/api" -ForegroundColor Cyan
    Write-Host "📱 Flutter app should open automatically" -ForegroundColor Cyan
    Write-Host "`nPress Ctrl+C to stop all processes" -ForegroundColor Yellow
    
    try {
        while ($Running) {
            Start-Sleep -Seconds 1
        }
    }
    catch {
        Write-Host "`n🛑 Stopping all processes..." -ForegroundColor Yellow
    }
    finally {
        Stop-Processes
    }
}
catch {
    Write-Host "❌ Script error: $_" -ForegroundColor Red
    Stop-Processes
    exit 1
} 