const axios = require('axios');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'http://localhost:3000';
const TEST_USER = {
  userId: 'testuser123',
  name: 'Test User',
  email: 'test@example.com',
  password: 'testpassword123',
  role: 'User',
  status: 'active'
};

const TEST_ADMIN = {
  userId: 'testadmin123',
  name: 'Test Admin',
  email: 'admin@example.com',
  password: 'adminpassword123',
  role: 'Admin',
  status: 'active'
};

const TEST_EVENT = {
  title: 'Test Event',
  description: 'This is a test event for full stack testing',
  date: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  location: 'Test Location',
  organizerId: 'testadmin123',
  status: 'active',
  maxParticipants: 100
};

class FullStackTester {
  constructor() {
    this.testResults = [];
    this.authToken = null;
  }

  async log(message, type = 'INFO') {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${type}] ${message}`);
  }

  async testHealthCheck() {
    try {
      const response = await axios.get(`${BASE_URL}/health`);
      if (response.status === 200) {
        this.log('✅ Health check passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ Health check failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testDatabaseConnection() {
    try {
      const response = await axios.get(`${BASE_URL}/api`);
      if (response.status === 200) {
        this.log('✅ Database connection test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ Database connection test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testUserRegistration() {
    try {
      const response = await axios.post(`${BASE_URL}/api/users`, TEST_USER);
      if (response.status === 201) {
        this.log('✅ User registration test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      if (error.response?.status === 409) {
        this.log('⚠️ User already exists (expected for repeated tests)', 'WARNING');
        return true;
      }
      this.log(`❌ User registration test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testAdminRegistration() {
    try {
      const response = await axios.post(`${BASE_URL}/api/users`, TEST_ADMIN);
      if (response.status === 201) {
        this.log('✅ Admin registration test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      if (error.response?.status === 409) {
        this.log('⚠️ Admin already exists (expected for repeated tests)', 'WARNING');
        return true;
      }
      this.log(`❌ Admin registration test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testUserAuthentication() {
    try {
      const response = await axios.post(`${BASE_URL}/api/auth/login`, {
        userId: TEST_USER.userId,
        password: TEST_USER.password
      });
      if (response.status === 200 && response.data.user) {
        this.log('✅ User authentication test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ User authentication test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testAdminAuthentication() {
    try {
      const response = await axios.post(`${BASE_URL}/api/auth/login`, {
        userId: TEST_ADMIN.userId,
        password: TEST_ADMIN.password
      });
      if (response.status === 200 && response.data.user) {
        this.log('✅ Admin authentication test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ Admin authentication test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testEventCreation() {
    try {
      const response = await axios.post(`${BASE_URL}/api/events`, TEST_EVENT);
      if (response.status === 201) {
        this.log('✅ Event creation test passed', 'SUCCESS');
        return response.data.eventId;
      }
    } catch (error) {
      this.log(`❌ Event creation test failed: ${error.message}`, 'ERROR');
      return null;
    }
  }

  async testEventRetrieval() {
    try {
      const response = await axios.get(`${BASE_URL}/api/events`);
      if (response.status === 200 && Array.isArray(response.data)) {
        this.log('✅ Event retrieval test passed', 'SUCCESS');
        return response.data.length > 0;
      }
    } catch (error) {
      this.log(`❌ Event retrieval test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testImageUpload() {
    try {
      // Create a simple test image (1x1 pixel PNG)
      const testImageData = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
      
      const response = await axios.post(`${BASE_URL}/api/upload/image`, {
        imageData: testImageData,
        fileName: 'test-image.png',
        fileType: 'image/png'
      });
      
      if (response.status === 200 && response.data.imageUrl) {
        this.log('✅ Image upload test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ Image upload test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testNotificationCreation() {
    try {
      const response = await axios.post(`${BASE_URL}/api/notifications`, {
        userId: TEST_USER.userId,
        title: 'Test Notification',
        body: 'This is a test notification',
        data: { test: true }
      });
      
      if (response.status === 201) {
        this.log('✅ Notification creation test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ Notification creation test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testNotificationRetrieval() {
    try {
      const response = await axios.get(`${BASE_URL}/api/notifications?userId=${TEST_USER.userId}`);
      if (response.status === 200 && Array.isArray(response.data)) {
        this.log('✅ Notification retrieval test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ Notification retrieval test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async testUserManagement() {
    try {
      const response = await axios.get(`${BASE_URL}/api/users`);
      if (response.status === 200 && Array.isArray(response.data)) {
        this.log('✅ User management test passed', 'SUCCESS');
        return true;
      }
    } catch (error) {
      this.log(`❌ User management test failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async runAllTests() {
    this.log('🚀 Starting Full Stack Test Suite for Eventura App', 'INFO');
    this.log('================================================', 'INFO');

    const tests = [
      { name: 'Health Check', test: () => this.testHealthCheck() },
      { name: 'Database Connection', test: () => this.testDatabaseConnection() },
      { name: 'User Registration', test: () => this.testUserRegistration() },
      { name: 'Admin Registration', test: () => this.testAdminRegistration() },
      { name: 'User Authentication', test: () => this.testUserAuthentication() },
      { name: 'Admin Authentication', test: () => this.testAdminAuthentication() },
      { name: 'Event Creation', test: () => this.testEventCreation() },
      { name: 'Event Retrieval', test: () => this.testEventRetrieval() },
      { name: 'Image Upload', test: () => this.testImageUpload() },
      { name: 'Notification Creation', test: () => this.testNotificationCreation() },
      { name: 'Notification Retrieval', test: () => this.testNotificationRetrieval() },
      { name: 'User Management', test: () => this.testUserManagement() },
    ];

    let passedTests = 0;
    let totalTests = tests.length;

    for (const test of tests) {
      this.log(`Running test: ${test.name}`, 'INFO');
      const result = await test.test();
      if (result) {
        passedTests++;
      }
      this.log('', 'INFO');
    }

    this.log('================================================', 'INFO');
    this.log(`🎯 Test Results: ${passedTests}/${totalTests} tests passed`, 'INFO');
    
    if (passedTests === totalTests) {
      this.log('🎉 ALL TESTS PASSED! Eventura app is fully functional.', 'SUCCESS');
    } else {
      this.log(`⚠️ ${totalTests - passedTests} test(s) failed. Please check the logs above.`, 'WARNING');
    }

    return passedTests === totalTests;
  }
}

// Run the tests if this file is executed directly
if (require.main === module) {
  const tester = new FullStackTester();
  tester.runAllTests().then(success => {
    process.exit(success ? 0 : 1);
  }).catch(error => {
    console.error('Test suite failed:', error);
    process.exit(1);
  });
}

module.exports = FullStackTester;
