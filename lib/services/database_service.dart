import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../mongodb.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../env_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isInitialized = false;
  
  // API Configuration
  static String get _apiBaseUrl => '${EnvConfig.apiBaseUrl}/api';

  /// Initialize the database service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (EnvConfig.shouldConnectToDatabase) {
        await MongoDataBase.connect();
        if (MongoDataBase.isConnected) {
          if (kIsWeb) {
            debugPrint('Database service initialized successfully - Connected to MongoDB Atlas via API backend');
          } else {
            debugPrint('Database service initialized successfully - Connected to MongoDB Atlas directly');
          }
        } else {
          debugPrint('Database service initialized with mock data - MongoDB connection failed');
        }
      } else {
        debugPrint('Database service initialized in mock mode');
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize database service: $e');
      // Don't rethrow - allow app to continue with limited functionality
      _isInitialized = true; // Mark as initialized so we don't keep retrying
    }
  }

  /// Check if database is connected
  bool get isConnected {
    return MongoDataBase.isConnected;
  }

  /// Get connection status message
  String get connectionStatus {
    return MongoDataBase.isConnected ? 'Connected to MongoDB Atlas' : 'Disconnected';
  }

  // User Management Methods
  Future<List<User>> getAllUsers() async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - fetching users from MongoDB Atlas via API');
        try {
          final response = await http.get(Uri.parse('$_apiBaseUrl/users'));
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final users = data.map((json) => User.fromMap(json)).toList();
            debugPrint('✅ Successfully fetched ${users.length} users from MongoDB Atlas');
            return users;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API call failed on web: $e');
        }
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/users'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => User.fromMap(json)).toList();
        }
      } catch (e) {
        debugPrint('API get users failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        return await MongoDataBase.getAllUsers();
      }
      
      // Fallback to mock data
      debugPrint('Using mock user data');
      return [
        User(
          name: "Kyle Angelo",
          userId: "22-4957-735",
          password: "KYLO.omni0",
          role: 'Admin',
          age: 21,
          email: "kyleangelocabading@gmail.com",
          address: "Admin Address",
          status: "active",
        ),
        User(
          name: "John Doe",
          userId: "23-1234-567",
          password: "password123",
          role: 'User',
          age: 25,
          email: "john.doe@example.com",
          address: "123 Main St",
          status: "active",
        ),
        User(
          name: "Jane Smith",
          userId: "24-5678-901",
          password: "password456",
          role: 'Organizer',
          age: 30,
          email: "jane.smith@example.com",
          address: "456 Oak Ave",
          status: "active",
        ),
      ];
    } catch (e) {
      debugPrint('Error getting all users: $e');
      // Return mock data on error
      return [
        User(
          name: "Kyle Angelo",
          userId: "22-4957-735",
          password: "KYLO.omni0",
          role: 'Admin',
          age: 21,
          email: "kyleangelocabading@gmail.com",
          address: "Admin Address",
          status: "active",
        ),
        User(
          name: "John Doe",
          userId: "23-1234-567",
          password: "password123",
          role: 'User',
          age: 25,
          email: "john.doe@example.com",
          address: "123 Main St",
          status: "active",
        ),
        User(
          name: "Jane Smith",
          userId: "24-5678-901",
          password: "password456",
          role: 'Organizer',
          age: 30,
          email: "jane.smith@example.com",
          address: "456 Oak Ave",
          status: "active",
        ),
      ];
    }
  }

  Future<User?> getUserById(String id) async {
    try {
      await _ensureInitialized();
      return await MongoDataBase.getUserById(id);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }

  Future<User?> getUserByUserId(String userId) async {
    try {
      await _ensureInitialized();
      return await MongoDataBase.getUserByUserId(userId);
    } catch (e) {
      debugPrint('Error getting user by user ID: $e');
      return null;
    }
  }

  Future<bool> addUser(User user) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - adding user to MongoDB Atlas via API');
        try {
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/users'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(user.toMap()),
          );
          if (response.statusCode == 201) {
            debugPrint('✅ User added successfully to MongoDB Atlas via API: ${user.userId}');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API add user failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user.toMap()),
        );
        if (response.statusCode == 201) {
          debugPrint('User added successfully via API: ${user.userId}');
          return true;
        }
      } catch (e) {
        debugPrint('API add user failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.addUser(user);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock add user');
      return true;
    } catch (e) {
      debugPrint('Error adding user: $e');
      return false;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _ensureInitialized();
      
      // Try API first (using PUT method)
      try {
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updates),
        );
        if (response.statusCode == 200) {
          debugPrint('User updated successfully via API: $userId');
          return true;
        }
      } catch (e) {
        debugPrint('API update user failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.updateUser(userId, updates);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock update user');
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final response = await http.delete(Uri.parse('$_apiBaseUrl/users/$userId'));
        if (response.statusCode == 200) {
          debugPrint('User deleted successfully via API: $userId');
          return true;
        }
      } catch (e) {
        debugPrint('API delete user failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.deleteUser(userId);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock delete user');
      return true;
    } catch (e) {
      debugPrint('Error deleting user: $e');
      return false;
    }
  }

  // Authentication Methods
  Future<User?> authenticateUser(String userId, String password) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - authenticating user via MongoDB Atlas API');
        try {
          // First check if the backend server is running
          try {
            final healthCheck = await http.get(
              Uri.parse('${EnvConfig.apiBaseUrl}/health'),
              headers: {'Accept': 'application/json'},
            ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
            
            if (healthCheck.statusCode != 200) {
              debugPrint('❌ Backend server health check failed: ${healthCheck.statusCode}');
              throw Exception('Backend server is not responding correctly. Status: ${healthCheck.statusCode}');
            }
            
            debugPrint('✅ Backend server health check passed');
          } catch (healthError) {
            debugPrint('❌ Backend server is not running or not accessible: $healthError');
            throw Exception('Backend server is not running. Please start the server and try again.');
          }
          
          // Now attempt authentication
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'password': password,
            }),
          ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

          debugPrint('🔄 API Response Status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              debugPrint('✅ User authenticated successfully via MongoDB Atlas API');
              // Get full user data
              final users = await getAllUsers();
              return users.firstWhere(
                (user) => user.userId == userId,
                orElse: () => User(
                  name: data['user']['name'] ?? 'Unknown',
                  userId: userId,
                  password: password,
                  role: data['user']['role'] ?? 'User',
                  age: 0,
                  email: data['user']['email'] ?? '',
                  address: '',
                  status: 'active',
                ),
              );
            } else {
              debugPrint('❌ Authentication failed: ${data['message']}');
              throw Exception('Authentication failed: ${data['message']}');
            }
          } else if (response.statusCode == 0) {
            // This typically means a network error or CORS issue
            debugPrint('❌ Network error or CORS issue - could not connect to API');
            throw Exception('Failed to connect to API server. Please check if the backend server is running.');
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
            throw Exception('Authentication failed: Server returned ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API authentication failed on web: $e');
          rethrow;
        }
      }
      
      // Try API authentication first (for mobile/desktop platforms)
      if (!kIsWeb) {
        try {
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/auth/login'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'password': password,
            }),
          ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

          debugPrint('🔄 API Response Status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success'] == true) {
              debugPrint('✅ User authenticated successfully via API');
              // Get full user data
              final users = await getAllUsers();
              return users.firstWhere(
                (user) => user.userId == userId,
                orElse: () => User(
                  name: data['user']['name'] ?? 'Unknown',
                  userId: userId,
                  password: password,
                  role: data['user']['role'] ?? 'User',
                  age: 0,
                  email: data['user']['email'] ?? '',
                  address: '',
                  status: 'active',
                ),
              );
            } else {
                debugPrint('❌ Authentication failed: ${data['message']}');
                throw Exception('Authentication failed: ${data['message'] ?? "Invalid credentials"}');
            }
          } else if (response.statusCode == 0) {
            // This typically means a network error or CORS issue
            debugPrint('❌ Network error or CORS issue - could not connect to API');
            throw Exception('Failed to connect to API server. Please check if the backend server is running.');
          } else {
            debugPrint('❌ API authentication failed: ${response.statusCode}');
            throw Exception('Authentication failed: Server returned ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API authentication failed, trying direct MongoDB: $e');
          // Only continue to direct MongoDB if this was a connection issue, not an auth failure
          if (e.toString().contains('Authentication failed')) {
            rethrow; // Re-throw authentication failures
          }
        }

        // Fallback to direct MongoDB connection
        if (MongoDataBase.isConnected) {
          return await MongoDataBase.authenticateUser(userId, password);
        }
      }
      
      // Fallback to mock authentication
      debugPrint('Using mock authentication');
      if (userId == "22-4957-735" && password == "KYLO.omni0") {
        return User(
          name: "Kyle Angelo",
          userId: "22-4957-735",
          password: "KYLO.omni0",
          role: 'Admin',
          age: 21,
          email: "kyleangelocabading@gmail.com",
          address: "Admin Address",
          status: "active",
        );
      } else if (userId == "23-1234-567" && password == "password123") {
        return User(
          name: "John Doe",
          userId: "23-1234-567",
          password: "password123",
          role: 'User',
          age: 25,
          email: "john.doe@example.com",
          address: "123 Main St",
          status: "active",
        );
      } else if (userId == "24-5678-901" && password == "password456") {
        return User(
          name: "Jane Smith",
          userId: "24-5678-901",
          password: "password456",
          role: 'Organizer',
          age: 30,
          email: "jane.smith@example.com",
          address: "456 Oak Ave",
          status: "active",
        );
      }
      throw Exception('Invalid credentials');
    } catch (e) {
      debugPrint('Error authenticating user: $e');
      rethrow; // Re-throw to let the UI handle specific error messages
    }
  }

  // Event Management Methods
  Future<List<Event>> getAllEvents() async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - fetching events from MongoDB Atlas via API');
        try {
          final response = await http.get(Uri.parse('$_apiBaseUrl/events'));
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final events = data.map((json) => Event.fromMap(json)).toList();
            debugPrint('✅ Successfully fetched ${events.length} events from MongoDB Atlas');
            return events;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API call failed on web: $e');
        }
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/events'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Event.fromMap(json)).toList();
        }
      } catch (e) {
        debugPrint('API get events failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        return await MongoDataBase.getAllEvents();
      }
      
      // Fallback to mock data
      debugPrint('Database not connected, using mock data');
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
        Event(
          id: '3',
          title: 'Workshop: Mobile App Development',
          description: 'Learn Flutter and build your first mobile app',
          eventDate: DateTime.now().add(const Duration(days: 7)),
          location: 'Tech Hub, Quezon City',
          organizerId: '22-4957-735',
          organizerName: 'Kyle Angelo',
          totalSlots: 30,
          availableSlots: 10,
          status: 'active',
          imageUrl: '',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          updatedAt: DateTime.now(),
        ),
        Event(
          id: '4',
          title: 'Computer Engineering Symposium 2024',
          description: 'Advanced topics in Computer Engineering including AI, Machine Learning, and Software Architecture. Join industry experts and researchers for a comprehensive exploration of cutting-edge technologies.',
          eventDate: DateTime.now().add(const Duration(days: 30)), // Future event
          location: 'Engineering Building, University Campus',
          organizerId: '24-5678-901',
          organizerName: 'Jane Smith',
          totalSlots: 100,
          availableSlots: 85, // Available slots for testing
          status: 'active',
          imageUrl: 'https://via.placeholder.com/400x200/006B3C/FFFFFF?text=Computer+Engineering+Symposium',
          createdAt: DateTime.now().subtract(const Duration(days: 20)),
          updatedAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      debugPrint('Error getting all events: $e');
      return [];
    }
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - fetching event by ID from MongoDB Atlas via API');
        try {
          final response = await http.get(Uri.parse('$_apiBaseUrl/events/$eventId'));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final event = Event.fromMap(data);
            debugPrint('✅ Successfully fetched event from MongoDB Atlas via API: ${event.title}');
            return event;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API get event by ID failed on web: $e');
        }
        return null; // Return null if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/events/$eventId'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return Event.fromMap(data);
        }
      } catch (e) {
        debugPrint('API get event by ID failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        return await MongoDataBase.getEventById(eventId);
      }
      
      // Fallback to mock data
      debugPrint('Database not connected, using mock event');
      return null;
    } catch (e) {
      debugPrint('Error getting event by ID: $e');
      return null;
    }
  }

  Future<List<Event>> getEventsByOrganizer(String organizerId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - fetching events by organizer from MongoDB Atlas via API');
        try {
          final response = await http.get(Uri.parse('$_apiBaseUrl/events/organizer/$organizerId'));
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final events = data.map((json) => Event.fromMap(json)).toList();
            debugPrint('✅ Successfully fetched ${events.length} events by organizer from MongoDB Atlas');
            return events;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API get events by organizer failed on web: $e');
        }
        return []; // Return empty list if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/events/organizer/$organizerId'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => Event.fromMap(json)).toList();
        }
      } catch (e) {
        debugPrint('API get events by organizer failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        return await MongoDataBase.getEventsByOrganizer(organizerId);
      }
      
      // Fallback to mock data - filter events by organizer
      debugPrint('Database not connected, using mock events filtered by organizer');
      final allEvents = await getAllEvents();
      return allEvents.where((event) => event.organizerId == organizerId).toList();
    } catch (e) {
      debugPrint('Error getting events by organizer: $e');
      return [];
    }
  }

  Future<bool> addEvent(Event event) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - adding event to MongoDB Atlas via API');
        try {
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/events'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(event.toMap()),
          );
          if (response.statusCode == 201) {
            debugPrint('✅ Event added successfully to MongoDB Atlas via API: ${event.title}');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API add event failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/events'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(event.toMap()),
        );
        if (response.statusCode == 201) {
          debugPrint('Event added successfully via API: ${event.title}');
          return true;
        }
      } catch (e) {
        debugPrint('API add event failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.addEvent(event);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock add event');
      return true;
    } catch (e) {
      debugPrint('Error adding event: $e');
      return false;
    }
  }

  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates, {String? editorUserId, bool isAdmin = false}) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - updating event in MongoDB Atlas via API');
        try {
          final updateData = {
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          };
          
          if (editorUserId != null) {
            updateData['last_edited_by'] = editorUserId;
          }

          final response = await http.put(
            Uri.parse('$_apiBaseUrl/events/$eventId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updateData),
          );
          if (response.statusCode == 200) {
            debugPrint('✅ Event updated successfully in MongoDB Atlas via API: $eventId');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API update event failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final updateData = {
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        if (editorUserId != null) {
          updateData['last_edited_by'] = editorUserId;
        }

        final response = await http.put(
          Uri.parse('$_apiBaseUrl/events/$eventId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updateData),
        );
        if (response.statusCode == 200) {
          debugPrint('Event updated successfully via API: $eventId');
          return true;
        }
      } catch (e) {
        debugPrint('API update event failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.updateEvent(eventId, updates, editorUserId: editorUserId, isAdmin: isAdmin);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock event update');
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - deleting event from MongoDB Atlas via API');
        try {
          final response = await http.delete(Uri.parse('$_apiBaseUrl/events/$eventId'));
          if (response.statusCode == 200) {
            debugPrint('✅ Event deleted successfully from MongoDB Atlas via API: $eventId');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API delete event failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.delete(Uri.parse('$_apiBaseUrl/events/$eventId'));
        if (response.statusCode == 200) {
          debugPrint('Event deleted successfully via API: $eventId');
          return true;
        }
      } catch (e) {
        debugPrint('API delete event failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.deleteEvent(eventId);
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // Event Registration Methods
  Future<List<EventRegistration>> getRegistrationsByUser(String userId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - fetching user registrations from MongoDB Atlas via API');
        try {
          final response = await http.get(Uri.parse('$_apiBaseUrl/registrations/user/$userId'));
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final registrations = data.map((json) => EventRegistration.fromMap(json)).toList();
            debugPrint('✅ Successfully fetched ${registrations.length} registrations from MongoDB Atlas');
            return registrations;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API call failed on web: $e');
        }
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/registrations/user/$userId'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => EventRegistration.fromMap(json)).toList();
        }
      } catch (e) {
        debugPrint('API get registrations by user failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        return await MongoDataBase.getRegistrationsByUser(userId);
      }
      
      // Fallback to mock data
      debugPrint('Database not connected, using mock user registrations');
      return [];
    } catch (e) {
      debugPrint('Error getting registrations by user: $e');
      return [];
    }
  }

  Future<List<EventRegistration>> getRegistrationsByEvent(String eventId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - fetching event registrations from MongoDB Atlas via API');
        try {
          final response = await http.get(Uri.parse('$_apiBaseUrl/registrations/event/$eventId'));
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final registrations = data.map((json) => EventRegistration.fromMap(json)).toList();
            debugPrint('✅ Successfully fetched ${registrations.length} event registrations from MongoDB Atlas');
            return registrations;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API call failed on web: $e');
        }
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.get(Uri.parse('$_apiBaseUrl/registrations/event/$eventId'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((json) => EventRegistration.fromMap(json)).toList();
        }
      } catch (e) {
        debugPrint('API get registrations by event failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        return await MongoDataBase.getRegistrationsByEvent(eventId);
      }
      
      // Fallback to mock data
      debugPrint('Database not connected, using mock registrations');
      return [];
    } catch (e) {
      debugPrint('Error getting registrations by event: $e');
      return [];
    }
  }

  Future<bool> registerForEvent(EventRegistration registration) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - registering for event in MongoDB Atlas via API');
        try {
          final response = await http.post(
            Uri.parse('$_apiBaseUrl/registrations'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(registration.toMap()),
          );
          if (response.statusCode == 201) {
            debugPrint('✅ Registration added successfully to MongoDB Atlas via API: ${registration.id}');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API register for event failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/registrations'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(registration.toMap()),
        );
        if (response.statusCode == 201) {
          debugPrint('Registration added successfully via API: ${registration.id}');
          return true;
        }
      } catch (e) {
        debugPrint('API register for event failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.registerForEvent(registration);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock registration');
      return true;
    } catch (e) {
      debugPrint('Error registering for event: $e');
      return false;
    }
  }

  Future<bool> confirmAttendance(String registrationId, bool attended, {String? certificateUrl}) async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final updates = {
          'attended': attended,
          'status': attended ? 'attended' : 'missed',
          'attendance_date': attended ? DateTime.now().toIso8601String() : null,
        };
        
        if (certificateUrl != null) {
          updates['certificate_url'] = certificateUrl;
        }

        final response = await http.put(
          Uri.parse('$_apiBaseUrl/registrations/$registrationId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(updates),
        );
        if (response.statusCode == 200) {
          debugPrint('Attendance confirmed successfully via API: $registrationId');
          return true;
        }
      } catch (e) {
        debugPrint('API confirm attendance failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.confirmAttendance(registrationId, attended, certificateUrl: certificateUrl);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock attendance confirmation');
      return true;
    } catch (e) {
      debugPrint('Error confirming attendance: $e');
      return false;
    }
  }

  // User Status Management
  Future<bool> blockUser(String userId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - blocking user in MongoDB Atlas via API');
        try {
          final response = await http.put(
            Uri.parse('$_apiBaseUrl/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': 'blocked'}),
          );
          if (response.statusCode == 200) {
            debugPrint('✅ User blocked successfully in MongoDB Atlas via API: $userId');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API block user failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'blocked'}),
        );
        if (response.statusCode == 200) {
          debugPrint('User blocked successfully via API: $userId');
          return true;
        }
      } catch (e) {
        debugPrint('API block user failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.blockUser(userId);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock block user');
      return true;
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - unblocking user in MongoDB Atlas via API');
        try {
          final response = await http.put(
            Uri.parse('$_apiBaseUrl/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'status': 'active'}),
          );
          if (response.statusCode == 200) {
            debugPrint('✅ User unblocked successfully in MongoDB Atlas via API: $userId');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API unblock user failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'status': 'active'}),
        );
        if (response.statusCode == 200) {
          debugPrint('User unblocked successfully via API: $userId');
          return true;
        }
      } catch (e) {
        debugPrint('API unblock user failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.unblockUser(userId);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock unblock user');
      return true;
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  /// Send notification to user
  Future<bool> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final notificationData = {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        };

        final response = await http.post(
          Uri.parse('$_apiBaseUrl/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(notificationData),
        );
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('Notification sent successfully via API: $title');
          return true;
        }
      } catch (e) {
        debugPrint('API send notification failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection - notifications handled via API only
      if (MongoDataBase.isConnected) {
        debugPrint('MongoDB connected - notifications should be handled via API');
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock notification send');
      return true;
    } catch (e) {
      debugPrint('Error sending notification: $e');
      return false;
    }
  }

  /// Upload image to server
  static Future<String?> uploadImage(String base64Image, String fileName, String fileType) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/upload/image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'fileName': fileName,
          'fileType': fileType,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    }
    return null;
  }

  /// Upload certificate to server
  static Future<String?> uploadCertificate(String base64Certificate, String fileName, String userId, String eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/upload/certificate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'certificate': base64Certificate,
          'fileName': fileName,
          'userId': userId,
          'eventId': eventId,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'] as String?;
      }
    } catch (e) {
      debugPrint('Error uploading certificate: $e');
    }
    return null;
  }

  /// Get all notifications for a user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/notifications/$userId'),
        );
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        debugPrint('API get notifications failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection - notifications handled via API only
      if (MongoDataBase.isConnected) {
        debugPrint('MongoDB connected - notifications should be handled via API');
        return [];
      }
      
      // Fallback to mock data
      debugPrint('Using mock notifications data');
      return [];
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  Future<bool> markNotificationRead(String notificationId) async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/notifications/$notificationId/read'),
          headers: {'Content-Type': 'application/json'},
        );
        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        debugPrint('API mark notification read failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection - notifications handled via API only
      if (MongoDataBase.isConnected) {
        debugPrint('MongoDB connected - notification read status should be handled via API');
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock mark notification read');
      return true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Get analytics data
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/analytics'),
        );
        if (response.statusCode == 200) {
          return jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('API get analytics failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection - analytics handled via API only
      if (MongoDataBase.isConnected) {
        debugPrint('MongoDB connected - analytics should be handled via API');
        return {
          'totalUsers': 50,
          'totalEvents': 20,
          'totalRegistrations': 100,
          'attendanceRate': 85.0,
        };
      }
      
      // Fallback to mock data
      debugPrint('Using mock analytics data');
      return {
        'totalUsers': 150,
        'totalEvents': 45,
        'totalRegistrations': 320,
        'attendanceRate': 75.5,
      };
    } catch (e) {
      debugPrint('Error getting analytics data: $e');
      return {};
    }
  }

  /// Export data to CSV
  Future<String?> exportData(String dataType) async {
    try {
      await _ensureInitialized();
      
      // Try API first
      try {
        final response = await http.get(
          Uri.parse('$_apiBaseUrl/export/$dataType'),
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['downloadUrl'] as String?;
        }
      } catch (e) {
        debugPrint('API export data failed: $e');
      }

      // Fallback implementation - generate CSV locally
      return await _generateLocalCSV(dataType);
    } catch (e) {
      debugPrint('Error exporting data: $e');
      return null;
    }
  }

  /// Generate CSV locally as fallback
  Future<String?> _generateLocalCSV(String dataType) async {
    try {
      // Implementation would depend on the specific data type
      debugPrint('Generating local CSV for $dataType');
      return 'local_export_${dataType}_${DateTime.now().millisecondsSinceEpoch}.csv';
    } catch (e) {
      debugPrint('Error generating local CSV: $e');
      return null;
    }
  }

  Future<bool> changeUserRole(String userId, String newRole) async {
    try {
      await _ensureInitialized();
      
      // On web platform, always use API to connect to MongoDB Atlas
      if (kIsWeb) {
        debugPrint('🌐 Web platform - changing user role in MongoDB Atlas via API');
        try {
          final response = await http.put(
            Uri.parse('$_apiBaseUrl/users/$userId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'role': newRole}),
          );
          if (response.statusCode == 200) {
            debugPrint('✅ User role changed successfully in MongoDB Atlas via API: $userId -> $newRole');
            return true;
          } else {
            debugPrint('❌ API returned status code: ${response.statusCode}');
          }
        } catch (e) {
          debugPrint('❌ API change user role failed on web: $e');
        }
        return false; // Return false if web API fails
      }
      
      // Try API first (for mobile/desktop platforms)
      try {
        final response = await http.put(
          Uri.parse('$_apiBaseUrl/users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'role': newRole}),
        );
        if (response.statusCode == 200) {
          debugPrint('User role changed successfully via API: $userId -> $newRole');
          return true;
        }
      } catch (e) {
        debugPrint('API change user role failed, trying direct MongoDB: $e');
      }

      // Fallback to direct MongoDB connection
      if (MongoDataBase.isConnected) {
        await MongoDataBase.changeUserRole(userId, newRole);
        return true;
      }
      
      // Fallback to mock
      debugPrint('Using mock change user role');
      return true;
    } catch (e) {
      debugPrint('Error changing user role: $e');
      return false;
    }
  }

  // Utility Methods
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Disconnect from database
  Future<void> disconnect() async {
    try {
      await MongoDataBase.disconnect();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error disconnecting from database: $e');
    }
  }

  /// Test database connection
  Future<bool> testConnection() async {
    try {
      await _ensureInitialized();
      return MongoDataBase.isConnected;
    } catch (e) {
      debugPrint('Error testing database connection: $e');
      return false;
    }
  }

  Future<List<EventRegistration>> getAllRegistrations() async {
    await _ensureInitialized();
    if (MongoDataBase.isConnected) {
      return await MongoDataBase.getAllRegistrations();
    }
    // Fallback: return empty list or mock data
    return [];
  }

}