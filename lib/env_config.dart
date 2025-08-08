import 'package:flutter/foundation.dart';

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
  
  // Web-specific API URL - defaults to the same as apiBaseUrl but can be overridden
  static String get webApiUrl {
    // For web platforms, we might need to use a different URL (e.g., relative path or different domain)
    if (kIsWeb) {
      // Check if we're running on localhost
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        // When running locally, use the standard localhost URL
        return apiBaseUrl;
      } else {
        // When deployed, use a relative URL to the current domain
        // This avoids CORS issues when the app is deployed
        return '/api';
      }
    }
    // For non-web platforms, just use the standard API URL
    return apiBaseUrl;
  }

  static const int connectionTimeout = int.fromEnvironment(
    'CONNECTION_TIMEOUT',
    defaultValue: 30000,
  );

  static const int requestTimeout = int.fromEnvironment(
    'REQUEST_TIMEOUT',
    defaultValue: 10000,
  );
  
  // Platform detection
  static bool get isWeb => kIsWeb;
  
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  // Database connection flag
  static const bool shouldConnectToDatabase = true;
  
  // Validation
  static bool validateConfig() {
    if (kIsWeb) {
      // For web, we only need to validate the API URL
      if (apiBaseUrl.isEmpty) {
        debugPrint('❌ API_BASE_URL is empty');
        return false;
      }
      return true;
    }
    
    // For non-web platforms, validate MongoDB connection details
    if (mongoUrl.isEmpty) {
      debugPrint('❌ MONGO_URL is empty');
      return false;
    }
    
    if (collectionName.isEmpty) {
      debugPrint('❌ COLLECTION_NAME is empty');
      return false;
    }
    
    if (apiBaseUrl.isEmpty) {
      debugPrint('❌ API_BASE_URL is empty');
      return false;
    }
    
    return true;
  }
  
  // Debug output
  static void printConfig() {
    debugPrint('📱 App Configuration:');
    debugPrint('   App Name: $appName');
    debugPrint('   App Version: $appVersion');
    debugPrint('   Platform: ${kIsWeb ? "Web" : defaultTargetPlatform.toString()}');
    
    if (kIsWeb) {
      debugPrint('🌐 Web API Configuration:');
      debugPrint('   API Base URL: $apiBaseUrl');
      debugPrint('   Web API URL: $webApiUrl');
    } else {
      debugPrint('💾 Database Configuration:');
      // Mask sensitive parts of the MongoDB URL
      final maskedUrl = mongoUrl.contains('@') 
          ? '${mongoUrl.substring(0, mongoUrl.indexOf('@') + 1)}***' 
          : mongoUrl;
      debugPrint('   MongoDB URL: $maskedUrl');
      debugPrint('   Collection Name: $collectionName');
      
      debugPrint('🌐 API Configuration:');
      debugPrint('   API Base URL: $apiBaseUrl');
    }
    
    debugPrint('⚙️ Timeouts:');
    debugPrint('   Connection Timeout: ${connectionTimeout}ms');
    debugPrint('   Request Timeout: ${requestTimeout}ms');
    
    debugPrint('🚩 Feature Flags:');
    debugPrint('   Analytics Enabled: $enableAnalytics');
    debugPrint('   Notifications Enabled: $enableNotifications');
    debugPrint('   Should Connect to Database: $shouldConnectToDatabase');
  }
}