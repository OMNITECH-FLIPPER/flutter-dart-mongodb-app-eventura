const mongoose = require('mongoose');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

async function testMongoConnection() {
  console.log('🔍 MongoDB Connection Test Started...');
  
  if (!process.env.MONGODB_URI) {
    console.error('❌ MONGODB_URI environment variable is not set');
    process.exit(1);
  }

  const uri = process.env.MONGODB_URI;
  console.log(`🔗 Attempting to connect to: ${uri.replace(/\/\/.*@/, '//***:***@')}`);
  
  try {
    // Connect to MongoDB
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 5000, // 5 second timeout
      socketTimeoutMS: 45000,
      maxPoolSize: 10,
      minPoolSize: 1,
      maxIdleTimeMS: 30000,
    });

    console.log('✅ Successfully connected to MongoDB');
    
    // Test database ping
    const result = await mongoose.connection.db.admin().ping();
    console.log('✅ Ping test successful:', result);
    
    // Get database info
    const admin = mongoose.connection.db.admin();
    const serverStatus = await admin.serverStatus();
    
    console.log('📊 Database Info:');
    console.log(`   - MongoDB Version: ${serverStatus.version}`);
    console.log(`   - Database: ${mongoose.connection.name}`);
    console.log(`   - Host: ${serverStatus.host}`);
    
    // List collections
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log(`   - Collections: ${collections.length}`);
    collections.forEach(col => {
      console.log(`     * ${col.name}`);
    });
    
    console.log('✅ MongoDB connection test completed successfully!');
    
  } catch (error) {
    console.error('❌ MongoDB connection test failed:', error.message);
    
    // Provide helpful error messages
    if (error.message.includes('authentication failed')) {
      console.error('💡 Check your username and password in the connection string');
    } else if (error.message.includes('ENOTFOUND') || error.message.includes('ECONNREFUSED')) {
      console.error('💡 Check your network connection and Atlas cluster configuration');
    } else if (error.message.includes('bad auth')) {
      console.error('💡 Verify your MongoDB Atlas credentials');
    }
    
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
  }
}

// Handle process termination
process.on('SIGINT', async () => {
  console.log('\n🛑 Test interrupted, cleaning up...');
  await mongoose.disconnect();
  process.exit(0);
});

// Run the test
testMongoConnection();
