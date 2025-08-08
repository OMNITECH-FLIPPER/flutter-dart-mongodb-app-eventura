# Eventura Network Setup Script
# Shows all available IP addresses and network interfaces

Write-Host "🌐 Eventura Network Configuration" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green

# Get all network interfaces
$networkInterfaces = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -like "192.168.*" -or 
    $_.IPAddress -like "10.*" -or 
    $_.IPAddress -like "172.*" -or
    $_.IPAddress -like "169.254.*"
}

if ($networkInterfaces) {
    Write-Host "`n📡 Available Network Interfaces:" -ForegroundColor Yellow
    
    $interfaceCount = 0
    foreach ($interface in $networkInterfaces) {
        $interfaceCount++
        Write-Host "`n$interfaceCount. Interface: $($interface.InterfaceAlias)" -ForegroundColor Cyan
        Write-Host "   IP Address: $($interface.IPAddress)" -ForegroundColor White
        Write-Host "   Subnet Mask: $($interface.PrefixLength)" -ForegroundColor White
        
        # Show access URLs for this interface
        Write-Host "   Access URLs:" -ForegroundColor Yellow
        Write-Host "     • Flutter App: http://$($interface.IPAddress):43218" -ForegroundColor Green
        Write-Host "     • Backend API: http://$($interface.IPAddress):42952" -ForegroundColor Green
        Write-Host "     • Health Check: http://$($interface.IPAddress):42952/health" -ForegroundColor Green
    }
    
    Write-Host "`n🚀 Primary Access Points:" -ForegroundColor Green
    Write-Host "   Local (this device):" -ForegroundColor Yellow
    Write-Host "     • Flutter App: http://localhost:43218" -ForegroundColor White
    Write-Host "     • Backend API: http://localhost:42952" -ForegroundColor White
    
    Write-Host "`n   Network (other devices):" -ForegroundColor Yellow
    foreach ($interface in $networkInterfaces) {
        Write-Host "     • Via $($interface.InterfaceAlias): http://$($interface.IPAddress):43218" -ForegroundColor White
    }
    
} else {
    Write-Host "❌ No network interfaces found" -ForegroundColor Red
}

# Show system information
Write-Host "`n💻 System Information:" -ForegroundColor Green
$computerName = $env:COMPUTERNAME
Write-Host "   Computer Name: $computerName" -ForegroundColor White

# Show firewall status
Write-Host "`n🔒 Firewall Status:" -ForegroundColor Green
$firewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled
foreach ($profile in $firewallStatus) {
    $status = $profile.Enabled ? "Enabled" : "Disabled"
    $color = $profile.Enabled ? "Red" : "Green"
    Write-Host "   $($profile.Name): $status" -ForegroundColor $color
}

# Show port status
Write-Host "`n🔌 Port Status:" -ForegroundColor Green
$ports = @(43218, 42952)
foreach ($port in $ports) {
    $listening = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($listening) {
        Write-Host "   Port ${port}: Listening" -ForegroundColor Green
    } else {
        Write-Host "   Port ${port}: Not listening" -ForegroundColor Red
    }
}

Write-Host "`n📱 Instructions for Other Devices:" -ForegroundColor Green
Write-Host "   1. Make sure the device is on the same network" -ForegroundColor White
Write-Host "   2. Open any web browser (Chrome, Safari, Firefox, Edge)" -ForegroundColor White
Write-Host "   3. Navigate to any of the IP addresses shown above" -ForegroundColor White
Write-Host "   4. The Eventura introduction page will load first" -ForegroundColor White
Write-Host "   5. Swipe through the introduction and click 'Get Started'" -ForegroundColor White
Write-Host "   6. Login with admin credentials: 22-4957-735 / KYLO.omni0" -ForegroundColor White

Write-Host "`n🔧 Troubleshooting:" -ForegroundColor Green
Write-Host "   • If devices can't connect, check Windows Firewall" -ForegroundColor White
Write-Host "   • Allow ports 43218 and 42952 through firewall" -ForegroundColor White
Write-Host "   • Ensure devices are on the same WiFi network" -ForegroundColor White
Write-Host "   • Try different IP addresses if one doesn't work" -ForegroundColor White

Write-Host "`n🎉 Eventura is now accessible from all devices on your network!" -ForegroundColor Green 