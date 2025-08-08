const http = require('http');

console.log('🔍 Eventura Status Check - CORRECT PORTS');
console.log('=======================================');

const services = [
    { name: 'Backend API', url: 'http://localhost:3000/health', port: 3000 },
    { name: 'Flutter App', url: 'http://localhost:43218', port: 43218 },
    { name: 'Landing Page', url: 'http://localhost:8080', port: 8080 }
];

let checked = 0;

services.forEach(service => {
    const req = http.get(service.url, (res) => {
        console.log(`✅ ${service.name}: Running on port ${service.port}`);
        checked++;
        if (checked === services.length) {
            console.log('\n🎉 All services are running!');
            console.log('\n📱 Multi-Device Access URLs:');
            console.log('   🌐 Flutter App: http://192.168.100.78:43218');
            console.log('   🔧 Backend API: http://192.168.100.78:3000');
            console.log('   🏠 Landing Page: http://192.168.100.78:8080');
            console.log('\n🚀 Ready for multiple devices!');
            console.log('\n🔑 Login: 22-4957-735 / KYLO.omni0');
        }
    }).on('error', (err) => {
        console.log(`❌ ${service.name}: Not running on port ${service.port}`);
        checked++;
        if (checked === services.length) {
            console.log('\n⚠️  Some services may not be running.');
        }
    });
    
    req.setTimeout(3000, () => {
        console.log(`⏰ ${service.name}: Timeout on port ${service.port}`);
        req.destroy();
        checked++;
        if (checked === services.length) {
            console.log('\n⚠️  Some services may not be running.');
        }
    });
}); 