# Eventura Hostname Setup Script
# Makes EVENTURA accessible from Android devices

Write-Host "🎯 Setting up EVENTURA hostname for Android access..." -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Get the current IP address
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"} | Select-Object -First 1).IPAddress

if (-not $ipAddress) {
    Write-Host "❌ Could not find local IP address" -ForegroundColor Red
    exit 1
}

Write-Host "📡 Found local IP: $ipAddress" -ForegroundColor Yellow

# Hosts file path
$hostsPath = "$env:windir\System32\drivers\etc\hosts"

# Check if EVENTURA entry already exists
$hostsContent = Get-Content $hostsPath
$eventuraEntry = $hostsContent | Where-Object { $_ -like "*EVENTURA*" }

if ($eventuraEntry) {
    Write-Host "⚠️  EVENTURA entry already exists in hosts file" -ForegroundColor Yellow
    Write-Host "Current entry: $eventuraEntry" -ForegroundColor Cyan
} else {
    # Add the EVENTURA entry
    $newEntry = "$ipAddress EVENTURA"
    Add-Content -Path $hostsPath -Value $newEntry
    Write-Host "✅ Added EVENTURA to hosts file" -ForegroundColor Green
    Write-Host "Entry: $newEntry" -ForegroundColor Cyan
}

Write-Host "`n🌐 Eventura will be available at:" -ForegroundColor Green
Write-Host "   Flutter App: http://EVENTURA:43218" -ForegroundColor Cyan
Write-Host "   Backend API: http://EVENTURA:42952" -ForegroundColor Cyan
Write-Host "   Health Check: http://EVENTURA:42952/health" -ForegroundColor Cyan

Write-Host "`n📱 Instructions for Android Chrome:" -ForegroundColor Green
Write-Host "   1. Make sure your Android device is on the same WiFi network" -ForegroundColor White
Write-Host "   2. Open Google Chrome on your Android device" -ForegroundColor White
Write-Host "   3. In the address bar, type: EVENTURA" -ForegroundColor Cyan
Write-Host "   4. Chrome will automatically add http:// and :43218" -ForegroundColor White
Write-Host "   5. The Eventura introduction page will load!" -ForegroundColor White
Write-Host "   6. Swipe through the introduction and click 'Get Started'" -ForegroundColor White
Write-Host "   7. Login with admin credentials: 22-4957-735 / KYLO.omni0" -ForegroundColor White

Write-Host "`n🔍 Alternative access methods:" -ForegroundColor Green
Write-Host "   • Direct URL: http://EVENTURA:43218" -ForegroundColor White
Write-Host "   • IP Address: http://$ipAddress:43218" -ForegroundColor White
Write-Host "   • Local: http://localhost:43218" -ForegroundColor White

Write-Host "`n🔧 To test the connection, run: ping EVENTURA" -ForegroundColor Green 