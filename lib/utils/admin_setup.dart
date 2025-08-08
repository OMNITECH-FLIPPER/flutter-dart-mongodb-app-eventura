import 'package:flutter/foundation.dart';
import '../mongodb.dart';
import '../models/user.dart';

class AdminSetup {
  static Future<void> ensureAdminUserExists() async {
    try {
      if (kIsWeb) {
        debugPrint('Skipping admin user creation on web platform');
        return;
      }
      
      // Check if admin user exists
      var adminUser = await MongoDataBase.getUserByUserId('22-4957-735');
      
      if (adminUser == null) {
        // Create admin user if it doesn't exist
        final adminUser = User(
          name: "Kyle Angelo",
          userId: "22-4957-735",
          password: "KYLO.omni0", // Will be hashed in addUser method
          role: "Admin",
          age: 25,
          email: "kyle.angelo@eventura.com",
          address: "Admin Address",
          status: "active",
        );
        
        await MongoDataBase.addUser(adminUser);
        debugPrint('Admin user created successfully');
      } else {
        debugPrint('Admin user already exists: ${adminUser.name}');
      }
    } catch (e) {
      debugPrint('Error ensuring admin user exists: $e');
    }
  }

  static Future<void> testAdminAuthentication() async {
    try {
      if (kIsWeb) {
        debugPrint('Skipping admin authentication test on web platform');
        return;
      }
      
      var user = await MongoDataBase.authenticateUser('22-4957-735', 'KYLO.omni0');
      
      if (user != null) {
        debugPrint('✅ Admin authentication successful!');
        debugPrint('Name: ${user.name}');
        debugPrint('User ID: ${user.userId}');
        debugPrint('Role: ${user.role}');
        debugPrint('Email: ${user.email}');
      } else {
        debugPrint('❌ Admin authentication failed!');
      }
    } catch (e) {
      debugPrint('Error testing admin authentication: $e');
    }
  }

  static Future<void> listAllUsers() async {
    try {
      if (kIsWeb) {
        debugPrint('Skipping user listing on web platform - using API instead');
        return;
      }
      
      var users = await MongoDataBase.getAllUsers();
      debugPrint('\n📋 All Users in Database:');
      debugPrint('Total users: ${users.length}');
      
      for (var user in users) {
        debugPrint('• ${user.name} (${user.userId}) - ${user.role}');
      }
    } catch (e) {
      debugPrint('Error listing users: $e');
    }
  }
} 