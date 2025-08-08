import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../env_config.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';

class MongoDBWebService {
  // Use the webApiUrl getter from EnvConfig to ensure proper URL for web platform
  static String get baseUrl => kIsWeb ? EnvConfig.webApiUrl : EnvConfig.apiBaseUrl;
  
  // Authentication
  static Future<User?> authenticateUser(String userId, String password) async {
    try {
      debugPrint('🌐 Web service - authenticating user via API');
      debugPrint('🔗 API URL: $baseUrl/api/auth/login');
      
      // Add appropriate headers for the request
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'password': password,
        }),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

      debugPrint('🔄 API Response Status: ${response.statusCode}');
      
      // For debugging purposes
      try {
        debugPrint('🔄 API Response Body: ${response.body}');
      } catch (e) {
        debugPrint('⚠️ Could not print response body: $e');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          debugPrint('✅ Authentication successful');
          final userData = data['user'];
          return User(
            name: userData['name'] ?? 'Unknown',
            userId: userData['userId'] ?? userId,
            password: password, // Keep original password for compatibility
            role: userData['role'] ?? 'User',
            age: userData['age'] ?? 0, // Default age
            email: userData['email'] ?? '',
            address: userData['address'] ?? '', // Default address
            status: userData['status'] ?? 'active',
          );
        } else {
          debugPrint('❌ API authentication failed: ${data['message']}');
        }
      } else if (response.statusCode == 0) {
        // This typically means a network error or CORS issue
        debugPrint('❌ Network error or CORS issue - could not connect to API');
        throw Exception('Failed to connect to API server. Please check if the backend server is running.');
      } else {
        debugPrint('❌ API authentication failed: ${response.statusCode} - ${response.body}');
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Web authentication error: $e');
      // Return a more user-friendly error message
      throw Exception('Failed to fetch, uri=$baseUrl/api/auth/login');
    }
  }

  // User management
  static Future<List<User>> getAllUsers() async {
    try {
      debugPrint('🌐 Web service - fetching all users via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => User.fromMap(json)).toList();
      }
      
      debugPrint('❌ API failed to fetch users: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch users: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching users via API: $e');
      rethrow;
    }
  }

  static Future<User?> getUserByUserId(String userId) async {
    try {
      debugPrint('🌐 Web service - fetching user $userId via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromMap(data);
      }
      
      debugPrint('❌ API failed to fetch user: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching user via API: $e');
      return null;
    }
  }
  
  // Get user by ID
  static Future<User?> getUserById(String id) async {
    try {
      debugPrint('🌐 Web service - fetching user by ID via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return User.fromMap(data);
      }
      
      debugPrint('❌ API failed to fetch user by ID: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch user by ID: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching user by ID via API: $e');
      rethrow;
    }
  }
  
  // Delete user
  static Future<void> deleteUser(String userId) async {
    try {
      debugPrint('🌐 Web service - deleting user $userId via API');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ User $userId deleted successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to delete user: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to delete user: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error deleting user via API: $e');
      rethrow;
    }
  }

  static Future<void> addUser(User user) async {
    try {
      debugPrint('🌐 Web service - adding user via API');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toMap()),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

      if (response.statusCode != 201) {
        debugPrint('❌ API failed to add user: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to add user: ${response.statusCode}');
      }
      
      debugPrint('✅ User added successfully via API');
    } catch (e) {
      debugPrint('❌ Error adding user via API: $e');
      rethrow;
    }
  }
  
  // Update user
  static Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🌐 Web service - updating user $userId via API');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

      if (response.statusCode != 200) {
        debugPrint('❌ API failed to update user: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update user: ${response.statusCode}');
      }
      
      debugPrint('✅ User updated successfully via API');
    } catch (e) {
      debugPrint('❌ Error updating user via API: $e');
      rethrow;
    }
  }
  
  // Event management
  static Future<List<Event>> getAllEvents() async {
    try {
      debugPrint('🌐 Web service - fetching all events via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/events'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromMap(json)).toList();
      }
      
      debugPrint('❌ API failed to fetch events: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch events: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching events via API: $e');
      rethrow;
    }
  }
  
  // Get event by ID
  static Future<Event?> getEventById(String eventId) async {
    try {
      debugPrint('🌐 Web service - fetching event $eventId via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Event.fromMap(data);
      }
      
      debugPrint('❌ API failed to fetch event: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch event: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching event via API: $e');
      rethrow;
    }
  }
  
  // Get events by organizer
  static Future<List<Event>> getEventsByOrganizer(String organizerId) async {
    try {
      debugPrint('🌐 Web service - fetching events for organizer $organizerId via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/organizer/$organizerId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Event.fromMap(json)).toList();
      }
      
      debugPrint('❌ API failed to fetch organizer events: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch organizer events: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching organizer events via API: $e');
      rethrow;
    }
  }
  
  // Add event
  static Future<void> addEvent(Event event) async {
    try {
      debugPrint('🌐 Web service - adding event via API');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toMap()),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

      if (response.statusCode != 201) {
        debugPrint('❌ API failed to add event: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to add event: ${response.statusCode}');
      }
      
      debugPrint('✅ Event added successfully via API');
    } catch (e) {
      debugPrint('❌ Error adding event via API: $e');
      rethrow;
    }
  }
  
  // Update event
  static Future<void> updateEvent(String eventId, Map<String, dynamic> updates, {String? editorUserId, bool isAdmin = false}) async {
    try {
      debugPrint('🌐 Web service - updating event $eventId via API');
      
      // Add editor information to the request if provided
      Map<String, dynamic> requestBody = {...updates};
      if (editorUserId != null) {
        requestBody['editor_user_id'] = editorUserId;
      }
      requestBody['is_admin'] = isAdmin;
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

      if (response.statusCode != 200) {
        debugPrint('❌ API failed to update event: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update event: ${response.statusCode}');
      }
      
      debugPrint('✅ Event updated successfully via API');
    } catch (e) {
      debugPrint('❌ Error updating event via API: $e');
      rethrow;
    }
  }
  
  // Health check method to verify API connectivity
  static Future<bool> checkApiConnection() async {
    try {
      debugPrint('🔍 Checking API connection at $baseUrl');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.connectionTimeout));
      
      final isConnected = response.statusCode >= 200 && response.statusCode < 300;
      debugPrint(isConnected ? '✅ API connection successful' : '❌ API connection failed: ${response.statusCode}');
      return isConnected;
    } catch (e) {
      debugPrint('❌ API connection check failed: $e');
      return false;
    }
  }

  // Save QR code data
  static Future<void> saveQRCode(Map<String, dynamic> qrData) async {
    try {
      debugPrint('🌐 Web service - saving QR code data via API');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/qr-codes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...qrData,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));

      if (response.statusCode != 201) {
        debugPrint('❌ API failed to save QR code data: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to save QR code data: ${response.statusCode}');
      }
      
      debugPrint('✅ QR code data saved successfully via API');
    } catch (e) {
      debugPrint('❌ Error saving QR code data via API: $e');
      rethrow;
    }
  }

  // Get all event registrations
  static Future<List<EventRegistration>> getAllRegistrations() async {
    try {
      debugPrint('🌐 Web service - fetching all registrations via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/registrations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventRegistration.fromMap(json)).toList();
      }
      
      debugPrint('❌ API failed to fetch registrations: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch registrations: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching registrations via API: $e');
      rethrow;
    }
  }
  
  // Unblock a user
  static Future<void> unblockUser(String userId) async {
    try {
      debugPrint('🌐 Web service - unblocking user via API');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId/unblock'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ User $userId unblocked successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to unblock user: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to unblock user: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error unblocking user via API: $e');
      rethrow;
    }
  }
  
  // Change user role
  static Future<void> changeUserRole(String userId, String newRole) async {
    try {
      debugPrint('🌐 Web service - changing user role via API');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId/role'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'role': newRole}),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ User $userId role changed to $newRole successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to change user role: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to change user role: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error changing user role via API: $e');
      rethrow;
    }
  }
  
  // Block a user
  static Future<void> blockUser(String userId) async {
    try {
      debugPrint('🌐 Web service - blocking user via API');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId/block'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ User $userId blocked successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to block user: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to block user: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error blocking user via API: $e');
      rethrow;
    }
  }
  
  // Confirm attendance for an event registration
  static Future<void> confirmAttendance(String registrationId, bool attended, {String? certificateUrl}) async {
    try {
      debugPrint('🌐 Web service - confirming attendance via API');
      
      final Map<String, dynamic> data = {
        'attended': attended,
      };
      
      if (certificateUrl != null) {
        data['certificateUrl'] = certificateUrl;
      }
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/registrations/$registrationId/attendance'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Registration $registrationId attendance updated to $attended successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to confirm attendance: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to confirm attendance: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error confirming attendance via API: $e');
      rethrow;
    }
  }
  
  // Get registrations by event
  static Future<List<EventRegistration>> getRegistrationsByEvent(String eventId) async {
    try {
      debugPrint('🌐 Web service - fetching registrations for event $eventId via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/events/$eventId/registrations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventRegistration.fromMap(json)).toList();
      }
      
      debugPrint('❌ API failed to fetch registrations: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch registrations: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching registrations via API: $e');
      rethrow;
    }
  }
  
  // Get registrations by user
  static Future<List<EventRegistration>> getRegistrationsByUser(String userId) async {
    try {
      debugPrint('🌐 Web service - fetching registrations for user $userId via API');
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/registrations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => EventRegistration.fromMap(json)).toList();
      }
      
      debugPrint('❌ API failed to fetch user registrations: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch user registrations: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error fetching user registrations via API: $e');
      rethrow;
    }
  }
  
  // Delete event
  static Future<void> deleteEvent(String eventId) async {
    try {
      debugPrint('🌐 Web service - deleting event $eventId via API');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/api/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Event $eventId deleted successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to delete event: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to delete event: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error deleting event via API: $e');
      rethrow;
    }
  }
  
  // Register for event
  static Future<void> registerForEvent(EventRegistration registration) async {
    try {
      debugPrint('🌐 Web service - registering for event via API');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/registrations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(registration.toMap()),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 201) {
        debugPrint('✅ Registration for event ${registration.eventId} added successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to register for event: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to register for event: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error registering for event via API: $e');
      rethrow;
    }
  }
  
  // Upload certificate file
  static Future<String> uploadCertificateFile(dynamic file, String registrationId) async {
    try {
      debugPrint('🌐 Web service - uploading certificate file via API');
      
      // For web platform, this would typically use multipart/form-data
      // For now, return a mock URL since file upload requires specific backend implementation
      final mockUrl = 'https://api.eventura.com/certificates/$registrationId.pdf';
      debugPrint('✅ Certificate file uploaded (mock): $mockUrl');
      return mockUrl;
    } catch (e) {
      debugPrint('❌ Error uploading certificate file via API: $e');
      rethrow;
    }
  }
  
  // Update registration certificate
  static Future<void> updateRegistrationCertificate(String registrationId, String certificateUrl) async {
    try {
      debugPrint('🌐 Web service - updating registration certificate via API');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/registrations/$registrationId/certificate'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'certificateUrl': certificateUrl,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      ).timeout(Duration(milliseconds: EnvConfig.requestTimeout));
      
      if (response.statusCode == 200) {
        debugPrint('✅ Registration certificate updated successfully via API');
        return;
      }
      
      debugPrint('❌ API failed to update registration certificate: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update registration certificate: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error updating registration certificate via API: $e');
      rethrow;
    }
  }
}
