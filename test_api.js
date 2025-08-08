const http = require('http');

const API_BASE = 'http://localhost:42952/api';

// Test function
async function testAPI() {
  console.log('🧪 Testing Eventura API...\n');

  // Test 1: Health check
  console.log('1️⃣ Testing Health Check:');
  try {
    const healthResponse = await makeRequest('/health');
    console.log('   ✅ Health check passed');
  } catch (e) {
    console.log('   ❌ Health check failed:', e.message);
  }

  // Test 2: Get users
  console.log('\n2️⃣ Testing Get Users:');
  try {
    const usersResponse = await makeRequest('/users');
    console.log(`   ✅ Found ${usersResponse.length} users`);
  } catch (e) {
    console.log('   ❌ Get users failed:', e.message);
  }

  // Test 3: Get events
  console.log('\n3️⃣ Testing Get Events:');
  try {
    const eventsResponse = await makeRequest('/events');
    console.log(`   ✅ Found ${eventsResponse.length} events`);
  } catch (e) {
    console.log('   ❌ Get events failed:', e.message);
  }

  // Test 4: Get registrations
  console.log('\n4️⃣ Testing Get Registrations:');
  try {
    const registrationsResponse = await makeRequest('/registrations');
    console.log(`   ✅ Found ${registrationsResponse.length} registrations`);
  } catch (e) {
    console.log('   ❌ Get registrations failed:', e.message);
  }

  // Test 5: Authentication
  console.log('\n5️⃣ Testing Authentication:');
  try {
    const authResponse = await makeRequest('/auth/login', 'POST', {
      userId: '22-4957-735',
      password: 'KYLO.omni0'
    });
    console.log('   ✅ Authentication successful');
  } catch (e) {
    console.log('   ❌ Authentication failed:', e.message);
  }

  console.log('\n🎉 API testing completed!');
}

// Helper function to make HTTP requests
function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 42952,
      path: `/api${path}`,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        try {
          const response = JSON.parse(body);
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve(response);
          } else {
            reject(new Error(`HTTP ${res.statusCode}: ${response.error || body}`));
          }
        } catch (e) {
          reject(new Error(`Invalid JSON response: ${body}`));
        }
      });
    });

    req.on('error', (e) => {
      reject(new Error(`Request failed: ${e.message}`));
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// Run the test
testAPI().catch(console.error); 