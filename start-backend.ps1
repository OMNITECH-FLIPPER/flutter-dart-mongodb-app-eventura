Write-Host "Starting Eventura Backend Server..." -ForegroundColor Green
$backendPath = "C:\EVENTURA APP\eventura_app_flutter_code\backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; Write-Host 'Starting Eventura Backend Server...' -ForegroundColor Yellow; npm run dev"
Write-Host "Backend server is starting in a new PowerShell window..." -ForegroundColor Green
Write-Host "The server will be available at: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Health check endpoint: http://localhost:3000/health" -ForegroundColor Cyan
Write-Host "API base URL: http://localhost:3000/api" -ForegroundColor Cyan
