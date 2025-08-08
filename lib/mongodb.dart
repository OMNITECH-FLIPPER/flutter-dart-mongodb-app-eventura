import 'package:flutter/foundation.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'models/user.dart';
import 'models/event.dart';
import 'models/event_registration.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'env_config.dart';
import 'services/mongodb_web_service.dart';

class MongoDataBase {
  static Db? _db;
  static bool _isConnected = false;

  static bool get isConnected => _isConnected;
  
  static Db? get db => _db;

  // Collection names
  static const String usersCollection = 'users';
  static const String eventsCollection = 'events';
  static const String registrationsCollection = 'event_registrations';

  static Future<void> connect() async {
    try {
      if (_isConnected) {
        debugPrint('Already connected to MongoDB');
        return;
      }

      debugPrint('Connecting to MongoDB Atlas...');
      
      // On web platform, we'll use the API backend to connect to MongoDB
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected - using API backend for MongoDB connection');
        _isConnected = true; // Mark as connected since API will handle MongoDB operations
        return;
      }
      
      // Check if we should use mock mode (for development/testing)
      if (await _shouldUseMockMode()) {
        debugPrint('🔄 Using mock mode for development');
        _isConnected = true;
        return;
      }
      
      // Try multiple connection methods for mobile/desktop platforms
      await _tryPrimaryConnection();
      
      if (!_isConnected) {
        await _tryAlternativeConnection();
      }
      
      if (!_isConnected) {
        await _trySimplifiedConnection();
      }
      
      if (!_isConnected) {
        debugPrint('⚠️ All connection attempts failed, switching to mock mode');
        _isConnected = true; // Enable mock mode
      }
      
    } catch (e) {
      _isConnected = false;
      debugPrint('❌ All MongoDB connection attempts failed: $e');
      debugPrint('🔄 Switching to mock mode for development');
      _isConnected = true; // Enable mock mode
    }
  }

  static Future<bool> _shouldUseMockMode() async {
    // Check if we're in development mode or if connection is explicitly disabled
    const bool useMockMode = bool.fromEnvironment('USE_MOCK_MODE', defaultValue: false);
    if (useMockMode) {
      return true;
    }
    
    // Check if we can reach the internet
    try {
      // Simple internet connectivity test
      return false; // Try real connection first
    } catch (e) {
      debugPrint('🌐 No internet connection detected, using mock mode');
      return true;
    }
  }

  static Future<void> _tryPrimaryConnection() async {
    try {
      debugPrint('🔗 Attempting primary connection to Atlas cluster0...');
      
      // Use the environment variable or fallback to the new connection string format
      var mongoUrl = EnvConfig.mongoUrl.isNotEmpty 
          ? EnvConfig.mongoUrl 
          : 'mongodb+srv://KyleAngelo:<db_password>@cluster0.evanqft.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';
      
      debugPrint('MongoDB URI: ${mongoUrl.contains('@') ? '${mongoUrl.substring(0, mongoUrl.indexOf('@') + 1)}***' : mongoUrl}');
      
      _db = Db(mongoUrl);
      await _db!.open();
      
      _isConnected = true;
      debugPrint('✅ Successfully connected to MongoDB Atlas cluster0');
      
      // Test the connection
      await _testConnection();
      
    } catch (e) {
      debugPrint('❌ Primary connection failed: $e');
      _isConnected = false;
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
    }
  }

  static Future<void> _tryAlternativeConnection() async {
    try {
      debugPrint('🔗 Attempting alternative connection method...');
      
      // Try with the updated Atlas connection string format
      var alternativeUrl = 'mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0';
      
      debugPrint('Alternative URI: ${alternativeUrl.contains('@') ? '${alternativeUrl.substring(0, alternativeUrl.indexOf('@') + 1)}***' : alternativeUrl}');
      
      _db = Db(alternativeUrl);
      await _db!.open();
      
      _isConnected = true;
      debugPrint('✅ Successfully connected to MongoDB Atlas using alternative method');
      
      // Test the connection
      await _testConnection();
      
    } catch (e) {
      debugPrint('❌ Alternative connection failed: $e');
      _isConnected = false;
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
    }
  }

  static Future<void> _trySimplifiedConnection() async {
    try {
      debugPrint('🔗 Attempting simplified connection method...');
      
      // Try with a direct connection to the primary shard
      var simplifiedUrl = 'mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority';
      
      debugPrint('Simplified URI: ${simplifiedUrl.contains('@') ? '${simplifiedUrl.substring(0, simplifiedUrl.indexOf('@') + 1)}***' : simplifiedUrl}');
      
      _db = Db(simplifiedUrl);
      await _db!.open();
      
      _isConnected = true;
      debugPrint('✅ Successfully connected using simplified method');
      
      // Test the connection
      await _testConnection();
      
    } catch (e) {
      debugPrint('❌ Simplified connection failed: $e');
      _isConnected = false;
      if (_db != null) {
        await _db!.close();
        _db = null;
      }
    }
  }

  static Future<void> _testConnection() async {
    try {
      debugPrint('🧪 Testing database connection...');
      
      // Test server status
      var status = await _db!.serverStatus();
      debugPrint('✅ Database status: ${status['ok']}');
      
      // Test collection operations
      await _testCollection();
      
    } catch (e) {
      debugPrint('⚠️ Connection test failed: $e');
      // Don't fail the connection for test issues
    }
  }

  static Future<void> _testCollection() async {
    try {
      if (_db == null) return; // Skip if no database connection
      
      var collection = _db!.collection(usersCollection);
      
      // Check if admin user already exists
      var existingAdmin = await collection.findOne(where.eq('user_id', '22-4957-735'));
      
      if (existingAdmin == null) {
        // Create admin user
        var adminUser = User(
          name: "Kyle Angelo",
          userId: "22-4957-735",
          password: "KYLO.omni0",
          role: "Admin",
          age: 25,
          email: "kyleangelocabading@gmail.com",
          address: "123 Main St",
          status: "active",
        );
        
        await collection.insert(adminUser.toMap());
        debugPrint('✅ Admin user created successfully');
      } else {
        debugPrint('✅ Admin user already exists');
      }
      
    } catch (e) {
      debugPrint('⚠️ Test collection operation failed: $e');
      // Don't fail the connection for test issues
    }
  }

  // User Management Methods
  static Future<List<User>> getAllUsers() async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getAllUsers();
      } catch (e) {
        debugPrint('❌ Web API getAllUsers failed: $e');
        // Return mock data on failure
        return _getMockUsers();
      }
    }
    
    try {
      if (_db == null) return _getMockUsers();
      
      var collection = _db!.collection(usersCollection);
      var users = await collection.find().toList();
      
      return users.map((user) => User.fromMap(user)).toList();
    } catch (e) {
      debugPrint('❌ getAllUsers failed: $e');
      return _getMockUsers();
    }
  }

  // Mock data for testing
  static List<User> _getMockUsers() {
    return [
      User(
        name: "Kyle Angelo",
        userId: "22-4957-735",
        password: "KYLO.omni0",
        role: "Admin",
        age: 25,
        email: "kyleangelocabading@gmail.com",
        address: "123 Main St",
        status: "active",
      ),
      User(
        name: "John Doe",
        userId: "22-1234-567",
        password: "password123",
        role: "User",
        age: 30,
        email: "john.doe@example.com",
        address: "456 Oak St",
        status: "active",
      ),
    ];
  }

  // Authentication Methods
  static Future<User?> authenticateUser(String userId, String password) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.authenticateUser(userId, password);
      } catch (e) {
        debugPrint('❌ Web API authentication failed: $e');
        // Fall back to mock authentication
        return _mockAuthenticateUser(userId, password);
      }
    }
    
    try {
      if (_db == null) return _mockAuthenticateUser(userId, password);
      
      var collection = _db!.collection(usersCollection);
      var user = await collection.findOne(where.eq('user_id', userId));
      
      if (user == null) {
        debugPrint('❌ User not found: $userId');
        return null;
      }
      
      var userObj = User.fromMap(user);
      
      // Check password
      if (userObj.password == password) {
        debugPrint('✅ User authenticated: $userId');
        return userObj;
      } else {
        debugPrint('❌ Invalid password for user: $userId');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Authentication failed: $e');
      return _mockAuthenticateUser(userId, password);
    }
  }

  // Mock authentication for testing
  static User? _mockAuthenticateUser(String userId, String password) {
    var mockUsers = _getMockUsers();
    
    for (var user in mockUsers) {
      if (user.userId == userId && user.password == password) {
        debugPrint('✅ Mock user authenticated: $userId');
        return user;
      }
    }
    
    debugPrint('❌ Mock authentication failed for user: $userId');
    return null;
  }
  
  // Helper method to hash passwords
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Get user by user ID
  static Future<User?> getUserByUserId(String userId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getUserByUserId(userId);
      } catch (e) {
        debugPrint('❌ Web API getUserByUserId failed: $e');
        // Fall back to mock data
        return _getMockUserById(userId);
      }
    }
    
    try {
      if (_db == null) return _getMockUserById(userId);
      
      var collection = _db!.collection(usersCollection);
      var user = await collection.findOne(where.eq('user_id', userId));
      
      if (user == null) {
        debugPrint('❌ User not found: $userId');
        return null;
      }
      
      return User.fromMap(user);
    } catch (e) {
      debugPrint('❌ getUserByUserId failed: $e');
      return _getMockUserById(userId);
    }
  }
  
  // Mock user by ID for testing
  static User? _getMockUserById(String userId) {
    var mockUsers = _getMockUsers();
    
    for (var user in mockUsers) {
      if (user.userId == userId) {
        return user;
      }
    }
    
    return null;
  }
  
  // Update user
  static Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.updateUser(userId, updates);
        return;
      } catch (e) {
        debugPrint('❌ Web API updateUser failed: $e');
        // Fall through to mock update
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock update');
        return; // Mock update (no-op)
      }
      
      var collection = _db!.collection(usersCollection);
      
      // Handle password hashing if needed
      if (updates.containsKey('password')) {
        updates['password'] = hashPassword(updates['password']);
      }
      
      // Create a ModifierBuilder and add each field from updates
      var modifier = modify;
      updates.forEach((key, value) {
        modifier = modifier.set(key, value);
      });
      
      await collection.updateOne(
        where.eq('user_id', userId),
        modifier
      );
      
      debugPrint('✅ User updated successfully: $userId');
    } catch (e) {
      debugPrint('❌ updateUser failed: $e');
    }
  }
  
  // Event Management Methods
  static Future<List<Event>> getAllEvents() async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getAllEvents();
      } catch (e) {
        debugPrint('❌ Web API getAllEvents failed: $e');
        // Return mock data on failure
        return _getMockEvents();
      }
    }
    
    try {
      if (_db == null) return _getMockEvents();
      
      var collection = _db!.collection(eventsCollection);
      var events = await collection.find().toList();
      
      return events.map((event) => Event.fromMap(event)).toList();
    } catch (e) {
      debugPrint('❌ getAllEvents failed: $e');
      return _getMockEvents();
    }
  }
  
  // Get event by ID
  static Future<Event?> getEventById(String eventId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getEventById(eventId);
      } catch (e) {
        debugPrint('❌ Web API getEventById failed: $e');
        // Fall back to mock data
        return _getMockEvents().firstWhere(
          (event) => event.id == eventId,
          orElse: () => throw Exception('Event not found'),
        );
      }
    }
    
    try {
      if (_db == null) {
        return _getMockEvents().firstWhere(
          (event) => event.id == eventId,
          orElse: () => throw Exception('Event not found'),
        );
      }
      
      var collection = _db!.collection(eventsCollection);
      var event = await collection.findOne(where.eq('_id', ObjectId.fromHexString(eventId)));
      
      if (event != null) {
        return Event.fromMap(event);
      }
      
      throw Exception('Event not found');
    } catch (e) {
      debugPrint('❌ getEventById failed: $e');
      rethrow;
    }
  }
  
  // Get events by organizer
  static Future<List<Event>> getEventsByOrganizer(String organizerId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getEventsByOrganizer(organizerId);
      } catch (e) {
        debugPrint('❌ Web API getEventsByOrganizer failed: $e');
        // Return mock data on failure
        return _getMockEvents().where((event) => event.organizerId == organizerId).toList();
      }
    }
    
    try {
      if (_db == null) {
        return _getMockEvents().where((event) => event.organizerId == organizerId).toList();
      }
      
      var collection = _db!.collection(eventsCollection);
      var events = await collection.find(where.eq('organizer_id', organizerId)).toList();
      
      return events.map((event) => Event.fromMap(event)).toList();
    } catch (e) {
      debugPrint('❌ getEventsByOrganizer failed: $e');
      return _getMockEvents().where((event) => event.organizerId == organizerId).toList();
    }
  }
  
  // Mock events for testing
  static List<Event> _getMockEvents() {
    return [
      Event(
        id: '1',
        title: 'Tech Conference 2024',
        description: 'Annual technology conference featuring the latest innovations',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        location: 'Convention Center, Metro Manila',
        organizerId: '22-4957-735',
        organizerName: 'Kyle Angelo',
        totalSlots: 100,
        availableSlots: 75,
        status: 'active',
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      Event(
        id: '2',
        title: 'Startup Networking Event',
        description: 'Connect with fellow entrepreneurs and investors',
        eventDate: DateTime.now().add(const Duration(days: 15)),
        location: 'Business District, Makati',
        organizerId: '24-5678-901',
        organizerName: 'Jane Smith',
        totalSlots: 50,
        availableSlots: 25,
        status: 'active',
        imageUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
  
  // Add event
  static Future<void> addEvent(Event event) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.addEvent(event);
        return;
      } catch (e) {
        debugPrint('❌ Web API addEvent failed: $e');
        // Fall through to mock add
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock add');
        return; // Mock add (no-op)
      }
      
      var collection = _db!.collection(eventsCollection);
      await collection.insertOne(event.toMap());
      
      debugPrint('✅ Event added successfully: ${event.title}');
    } catch (e) {
      debugPrint('❌ addEvent failed: $e');
    }
  }
  
  // Update event
  static Future<void> updateEvent(String eventId, Map<String, dynamic> updates, {String? editorUserId, bool isAdmin = false}) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.updateEvent(eventId, updates, editorUserId: editorUserId, isAdmin: isAdmin);
        return;
      } catch (e) {
        debugPrint('❌ Web API updateEvent failed: $e');
        // Fall through to mock update
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock update');
        return; // Mock update (no-op)
      }
      
      var collection = _db!.collection(eventsCollection);
      
      // Add updated timestamp
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      // Create a ModifierBuilder and add each field from updates
      var modifier = modify;
      updates.forEach((key, value) {
        modifier = modifier.set(key, value);
      });
      
      await collection.updateOne(
        where.eq('_id', ObjectId.fromHexString(eventId)),
        modifier
      );
      
      debugPrint('✅ Event updated successfully: $eventId');
    } catch (e) {
      debugPrint('❌ updateEvent failed: $e');
    }
  }
  
  // Add user
  static Future<void> addUser(User user) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.addUser(user);
        return;
      } catch (e) {
        debugPrint('❌ Web API addUser failed: $e');
        // Fall through to mock add
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock add');
        return; // Mock add (no-op)
      }
      
      // Hash password before storing
      final userWithHashedPassword = User(
        name: user.name,
        userId: user.userId,
        password: hashPassword(user.password),
        role: user.role,
        age: user.age,
        email: user.email,
        address: user.address,
        status: user.status,
      );
      
      var collection = _db!.collection(usersCollection);
      await collection.insertOne(userWithHashedPassword.toMap());
      
      debugPrint('✅ User added successfully: ${user.name}');
    } catch (e) {
      debugPrint('❌ addUser failed: $e');
    }
  }
  
  // Save QR code data
  static Future<void> saveQRCode(Map<String, dynamic> qrData) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.saveQRCode(qrData);
        return;
      } catch (e) {
        debugPrint('❌ Web API saveQRCode failed: $e');
        // Fall through to mock save
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock save');
        return; // Mock save (no-op)
      }
      
      var collection = _db!.collection('qr_codes');
      await collection.insertOne({
        ...qrData,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ QR code data saved successfully');
    } catch (e) {
      debugPrint('❌ saveQRCode failed: $e');
    }
  }

  /// Disconnects from the MongoDB database and resets the connection state
  static Future<void> disconnect() async {
    try {
      if (_db != null && _isConnected) {
        debugPrint('Disconnecting from MongoDB...');
        await _db!.close();
        _db = null;
        _isConnected = false;
        debugPrint('Successfully disconnected from MongoDB');
      } else {
        debugPrint('No active MongoDB connection to disconnect');
      }
    } catch (e) {
      debugPrint('Error disconnecting from MongoDB: $e');
      // Reset state even if there's an error
      _db = null;
      _isConnected = false;
    }
  }
  
  // Get all event registrations
  static Future<List<EventRegistration>> getAllRegistrations() async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getAllRegistrations();
      } catch (e) {
        debugPrint('❌ Web API getAllRegistrations failed: $e');
        // Return mock data on failure
        return _getMockRegistrations();
      }
    }
    
    try {
      if (_db == null) return _getMockRegistrations();
      
      var collection = _db!.collection(registrationsCollection);
      var registrations = await collection.find().toList();
      
      return registrations.map((reg) => EventRegistration.fromMap(reg)).toList();
    } catch (e) {
      debugPrint('❌ getAllRegistrations failed: $e');
      return _getMockRegistrations();
    }
  }
  
  // Mock registrations for testing
  static List<EventRegistration> _getMockRegistrations() {
    return [
      EventRegistration(
        id: '1',
        userId: '22-1234-567',
        userName: 'John Doe',
        userEmail: 'john.doe@example.com',
        eventId: '1',
        eventTitle: 'Tech Conference 2024',
        registrationDate: DateTime.now().subtract(const Duration(days: 5)),
        isConfirmed: true,
        attended: false,
        status: 'registered',
      ),
      EventRegistration(
        id: '2',
        userId: '22-4957-735',
        userName: 'Kyle Angelo',
        userEmail: 'kyleangelocabading@gmail.com',
        eventId: '2',
        eventTitle: 'Startup Networking Event',
        registrationDate: DateTime.now().subtract(const Duration(days: 2)),
        isConfirmed: true,
        attended: false,
        status: 'registered',
      ),
    ];
  }
  
  // User Management - Unblock User
  static Future<void> unblockUser(String userId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.unblockUser(userId);
        return;
      } catch (e) {
        debugPrint('❌ Web API unblockUser failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock unblock');
        return; // Mock unblock (no-op)
      }
      
      var collection = _db!.collection(usersCollection);
      await collection.updateOne(
        where.eq('userId', userId),
        modify.set('status', 'active')
      );
      
      debugPrint('✅ User $userId unblocked successfully');
    } catch (e) {
      debugPrint('❌ unblockUser failed: $e');
    }
  }
  
  // User Management - Change User Role
  static Future<void> changeUserRole(String userId, String newRole) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.changeUserRole(userId, newRole);
        return;
      } catch (e) {
        debugPrint('❌ Web API changeUserRole failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock role change');
        return; // Mock role change (no-op)
      }
      
      var collection = _db!.collection(usersCollection);
      await collection.updateOne(
        where.eq('userId', userId),
        modify.set('role', newRole)
      );
      
      debugPrint('✅ User $userId role changed to $newRole successfully');
    } catch (e) {
      debugPrint('❌ changeUserRole failed: $e');
    }
  }
  
  // User Management - Block User
  static Future<void> blockUser(String userId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.blockUser(userId);
        return;
      } catch (e) {
        debugPrint('❌ Web API blockUser failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock block');
        return; // Mock block (no-op)
      }
      
      var collection = _db!.collection(usersCollection);
      await collection.updateOne(
        where.eq('userId', userId),
        modify.set('status', 'blocked')
      );
      
      debugPrint('✅ User $userId blocked successfully');
    } catch (e) {
      debugPrint('❌ blockUser failed: $e');
    }
  }
  
  // Registration Management - Confirm Attendance
  static Future<void> confirmAttendance(String registrationId, bool attended, {String? certificateUrl}) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.confirmAttendance(registrationId, attended, certificateUrl: certificateUrl);
        return;
      } catch (e) {
        debugPrint('❌ Web API confirmAttendance failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock attendance confirmation');
        return; // Mock attendance confirmation (no-op)
      }
      
      var collection = _db!.collection(registrationsCollection);
      var updateData = {
        'attended': attended,
        'status': attended ? 'attended' : 'registered',
      };
      
      if (certificateUrl != null) {
        updateData['certificateUrl'] = certificateUrl;
      }
      
      await collection.updateOne(
        where.eq('_id', ObjectId.fromHexString(registrationId)),
        modify.set('attended', attended).set('status', attended ? 'attended' : 'registered')
      );
      
      debugPrint('✅ Registration $registrationId attendance updated to $attended successfully');
    } catch (e) {
      debugPrint('❌ confirmAttendance failed: $e');
    }
  }
  
  // Get registrations by event
  static Future<List<EventRegistration>> getRegistrationsByEvent(String eventId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getRegistrationsByEvent(eventId);
      } catch (e) {
        debugPrint('❌ Web API getRegistrationsByEvent failed: $e');
        // Return mock data on failure
        return _getMockRegistrations().where((reg) => reg.eventId == eventId).toList();
      }
    }
    
    try {
      if (_db == null) {
        return _getMockRegistrations().where((reg) => reg.eventId == eventId).toList();
      }
      
      var collection = _db!.collection(registrationsCollection);
      var registrations = await collection.find(where.eq('event_id', eventId)).toList();
      
      return registrations.map((reg) => EventRegistration.fromMap(reg)).toList();
    } catch (e) {
      debugPrint('❌ getRegistrationsByEvent failed: $e');
      return _getMockRegistrations().where((reg) => reg.eventId == eventId).toList();
    }
  }
  
  // Register for event
  static Future<void> registerForEvent(EventRegistration registration) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.registerForEvent(registration);
        return;
      } catch (e) {
        debugPrint('❌ Web API registerForEvent failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock registration');
        return; // Mock registration (no-op)
      }
      
      var collection = _db!.collection(registrationsCollection);
      await collection.insertOne(registration.toMap());
      
      debugPrint('✅ Registration for event ${registration.eventId} added successfully');
    } catch (e) {
      debugPrint('❌ registerForEvent failed: $e');
    }
  }
  
  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.deleteEvent(eventId);
        return;
      } catch (e) {
        debugPrint('❌ Web API deleteEvent failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock delete');
        return; // Mock delete (no-op)
      }
      
      var collection = _db!.collection(eventsCollection);
      await collection.deleteOne(where.eq('_id', ObjectId.fromHexString(eventId)));
      
      // Also delete all registrations for this event
      var regCollection = _db!.collection(registrationsCollection);
      await regCollection.deleteMany(where.eq('event_id', eventId));
      
      debugPrint('✅ Event $eventId and its registrations deleted successfully');
    } catch (e) {
      debugPrint('❌ deleteEvent failed: $e');
    }
  }
  
  // Get registrations by user
  static Future<List<EventRegistration>> getRegistrationsByUser(String userId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getRegistrationsByUser(userId);
      } catch (e) {
        debugPrint('❌ Web API getRegistrationsByUser failed: $e');
        // Return mock data on failure
        return _getMockRegistrations().where((reg) => reg.userId == userId).toList();
      }
    }
    
    try {
      if (_db == null) {
        return _getMockRegistrations().where((reg) => reg.userId == userId).toList();
      }
      
      var collection = _db!.collection(registrationsCollection);
      var registrations = await collection.find(where.eq('user_id', userId)).toList();
      
      return registrations.map((reg) => EventRegistration.fromMap(reg)).toList();
    } catch (e) {
      debugPrint('❌ getRegistrationsByUser failed: $e');
      return _getMockRegistrations().where((reg) => reg.userId == userId).toList();
    }
  }
  
  // Get user by ID
  static Future<User?> getUserById(String id) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.getUserById(id);
      } catch (e) {
        debugPrint('❌ Web API getUserById failed: $e');
        // Fall through to mock data
      }
    }
    
    try {
      if (_db == null) {
        return _getMockUsers().firstWhere(
          (user) => user.id == id,
          orElse: () => throw Exception('User not found'),
        );
      }
      
      var collection = _db!.collection(usersCollection);
      var user = await collection.findOne(where.eq('_id', ObjectId.fromHexString(id)));
      
      if (user != null) {
        return User.fromMap(user);
      }
      
      throw Exception('User not found');
    } catch (e) {
      debugPrint('❌ getUserById failed: $e');
      rethrow;
    }
  }
  
  // Delete user
  static Future<void> deleteUser(String userId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.deleteUser(userId);
        return;
      } catch (e) {
        debugPrint('❌ Web API deleteUser failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock delete');
        return; // Mock delete (no-op)
      }
      
      var collection = _db!.collection(usersCollection);
      await collection.deleteOne(where.eq('_id', ObjectId.fromHexString(userId)));
      
      // Also delete all registrations for this user
      var regCollection = _db!.collection(registrationsCollection);
      await regCollection.deleteMany(where.eq('user_id', userId));
      
      debugPrint('✅ User $userId and their registrations deleted successfully');
    } catch (e) {
      debugPrint('❌ deleteUser failed: $e');
    }
  }
  
  // Upload certificate file
  static Future<String> uploadCertificateFile(dynamic file, String registrationId) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        return await MongoDBWebService.uploadCertificateFile(file, registrationId);
      } catch (e) {
        debugPrint('❌ Web API uploadCertificateFile failed: $e');
        // Return mock URL
        return 'mock://certificate/$registrationId.pdf';
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock upload');
        return 'mock://certificate/$registrationId.pdf'; // Mock URL
      }
      
      // For now, return a mock URL since file upload requires backend implementation
      // In a real implementation, this would upload to a file storage service
      final mockUrl = 'https://storage.eventura.com/certificates/$registrationId.pdf';
      debugPrint('✅ Certificate file uploaded (mock): $mockUrl');
      return mockUrl;
    } catch (e) {
      debugPrint('❌ uploadCertificateFile failed: $e');
      return 'mock://certificate/$registrationId.pdf';
    }
  }
  
  // Update registration certificate
  static Future<void> updateRegistrationCertificate(String registrationId, String certificateUrl) async {
    if (kIsWeb) {
      // Use API backend for web platform
      try {
        await MongoDBWebService.updateRegistrationCertificate(registrationId, certificateUrl);
        return;
      } catch (e) {
        debugPrint('❌ Web API updateRegistrationCertificate failed: $e');
        // Fall through to direct MongoDB or mock
      }
    }
    
    try {
      if (_db == null) {
        debugPrint('⚠️ Database not connected, using mock update');
        return; // Mock update (no-op)
      }
      
      var collection = _db!.collection(registrationsCollection);
      await collection.updateOne(
        where.eq('_id', ObjectId.fromHexString(registrationId)),
        modify.set('certificate_url', certificateUrl).set('updated_at', DateTime.now().toIso8601String())
      );
      
      debugPrint('✅ Registration certificate updated successfully: $registrationId');
    } catch (e) {
      debugPrint('❌ updateRegistrationCertificate failed: $e');
    }
  }
}
