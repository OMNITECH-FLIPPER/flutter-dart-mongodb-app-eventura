# Eventura Network Information Script
# Shows how to access Eventura from other devices

Write-Host "🌐 Eventura Network Access Information" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Get network information
$networkInfo = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -like "192.168.*" -or 
    $_.IPAddress -like "10.*" -or 
    $_.IPAddress -like "172.*"
} | Select-Object -First 1

if ($networkInfo) {
    $ipAddress = $networkInfo.IPAddress
    $interface = $networkInfo.InterfaceAlias
    
    Write-Host "`n📡 Network Interface: $interface" -ForegroundColor Yellow
    Write-Host "🌍 Your IP Address: $ipAddress" -ForegroundColor Cyan
    
    Write-Host "`n🚀 Eventura Access URLs:" -ForegroundColor Green
    Write-Host "   Local (this device):" -ForegroundColor Yellow
    Write-Host "     • Flutter App: http://eventura.local:43218" -ForegroundColor White
    Write-Host "     • Backend API: http://eventura.local:42952" -ForegroundColor White
    Write-Host "     • Health Check: http://eventura.local:42952/health" -ForegroundColor White
    
    Write-Host "`n   Network (other devices):" -ForegroundColor Yellow
    Write-Host "     • Flutter App: http://$ipAddress:43218" -ForegroundColor White
    Write-Host "     • Backend API: http://$ipAddress:42952" -ForegroundColor White
    Write-Host "     • Health Check: http://$ipAddress:42952/health" -ForegroundColor White
    
    Write-Host "`n📱 Instructions for other devices:" -ForegroundColor Green
    Write-Host "   1. Make sure the device is on the same network" -ForegroundColor White
    Write-Host "   2. Open a web browser" -ForegroundColor White
    Write-Host "   3. Navigate to: http://$ipAddress:43218" -ForegroundColor Cyan
    Write-Host "   4. The Eventura app will load" -ForegroundColor White
    
    Write-Host "`n🔧 To start Eventura services:" -ForegroundColor Green
    Write-Host "   • Backend: npm start" -ForegroundColor White
    Write-Host "   • Flutter: flutter run -d chrome --web-hostname 0.0.0.0 --web-port 43218" -ForegroundColor White
    
} else {
    Write-Host "❌ Could not find network interface" -ForegroundColor Red
}

Write-Host "`n🔍 Troubleshooting:" -ForegroundColor Green
Write-Host "   • Check Windows Firewall settings" -ForegroundColor White
Write-Host "   • Ensure ports 42952 and 43218 are open" -ForegroundColor White
Write-Host "   • Verify devices are on the same network" -ForegroundColor White 