# Eventura Hosts File Setup Script
# This script adds eventura.local to your hosts file

Write-Host "🔧 Setting up Eventura hosts file entry..." -ForegroundColor Green

# Get the current IP address
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.*"} | Select-Object -First 1).IPAddress

if (-not $ipAddress) {
    Write-Host "❌ Could not find local IP address" -ForegroundColor Red
    exit 1
}

Write-Host "📡 Found local IP: $ipAddress" -ForegroundColor Yellow

# Hosts file path
$hostsPath = "$env:windir\System32\drivers\etc\hosts"

# Check if entry already exists
$hostsContent = Get-Content $hostsPath
$entryExists = $hostsContent | Where-Object { $_ -like "*eventura.local*" }

if ($entryExists) {
    Write-Host "⚠️  Eventura entry already exists in hosts file" -ForegroundColor Yellow
    Write-Host "Current entry: $entryExists" -ForegroundColor Cyan
} else {
    # Add the entry
    $newEntry = "$ipAddress eventura.local"
    Add-Content -Path $hostsPath -Value $newEntry
    Write-Host "✅ Added eventura.local to hosts file" -ForegroundColor Green
    Write-Host "Entry: $newEntry" -ForegroundColor Cyan
}

Write-Host "`n🌐 Eventura will be available at:" -ForegroundColor Green
Write-Host "   Flutter App: http://eventura.local:43218" -ForegroundColor Cyan
Write-Host "   Backend API: http://eventura.local:42952" -ForegroundColor Cyan
Write-Host "   Health Check: http://eventura.local:42952/health" -ForegroundColor Cyan

Write-Host "`n📱 Other devices on your network can access it using your IP: $ipAddress" -ForegroundColor Yellow
Write-Host "   Flutter App: http://$ipAddress:43218" -ForegroundColor Cyan
Write-Host "   Backend API: http://$ipAddress:42952" -ForegroundColor Cyan

Write-Host "`n🔍 To test the connection, run: ping eventura.local" -ForegroundColor Green 