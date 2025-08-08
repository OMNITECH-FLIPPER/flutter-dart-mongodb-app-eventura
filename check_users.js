const http = require('http');

function makeRequest(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 42952,
      path: `/api${path}`,
      method: 'GET',
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
          resolve(response);
        } catch (e) {
          reject(new Error(`Invalid JSON response: ${body}`));
        }
      });
    });

    req.on('error', (e) => {
      reject(new Error(`Request failed: ${e.message}`));
    });

    req.end();
  });
}

async function checkUsers() {
  try {
    console.log('🔍 Checking users in MongoDB Atlas...\n');
    
    const users = await makeRequest('/users');
    
    console.log(`📋 Found ${users.length} users in database:\n`);
    
    users.forEach((user, index) => {
      console.log(`${index + 1}. ${user.name} (${user.user_id})`);
      console.log(`   Role: ${user.role}`);
      console.log(`   Email: ${user.email}`);
      console.log(`   Status: ${user.status}`);
      console.log(`   Password: ${user.password}`);
      console.log('');
    });
    
    console.log('🎯 Use these credentials to test the Flutter app!');
    
  } catch (error) {
    console.error('❌ Error checking users:', error.message);
  }
}

checkUsers(); 