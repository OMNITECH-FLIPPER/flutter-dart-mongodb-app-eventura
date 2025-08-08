# Quick Multi-Device Access Test for Eventura

Write-Host "🚀 Quick Eventura Multi-Device Test" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Get IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"} | Select-Object -First 1).IPAddress

Write-Host "`n📡 Your IP: $ip" -ForegroundColor Cyan

# Test URLs
$flutterUrl = "http://$ip:43218"
$backendUrl = "http://$ip:42952/health"

Write-Host "`n🌐 Access URLs:" -ForegroundColor Yellow
Write-Host "   Flutter App: $flutterUrl" -ForegroundColor Green
Write-Host "   Backend API: $backendUrl" -ForegroundColor Green

Write-Host "`n📱 Multi-Device Instructions:" -ForegroundColor Yellow
Write-Host "   1. Open any browser on any device" -ForegroundColor White
Write-Host "   2. Type: $flutterUrl" -ForegroundColor Cyan
Write-Host "   3. All devices can access simultaneously!" -ForegroundColor White

Write-Host "`n✅ Ready for multi-device access!" -ForegroundColor Green 