const http = require('http');

console.log('🔍 Quick Status Check for Eventura Multi-Device Access...');
console.log('=====================================================');

const services = [
    { name: 'Flutter App', url: 'http://192.168.100.78:43218', port: 43218 },
    { name: 'Backend API', url: 'http://192.168.100.78:42952/health', port: 42952 },
    { name: 'Landing Page', url: 'http://192.168.100.78:8080', port: 8080 }
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
            console.log('   🔧 Backend API: http://192.168.100.78:42952');
            console.log('   🏠 Landing Page: http://192.168.100.78:8080');
            console.log('\n🚀 Ready for multiple devices!');
        }
    }).on('error', (err) => {
        console.log(`❌ ${service.name}: Not running on port ${service.port}`);
        checked++;
        if (checked === services.length) {
            console.log('\n⚠️  Some services may not be running.');
            console.log('   Start them with: npm start && flutter run -d chrome --web-hostname 0.0.0.0 --web-port 43218');
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