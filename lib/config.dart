import 'package:flutter/material.dart';
import 'env_config.dart';

class Config {
  // Database Configuration
  /// IMPORTANT: Set your MongoDB connection string via --dart-define=MONGO_URL=... or use the default for local development.
  /// Example: mongodb+srv://username:password@cluster-url/dbname?retryWrites=true&w=majority
  static const String mongoUrl = EnvConfig.mongoUrl;

  static void assertMongoUrl() {
    EnvConfig.validateConfig();
  }
  
  static const String collectionName = EnvConfig.collectionName;
  
  // App Configuration
  static const String appName = EnvConfig.appName;
  static const String appVersion = EnvConfig.appVersion;
  
  // API Configuration
  static const String apiBaseUrl = EnvConfig.apiBaseUrl;
  static const String apiVersion = '/api';
  static const String fullApiUrl = '$apiBaseUrl$apiVersion';
  
  // API Endpoints
  static const String healthEndpoint = '$apiBaseUrl/health';
  static const String usersEndpoint = '$fullApiUrl/users';
  static const String eventsEndpoint = '$fullApiUrl/events';
  static const String registrationsEndpoint = '$fullApiUrl/registrations';
  static const String authLoginEndpoint = '$fullApiUrl/auth/login';
  
  // Color Theme
  static const Color primaryColor = Color(0xFF006B3C);
  static const Color secondaryColor = Color(0xFFFFFFFF);
  static const Color tertiaryColor = Color(0xFF000000);
  
  // Feature Flags
  static const bool enableAnalytics = EnvConfig.enableAnalytics;
  static const bool enableNotifications = EnvConfig.enableNotifications;
  
  // API Configuration
  static const int connectionTimeout = EnvConfig.connectionTimeout; // 30 seconds
  static const int requestTimeout = EnvConfig.requestTimeout; // 10 seconds
  
  // User Roles
  static const String roleUser = 'User';
  static const String roleAdmin = 'Admin';
  static const String roleOrganizer = 'Organizer';
  
  // App Routes
  static const String introductionRoute = '/';
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String userManagementRoute = '/users';
  static const String eventsRoute = '/events';
  static const String adminRoute = '/admin';
  static const String organizerRoute = '/organizer';
} 