import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  print('🔗 Testing MongoDB Atlas Connection...');
  
  // Test connection strings
  final connectionStrings = [
    'mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority',
    'mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority',
    'mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&authSource=admin&retryWrites=true&w=majority',
  ];
  
  for (int i = 0; i < connectionStrings.length; i++) {
    final url = connectionStrings[i];
    print('\n🔗 Testing connection string ${i + 1}:');
    print('URL: ${url.contains('@') ? '${url.substring(0, url.indexOf('@') + 1)}***' : url}');
    
    try {
      final db = Db(url);
      await db.open();
      
      print('✅ Connection successful!');
      
      // Test a simple operation
      final collection = db.collection('users');
      final count = await collection.count();
      print('📊 Users collection count: $count');
      
      await db.close();
      print('🔒 Connection closed successfully');
      
      // If we get here, the connection worked
      print('🎉 MongoDB Atlas connection is working!');
      return;
      
    } catch (e) {
      print('❌ Connection failed: $e');
    }
  }
  
  print('\n❌ All connection attempts failed. Please check:');
  print('1. Internet connection');
  print('2. MongoDB Atlas cluster status');
  print('3. Network access settings in MongoDB Atlas');
  print('4. Username and password');
  print('5. Database name');
} 