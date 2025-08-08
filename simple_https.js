const https = require('https');
const http = require('http');
const fs = require('fs');

// Simple HTTPS setup without external dependencies
const options = {
    key: fs.readFileSync('key.pem'),
    cert: fs.readFileSync('cert.pem')
};

const FLUTTER_PORT = 43218;
const HTTPS_PORT = 8443;

console.log('🔒 Starting Simple HTTPS Server for Eventura...');
console.log('📡 Your IP: 192.168.100.78');
console.log('🌐 HTTPS URL: https://192.168.100.78:8443');

// Simple HTTPS server
const server = https.createServer(options, (req, res) => {
    // Redirect to Flutter app
    res.writeHead(302, {
        'Location': `http://192.168.100.78:${FLUTTER_PORT}${req.url}`
    });
    res.end();
});

server.listen(HTTPS_PORT, '0.0.0.0', () => {
    console.log(`✅ HTTPS Server running on port ${HTTPS_PORT}`);
    console.log(`🚀 Access Eventura via: https://192.168.100.78:8443`);
    console.log(`📱 Multi-device access ready!`);
});

// Also create a simple landing page
const landingServer = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Eventura - Fast Multi-Device Access</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: Arial, sans-serif; text-align: center; padding: 20px; background: #f5f5f5; }
                .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                .button { background: #006B3C; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 10px; display: inline-block; font-weight: bold; }
                .url { background: #f0f0f0; padding: 10px; border-radius: 5px; font-family: monospace; margin: 10px; border: 1px solid #ddd; }
                .success { color: #006B3C; font-weight: bold; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎯 Eventura - Fast Multi-Device Access</h1>
                <p class="success">✅ Ready for multiple devices!</p>
                
                <h3>Quick Access URLs:</h3>
                <div class="url">https://192.168.100.78:8443</div>
                <div class="url">http://192.168.100.78:43218</div>
                
                <h3>📱 Multi-Device Instructions:</h3>
                <p>1. Open any browser on any device</p>
                <p>2. Type one of the URLs above</p>
                <p>3. All devices can access simultaneously!</p>
                
                <h3>🔑 Login Credentials:</h3>
                <p><strong>User ID:</strong> 22-4957-735</p>
                <p><strong>Password:</strong> KYLO.omni0</p>
                
                <h3>🚀 Test Now:</h3>
                <a href="https://192.168.100.78:8443" class="button">🔒 HTTPS Access</a>
                <a href="http://192.168.100.78:43218" class="button">🌐 HTTP Access</a>
            </div>
        </body>
        </html>
    `);
});

landingServer.listen(8080, '0.0.0.0', () => {
    console.log(`✅ Landing page running on port 8080`);
    console.log(`🌐 Access via: http://192.168.100.78:8080`);
}); 