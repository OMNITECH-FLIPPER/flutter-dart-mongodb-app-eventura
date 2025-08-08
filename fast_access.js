const http = require('http');

const FLUTTER_PORT = 43218;
const BACKEND_PORT = 42952;
const ACCESS_PORT = 8080;

console.log('🚀 Starting Fast Multi-Device Access for Eventura...');
console.log('📡 Your IP: 192.168.100.78');

// Fast access server
const server = http.createServer((req, res) => {
    res.writeHead(200, { 
        'Content-Type': 'text/html',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'no-cache'
    });
    
    res.end(`
        <!DOCTYPE html>
        <html>
        <head>
            <title>Eventura - Fast Multi-Device Access</title>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { 
                    font-family: 'Segoe UI', Arial, sans-serif; 
                    text-align: center; 
                    padding: 20px; 
                    background: linear-gradient(135deg, #006B3C, #004d2b);
                    margin: 0;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                .container { 
                    max-width: 600px; 
                    background: white; 
                    padding: 40px; 
                    border-radius: 15px; 
                    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                }
                .button { 
                    background: #006B3C; 
                    color: white; 
                    padding: 15px 30px; 
                    text-decoration: none; 
                    border-radius: 8px; 
                    margin: 10px; 
                    display: inline-block; 
                    font-weight: bold;
                    transition: all 0.3s ease;
                }
                .button:hover {
                    background: #004d2b;
                    transform: translateY(-2px);
                }
                .url { 
                    background: #f8f9fa; 
                    padding: 12px; 
                    border-radius: 8px; 
                    font-family: monospace; 
                    margin: 10px; 
                    border: 2px solid #006B3C;
                    font-size: 14px;
                }
                .success { 
                    color: #006B3C; 
                    font-weight: bold; 
                    font-size: 18px;
                }
                .title {
                    color: #006B3C;
                    font-size: 2.5em;
                    margin-bottom: 10px;
                }
                .subtitle {
                    color: #666;
                    margin-bottom: 30px;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1 class="title">🎯 Eventura</h1>
                <p class="subtitle">Fast Multi-Device Access</p>
                <p class="success">✅ Ready for multiple devices!</p>
                
                <h3>Quick Access URLs:</h3>
                <div class="url">http://192.168.100.78:43218</div>
                <div class="url">http://192.168.100.78:8080</div>
                
                <h3>📱 Multi-Device Instructions:</h3>
                <p>1. Open any browser on any device</p>
                <p>2. Type: <strong>192.168.100.78:43218</strong></p>
                <p>3. All devices can access simultaneously!</p>
                
                <h3>🔑 Login Credentials:</h3>
                <p><strong>User ID:</strong> 22-4957-735</p>
                <p><strong>Password:</strong> KYLO.omni0</p>
                
                <h3>🚀 Test Now:</h3>
                <a href="http://192.168.100.78:43218" class="button">🌐 Access Eventura</a>
                
                <h3>📊 Status:</h3>
                <p>✅ Flutter App: Running on port 43218</p>
                <p>✅ Backend API: Running on port 42952</p>
                <p>✅ Multi-device access: Enabled</p>
            </div>
        </body>
        </html>
    `);
});

server.listen(ACCESS_PORT, '0.0.0.0', () => {
    console.log(`✅ Fast access server running on port ${ACCESS_PORT}`);
    console.log(`🚀 Access Eventura via: http://192.168.100.78:43218`);
    console.log(`📱 Multi-device access ready!`);
    console.log(`🌐 Landing page: http://192.168.100.78:8080`);
}); 