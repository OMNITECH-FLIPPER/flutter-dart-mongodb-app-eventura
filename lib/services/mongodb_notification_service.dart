import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// Removed unused import
// Removed unused import
import '../mongodb.dart';
// Removed unused import

class NotificationData {
  final String id;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool read;
  final String? userId;
  final String? topic;
  final String type;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
    this.read = false,
    this.userId,
    this.topic,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'userId': userId,
      'topic': topic,
      'type': type,
    };
  }

  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      timestamp: DateTime.parse(map['timestamp']),
      read: map['read'] ?? false,
      userId: map['userId'],
      topic: map['topic'],
      type: map['type'],
    );
  }
}

class MongoDBNotificationService {
  static final MongoDBNotificationService _instance = MongoDBNotificationService._internal();
  factory MongoDBNotificationService() => _instance;
  MongoDBNotificationService._internal();

  bool _isInitialized = false;
  String? _currentUserId;
  List<String> _subscribedTopics = [];
  
  // API Configuration
  static const String _apiBaseUrl = 'http://localhost:3000/api';

  /// Initialize the MongoDB notification service
  static Future<void> initialize() async {
    try {
      final service = MongoDBNotificationService();
      await service._initialize();
      debugPrint('✅ MongoDB notification service initialized successfully');
    } catch (e) {
      debugPrint('❌ Failed to initialize MongoDB notification service: $e');
    }
  }

  /// Initialize the service
  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      // Load user preferences
      await _loadUserPreferences();
      
      // Start polling for notifications
      _startNotificationPolling();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error initializing MongoDB notification service: $e');
    }
  }

  /// Load user preferences from local storage
  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('current_user_id');
      _subscribedTopics = prefs.getStringList('subscribed_topics') ?? [];
      debugPrint('📱 Loaded user preferences: userId=$_currentUserId, topics=$_subscribedTopics');
    } catch (e) {
      debugPrint('❌ Error loading user preferences: $e');
    }
  }

  /// Save user preferences to local storage
  Future<void> _saveUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserId != null) {
        await prefs.setString('current_user_id', _currentUserId!);
      }
      await prefs.setStringList('subscribed_topics', _subscribedTopics);
      debugPrint('💾 Saved user preferences');
    } catch (e) {
      debugPrint('❌ Error saving user preferences: $e');
    }
  }

  /// Start polling for notifications
  void _startNotificationPolling() {
    // Poll for notifications every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      _pollForNotifications();
      _startNotificationPolling(); // Continue polling
    });
  }

  /// Poll for new notifications
  Future<void> _pollForNotifications() async {
    try {
      if (_currentUserId == null) return;

      // On web platform, use API to get notifications
      if (kIsWeb) {
        await _pollNotificationsViaAPI();
      } else {
        await _pollNotificationsViaMongoDB();
      }
    } catch (e) {
      debugPrint('❌ Error polling for notifications: $e');
    }
  }

  /// Poll notifications via API
  Future<void> _pollNotificationsViaAPI() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/notifications?userId=$_currentUserId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final notifications = data.map((json) => NotificationData.fromMap(json)).toList();
        
        // Process new notifications
        for (final notification in notifications) {
          if (!notification.read) {
            debugPrint('📱 New notification: ${notification.title}');
            // Here you would trigger local notification display
          }
        }
      }
    } catch (e) {
      debugPrint('❌ API notification polling failed: $e');
    }
  }

  /// Poll notifications via direct MongoDB
  Future<void> _pollNotificationsViaMongoDB() async {
    try {
      if (!MongoDataBase.isConnected) {
        debugPrint('⚠️ MongoDB not connected, skipping notification polling');
        return;
      }

      final db = MongoDataBase.db;
      if (db == null) {
        debugPrint('❌ Database not connected, skipping notification polling');
        return;
      }

      final collection = db.collection('notifications');
      final cursor = collection.find({
        'userId': _currentUserId,
        'read': false,
      });

      await for (final doc in cursor) {
        final notification = NotificationData.fromMap(doc);
        debugPrint('📱 New notification: ${notification.title}');
        // Here you would trigger local notification display
      }
    } catch (e) {
      debugPrint('❌ MongoDB notification polling failed: $e');
    }
  }

  /// Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      final service = MongoDBNotificationService();
      if (!service._subscribedTopics.contains(topic)) {
        service._subscribedTopics.add(topic);
        await service._saveUserPreferences();
        debugPrint('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final service = MongoDBNotificationService();
      service._subscribedTopics.remove(topic);
      await service._saveUserPreferences();
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe user to their personal topic
  static Future<void> subscribeToUserTopic(String userId) async {
    await subscribeToTopic('user_$userId');
  }

  /// Subscribe to admin topic
  static Future<void> subscribeToAdminTopic() async {
    await subscribeToTopic('admin');
  }

  /// Subscribe to organizer topic
  static Future<void> subscribeToOrganizerTopic() async {
    await subscribeToTopic('organizer');
  }

  /// Send notification to specific user
  static Future<bool> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String type = 'general',
  }) async {
    try {
      final notification = NotificationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        data: data,
        timestamp: DateTime.now(),
        userId: userId,
        type: type,
      );

      // On web platform, use API
      if (kIsWeb) {
        return await _sendNotificationViaAPI(notification);
      }

      // Store in MongoDB
      await _storeNotificationInMongoDB(notification);
      
      // Try to send via API if available
      await _sendNotificationViaAPI(notification);
      
      debugPrint('✅ Notification sent to user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending notification to user: $e');
      return false;
    }
  }

  /// Send notification to topic
  static Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    String type = 'general',
  }) async {
    try {
      final notification = NotificationData(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        data: data,
        timestamp: DateTime.now(),
        topic: topic,
        type: type,
      );

      // On web platform, use API
      if (kIsWeb) {
        return await _sendNotificationViaAPI(notification);
      }

      // Store in MongoDB
      await _storeNotificationInMongoDB(notification);
      
      // Try to send via API if available
      await _sendNotificationViaAPI(notification);
      
      debugPrint('✅ Notification sent to topic: $topic');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending notification to topic: $e');
      return false;
    }
  }

  /// Store notification in MongoDB
  static Future<void> _storeNotificationInMongoDB(NotificationData notification) async {
    try {
      if (!MongoDataBase.isConnected) {
        debugPrint('⚠️ MongoDB not connected, storing notification locally');
        await _storeNotificationLocally(notification);
        return;
      }

      final db = MongoDataBase.db;
      if (db == null) {
        debugPrint('❌ Database not connected, storing locally');
        await _storeNotificationLocally(notification);
        return;
      }
      final collection = db.collection('notifications');
      await collection.insertOne(notification.toMap());
      debugPrint('✅ Notification stored in MongoDB');
    } catch (e) {
      debugPrint('❌ Error storing notification in MongoDB: $e');
      await _storeNotificationLocally(notification);
    }
  }

  /// Send notification via API
  static Future<bool> _sendNotificationViaAPI(NotificationData notification) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(notification.toMap()),
      );
      
      if (response.statusCode == 201) {
        debugPrint('✅ Notification sent via API');
        return true;
      } else {
        debugPrint('❌ API returned status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification via API: $e');
      return false;
    }
  }

  /// Store notification locally (fallback)
  static Future<void> _storeNotificationLocally(NotificationData notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('local_notifications') ?? [];
      notifications.add(jsonEncode(notification.toMap()));
      await prefs.setStringList('local_notifications', notifications);
      debugPrint('✅ Notification stored locally');
    } catch (e) {
      debugPrint('❌ Error storing notification locally: $e');
    }
  }

  /// Get notifications for current user
  static Future<List<NotificationData>> getNotificationsForUser(String userId) async {
    try {
      // On web platform, use API
      if (kIsWeb) {
        return await _getNotificationsViaAPI(userId);
      }

      // Try direct MongoDB
      if (MongoDataBase.isConnected) {
        return await _getNotificationsViaMongoDB(userId);
      }

      // Fallback to local storage
      return await _getNotificationsLocally(userId);
    } catch (e) {
      debugPrint('❌ Error getting notifications: $e');
      return [];
    }
  }

  /// Get notifications via API
  static Future<List<NotificationData>> _getNotificationsViaAPI(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/notifications?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationData.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting notifications via API: $e');
      return [];
    }
  }

  /// Get notifications via MongoDB
  static Future<List<NotificationData>> _getNotificationsViaMongoDB(String userId) async {
    try {
      final db = MongoDataBase.db;
      if (db == null) return [];

      final collection = db.collection('notifications');
      final cursor = collection.find({'userId': userId});
      
      final notifications = <NotificationData>[];
      await for (final doc in cursor) {
        notifications.add(NotificationData.fromMap(doc));
      }
      return notifications;
    } catch (e) {
      debugPrint('❌ Error getting notifications via MongoDB: $e');
      return [];
    }
  }

  /// Get notifications from local storage
  static Future<List<NotificationData>> _getNotificationsLocally(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('local_notifications') ?? [];
      
      final userNotifications = <NotificationData>[];
      for (final notificationJson in notifications) {
        final notification = NotificationData.fromMap(jsonDecode(notificationJson));
        if (notification.userId == userId) {
          userNotifications.add(notification);
        }
      }
      return userNotifications;
    } catch (e) {
      debugPrint('❌ Error getting local notifications: $e');
      return [];
    }
  }

  /// Mark notification as read
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      // On web platform, use API
      if (kIsWeb) {
        return await _markNotificationReadViaAPI(notificationId);
      }

      // Try direct MongoDB
      if (MongoDataBase.isConnected) {
        return await _markNotificationReadViaMongoDB(notificationId);
      }

      // Fallback to local storage
      return await _markNotificationReadLocally(notificationId);
    } catch (e) {
      debugPrint('❌ Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark notification as read via API
  static Future<bool> _markNotificationReadViaAPI(String notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/notifications/$notificationId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'read': true}),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error marking notification as read via API: $e');
      return false;
    }
  }

  /// Mark notification as read via MongoDB
  static Future<bool> _markNotificationReadViaMongoDB(String notificationId) async {
    try {
      final db = MongoDataBase.db;
      if (db == null) return false;

      final collection = db.collection('notifications');
      final result = await collection.updateOne(
        {'id': notificationId},
        {'\$set': {'read': true}},
      );
      
      return result.isSuccess;
    } catch (e) {
      debugPrint('❌ Error marking notification as read via MongoDB: $e');
      return false;
    }
  }

  /// Mark notification as read locally
  static Future<bool> _markNotificationReadLocally(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('local_notifications') ?? [];
      
      for (int i = 0; i < notifications.length; i++) {
        final notification = NotificationData.fromMap(jsonDecode(notifications[i]));
        if (notification.id == notificationId) {
          notification.data['read'] = true;
          notifications[i] = jsonEncode(notification.toMap());
          await prefs.setStringList('local_notifications', notifications);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error marking notification as read locally: $e');
      return false;
    }
  }

  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      // On web platform, use API
      if (kIsWeb) {
        return await _deleteNotificationViaAPI(notificationId);
      }

      // Try direct MongoDB
      if (MongoDataBase.isConnected) {
        return await _deleteNotificationViaMongoDB(notificationId);
      }

      // Fallback to local storage
      return await _deleteNotificationLocally(notificationId);
    } catch (e) {
      debugPrint('❌ Error deleting notification: $e');
      return false;
    }
  }

  /// Delete notification via API
  static Future<bool> _deleteNotificationViaAPI(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/notifications/$notificationId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Error deleting notification via API: $e');
      return false;
    }
  }

  /// Delete notification via MongoDB
  static Future<bool> _deleteNotificationViaMongoDB(String notificationId) async {
    try {
      final db = MongoDataBase.db;
      if (db == null) return false;

      final collection = db.collection('notifications');
      final result = await collection.deleteOne({'id': notificationId});
      
      return result.isSuccess;
    } catch (e) {
      debugPrint('❌ Error deleting notification via MongoDB: $e');
      return false;
    }
  }

  /// Delete notification locally
  static Future<bool> _deleteNotificationLocally(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('local_notifications') ?? [];
      
      final updatedNotifications = <String>[];
      for (final notificationJson in notifications) {
        final notification = NotificationData.fromMap(jsonDecode(notificationJson));
        if (notification.id != notificationId) {
          updatedNotifications.add(notificationJson);
        }
      }
      
      await prefs.setStringList('local_notifications', updatedNotifications);
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting notification locally: $e');
      return false;
    }
  }

  /// Get notification count for user
  static Future<int> getNotificationCount(String userId) async {
    try {
      final notifications = await getNotificationsForUser(userId);
      return notifications.where((n) => !n.read).length;
    } catch (e) {
      debugPrint('❌ Error getting notification count: $e');
      return 0;
    }
  }

  /// Clear all notifications for user
  static Future<bool> clearAllNotifications(String userId) async {
    try {
      final notifications = await getNotificationsForUser(userId);
      bool allDeleted = true;
      
      for (final notification in notifications) {
        final deleted = await deleteNotification(notification.id);
        if (!deleted) allDeleted = false;
      }
      
      return allDeleted;
    } catch (e) {
      debugPrint('❌ Error clearing notifications: $e');
      return false;
    }
  }

  /// Set current user for notifications
  static Future<void> setCurrentUser(String userId) async {
    try {
      final service = MongoDBNotificationService();
      service._currentUserId = userId;
      await service._saveUserPreferences();
      debugPrint('✅ Current user set for notifications: $userId');
    } catch (e) {
      debugPrint('❌ Error setting current user: $e');
    }
  }

  /// Get stored notifications from local storage
  static Future<List<NotificationData>> getStoredNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = prefs.getStringList('local_notifications') ?? [];
      
      return notifications.map((json) {
        return NotificationData.fromMap(jsonDecode(json));
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting stored notifications: $e');
      return [];
    }
  }

  /// Get notification settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enabled': prefs.getBool('notifications_enabled') ?? true,
        'sound': prefs.getBool('notifications_sound') ?? true,
        'vibration': prefs.getBool('notifications_vibration') ?? true,
        'topics': prefs.getStringList('subscribed_topics') ?? [],
      };
    } catch (e) {
      debugPrint('❌ Error getting notification settings: $e');
      return {
        'enabled': true,
        'sound': true,
        'vibration': true,
        'topics': [],
      };
    }
  }

  /// Request notification permissions
  static Future<bool> requestNotificationPermissions() async {
    try {
      // For web, we'll just return true as permissions are handled by the browser
      if (kIsWeb) {
        return true;
      }
      
      // For mobile, this would typically request platform-specific permissions
      // For now, we'll return true as a placeholder
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      return false;
    }
  }
} 