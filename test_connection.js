const http = require('http');

console.log('🔍 Testing Eventura Connection...');
console.log('================================');

// Test local connection first
const testLocal = () => {
    console.log('\n📡 Testing local connections...');
    
    // Test backend
    const backendReq = http.get('http://localhost:42952/health', (res) => {
        console.log('✅ Backend API: Running on localhost:42952');
    }).on('error', (err) => {
        console.log('❌ Backend API: Not running on localhost:42952');
    });
    
    // Test Flutter
    const flutterReq = http.get('http://localhost:43218', (res) => {
        console.log('✅ Flutter App: Running on localhost:43218');
    }).on('error', (err) => {
        console.log('❌ Flutter App: Not running on localhost:43218');
    });
    
    // Test landing page
    const landingReq = http.get('http://localhost:8080', (res) => {
        console.log('✅ Landing Page: Running on localhost:8080');
    }).on('error', (err) => {
        console.log('❌ Landing Page: Not running on localhost:8080');
    });
};

// Test network connection
const testNetwork = () => {
    console.log('\n🌐 Testing network connections...');
    
    const ip = '192.168.100.78';
    
    // Test backend
    const backendReq = http.get(`http://${ip}:42952/health`, (res) => {
        console.log(`✅ Backend API: Accessible via ${ip}:42952`);
    }).on('error', (err) => {
        console.log(`❌ Backend API: Not accessible via ${ip}:42952`);
    });
    
    // Test Flutter
    const flutterReq = http.get(`http://${ip}:43218`, (res) => {
        console.log(`✅ Flutter App: Accessible via ${ip}:43218`);
    }).on('error', (err) => {
        console.log(`❌ Flutter App: Not accessible via ${ip}:43218`);
    });
    
    // Test landing page
    const landingReq = http.get(`http://${ip}:8080`, (res) => {
        console.log(`✅ Landing Page: Accessible via ${ip}:8080`);
    }).on('error', (err) => {
        console.log(`❌ Landing Page: Not accessible via ${ip}:8080`);
    });
};

// Run tests
testLocal();
setTimeout(testNetwork, 2000);

console.log('\n📱 Multi-Device Access URLs:');
console.log('   🌐 Flutter App: http://192.168.100.78:43218');
console.log('   🔧 Backend API: http://192.168.100.78:42952');
console.log('   🏠 Landing Page: http://192.168.100.78:8080');
console.log('\n🔑 Login: 22-4957-735 / KYLO.omni0'); 