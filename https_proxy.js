const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');

// Create self-signed certificate for HTTPS
const selfSigned = require('selfsigned');
const attrs = [{ name: 'commonName', value: 'eventura.local' }];
const pems = selfSigned.generate(attrs, { days: 365 });

// Write certificate files
fs.writeFileSync('cert.pem', pems.cert);
fs.writeFileSync('key.pem', pems.private);

const FLUTTER_PORT = 43218;
const BACKEND_PORT = 42952;
const HTTPS_PORT = 8443;

console.log('🔒 Starting HTTPS Proxy for Eventura...');
console.log('📡 Your IP: 192.168.100.78');
console.log('🌐 HTTPS URL: https://192.168.100.78:8443');

// HTTPS Proxy for Flutter App
const httpsServer = https.createServer({
    cert: pems.cert,
    key: pems.private
}, (req, res) => {
    const options = {
        hostname: 'localhost',
        port: FLUTTER_PORT,
        path: req.url,
        method: req.method,
        headers: req.headers
    };

    const proxyReq = http.request(options, (proxyRes) => {
        res.writeHead(proxyRes.statusCode, proxyRes.headers);
        proxyRes.pipe(res);
    });

    req.pipe(proxyReq);
});

httpsServer.listen(HTTPS_PORT, '0.0.0.0', () => {
    console.log(`✅ HTTPS Proxy running on port ${HTTPS_PORT}`);
    console.log(`🚀 Access Eventura via: https://192.168.100.78:8443`);
    console.log(`📱 Multi-device access ready!`);
});

// Also start HTTP server for fallback
const httpServer = http.createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Eventura - Multi-Device Access</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
                .button { background: #006B3C; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; margin: 10px; display: inline-block; }
                .url { background: #f0f0f0; padding: 10px; border-radius: 5px; font-family: monospace; margin: 10px; }
            </style>
        </head>
        <body>
            <h1>🎯 Eventura Multi-Device Access</h1>
            <p>Choose your preferred access method:</p>
            
            <a href="https://192.168.100.78:8443" class="button">🔒 HTTPS (Recommended)</a>
            <a href="http://192.168.100.78:43218" class="button">🌐 HTTP</a>
            
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
        </body>
        </html>
    `);
});

httpServer.listen(8080, '0.0.0.0', () => {
    console.log(`✅ HTTP Server running on port 8080`);
    console.log(`🌐 Access via: http://192.168.100.78:8080`);
}); 