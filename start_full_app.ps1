# Start both backend and frontend servers for Eventura
Write-Host "Starting Eventura Full Stack Application..." -ForegroundColor Green

# Kill any existing processes
Write-Host "Stopping any existing processes..." -ForegroundColor Yellow
try {
    taskkill /f /im node.exe 2>$null
    Write-Host "Stopped existing Node.js processes"
} catch {
    Write-Host "No existing Node.js processes found"
}

# Start the backend server
Write-Host "Starting backend server..." -ForegroundColor Cyan
Start-Process -FilePath "node" -ArgumentList "server.js" -WindowStyle Minimized

# Wait for backend to start
Write-Host "Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Test backend health
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/health" -Method Get
    Write-Host "Backend server is running on port 3000" -ForegroundColor Green
    Write-Host "   Status: $($response.status)" -ForegroundColor White
} catch {
    Write-Host "Backend server failed to start" -ForegroundColor Red
    exit 1
}

# Start Flutter web
Write-Host "Starting Flutter web app..." -ForegroundColor Cyan
Write-Host "This will open Chrome automatically..." -ForegroundColor Yellow
Write-Host "" -ForegroundColor White

# Start Flutter with specific web port
flutter run -d chrome --web-port 8080

Write-Host "Flutter app started successfully!" -ForegroundColor Green
Write-Host "Backend API: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:8080" -ForegroundColor Cyan
