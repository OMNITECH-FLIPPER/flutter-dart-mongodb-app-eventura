import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  print('🚀 Testing MongoDB Atlas Cluster0 Connection...\n');
  
  // Connection string for your Atlas Cluster0 (standard format for mongo_dart)
  const mongoUrl = 'mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority';
  
  try {
    print('📡 Connecting to MongoDB Atlas Cluster0...');
    
    // Create database connection
    final db = Db(mongoUrl);
    
    // Open connection
    await db.open();
    print('✅ Successfully connected to MongoDB Atlas!');
    
    // Test server status
    print('🧪 Testing server status...');
    final serverStatus = await db.serverStatus();
    print('✅ Server status: ${serverStatus['ok']}');
    
    // Test database operations
    print('🧪 Testing database operations...');
    final usersCollection = db.collection('users');
    
    // Try to count documents (this will work even if collection is empty)
    final userCount = await usersCollection.count();
    print('👥 Current users in database: $userCount');
    
    // Test events collection
    final eventsCollection = db.collection('events');
    final eventCount = await eventsCollection.count();
    print('📅 Current events in database: $eventCount');
    
    // Test registrations collection
    final registrationsCollection = db.collection('event_registrations');
    final registrationCount = await registrationsCollection.count();
    print('📝 Current registrations in database: $registrationCount');
    
    print('\n🎉 All tests passed! Your MongoDB Atlas Cluster0 is properly connected.');
    print('📊 Database Statistics:');
    print('   - Database Name: MongoDataBase');
    print('   - Cluster: cluster0');
    print('   - Users: $userCount');
    print('   - Events: $eventCount');
    print('   - Registrations: $registrationCount');
    
    // Close connection
    await db.close();
    print('\n✅ Connection closed successfully');
    
  } catch (e) {
    print('❌ Connection failed: $e');
    print('\n🔧 Troubleshooting tips:');
    print('1. Check your internet connection');
    print('2. Verify MongoDB Atlas cluster is running');
    print('3. Ensure your IP is whitelisted in Atlas');
    print('4. Confirm credentials are correct');
  }
}
