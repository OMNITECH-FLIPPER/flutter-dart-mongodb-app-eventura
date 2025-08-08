import 'package:flutter/material.dart';

class EnvConfig {
  // MongoDB Configuration
  static const String mongoUrl = String.fromEnvironment(
    'MONGO_URL',
    defaultValue: 'mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority',
  );

  static const String collectionName = String.fromEnvironment(
    'COLLECTION_NAME',
    defaultValue: 'users',
  );

  // App Configuration
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Eventura',
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  // Feature Flags
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );

  static const bool enableNotifications = bool.fromEnvironment(
    'ENABLE_NOTIFICATIONS',
    defaultValue: true,
  );

  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const int connectionTimeout = int.fromEnvironment(
    'CONNECTION_TIMEOUT',
    defaultValue: 30000,
  );

  static const int requestTimeout = int.fromEnvironment(
    'REQUEST_TIMEOUT',
    defaultValue: 10000,
  );

  // Validation method
  static void validateConfig() {
    if (mongoUrl.isEmpty || mongoUrl == 'MUST_SET_MONGO_URL') {
      throw Exception('MongoDB connection string is not set. Please provide MONGO_URL via --dart-define.');
    }
    
    if (collectionName.isEmpty) {
      throw Exception('Collection name is not set. Please provide COLLECTION_NAME via --dart-define.');
    }
    
    if (apiBaseUrl.isEmpty) {
      throw Exception('API base URL is not set. Please provide API_BASE_URL via --dart-define.');
    }
  }

  // Debug method to print current configuration
  static void printConfig() {
    debugPrint('=== Environment Configuration ===');
    debugPrint('MongoDB URL: ${mongoUrl.substring(0, mongoUrl.indexOf('@') + 1)}***');
    debugPrint('Collection Name: $collectionName');
    debugPrint('API Base URL: $apiBaseUrl');
    debugPrint('App Name: $appName');
    debugPrint('App Version: $appVersion');
    debugPrint('Enable Analytics: $enableAnalytics');
    debugPrint('Enable Notifications: $enableNotifications');
    debugPrint('Connection Timeout: $connectionTimeout');
    debugPrint('Request Timeout: $requestTimeout');
    debugPrint('================================');
  }
} 