import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mongodb.dart';
import '../models/user.dart';
import 'email_service.dart';

class PasswordResetService {
  static final PasswordResetService _instance = PasswordResetService._internal();
  factory PasswordResetService() => _instance;
  PasswordResetService._internal();

  // JWT Secret (in production, this should be stored securely)
  static const String _jwtSecret = 'eventura_jwt_secret_key_2024';
  static const int _tokenExpirationHours = 1; // Token expires in 1 hour

  /// Generate a password reset token
  static String _generateToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Create a JWT token for password reset
  static String _createJWTToken(String userId, String email) {
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };

    final payload = {
      'sub': userId,
      'email': email,
      'type': 'password_reset',
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp': (DateTime.now().add(Duration(hours: _tokenExpirationHours)).millisecondsSinceEpoch ~/ 1000),
    };

    final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
    final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
    
    final signature = Hmac(sha256, utf8.encode(_jwtSecret))
        .convert(utf8.encode('$encodedHeader.$encodedPayload'));
    final encodedSignature = base64Url.encode(signature.bytes);

    return '$encodedHeader.$encodedPayload.$encodedSignature';
  }

  /// Verify JWT token
  static Map<String, dynamic>? _verifyJWTToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final header = parts[0];
      final payload = parts[1];
      final signature = parts[2];

      // Verify signature
      final expectedSignature = Hmac(sha256, utf8.encode(_jwtSecret))
          .convert(utf8.encode('$header.$payload'));
      final expectedEncodedSignature = base64Url.encode(expectedSignature.bytes);

      if (signature != expectedEncodedSignature) {
        debugPrint('❌ JWT signature verification failed');
        return null;
      }

      // Decode payload
      final decodedPayload = utf8.decode(base64Url.decode(payload));
      final payloadData = jsonDecode(decodedPayload) as Map<String, dynamic>;

      // Check expiration
      final expiration = payloadData['exp'] as int;
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (currentTime > expiration) {
        debugPrint('❌ JWT token expired');
        return null;
      }

      return payloadData;
    } catch (e) {
      debugPrint('❌ JWT token verification error: $e');
      return null;
    }
  }

  /// Request password reset
  static Future<bool> requestPasswordReset(String emailOrUserId) async {
    try {
      // Find user by email or user ID
      User? user;
      
      if (emailOrUserId.contains('@')) {
        // Search by email
        final users = await MongoDataBase.getAllUsers();
        user = users.firstWhere(
          (u) => u.email.toLowerCase() == emailOrUserId.toLowerCase(),
          orElse: () => throw Exception('User not found'),
        );
      } else {
        // Search by user ID
        user = await MongoDataBase.getUserByUserId(emailOrUserId);
        if (user == null) {
          throw Exception('User not found');
        }
      }

      // Check if user is active
      if (user.status != 'active') {
        throw Exception('Account is not active');
      }

      // Generate reset token
      final resetToken = _createJWTToken(user.userId, user.email);

      // Store token in database (you might want to create a separate collection for this)
      await _storeResetToken(user.userId, resetToken);

      // Send password reset email
      final emailSent = await EmailService.sendPasswordResetEmail(user.email, resetToken);

      if (emailSent) {
        debugPrint('✅ Password reset email sent to ${user.email}');
        return true;
      } else {
        debugPrint('❌ Failed to send password reset email');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Password reset request error: $e');
      return false;
    }
  }

  /// Store reset token in database
  static Future<void> _storeResetToken(String userId, String token) async {
    try {
      if (MongoDataBase.isConnected) {
        final collection = MongoDataBase.db!.collection('password_reset_tokens');
        
        // Remove any existing tokens for this user
        await collection.deleteMany({'user_id': userId});
        
        // Store new token
        await collection.insertOne({
          'user_id': userId,
          'token': token,
          'created_at': DateTime.now().toIso8601String(),
          'expires_at': DateTime.now().add(Duration(hours: _tokenExpirationHours)).toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('❌ Error storing reset token: $e');
    }
  }

  /// Verify reset token
  static Future<User?> verifyResetToken(String token) async {
    try {
      // Verify JWT token
      final payload = _verifyJWTToken(token);
      if (payload == null) {
        return null;
      }

      final userId = payload['sub'] as String;
      final email = payload['email'] as String;

      // Get user from database
      final user = await MongoDataBase.getUserByUserId(userId);
      if (user == null || user.email != email) {
        return null;
      }

      // Check if user is active
      if (user.status != 'active') {
        return null;
      }

      return user;
    } catch (e) {
      debugPrint('❌ Token verification error: $e');
      return null;
    }
  }

  /// Reset password with token
  static Future<bool> resetPassword(String token, String newPassword) async {
    try {
      // Verify token and get user
      final user = await verifyResetToken(token);
      if (user == null) {
        throw Exception('Invalid or expired reset token');
      }

      // Validate new password
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters long');
      }

      // Update password in database
      try {
        await MongoDataBase.updateUser(user.userId, {
          'password': newPassword,
        });
        
        // Remove used token
        await _removeResetToken(user.userId);
        debugPrint('✅ Password reset successful for user: ${user.userId}');
        return true;
      } catch (e) {
        debugPrint('❌ Failed to update password: $e');
        throw Exception('Failed to update password');
      }
    } catch (e) {
      debugPrint('❌ Password reset error: $e');
      return false;
    }
  }

  /// Remove reset token from database
  static Future<void> _removeResetToken(String userId) async {
    try {
      if (MongoDataBase.isConnected) {
        final collection = MongoDataBase.db!.collection('password_reset_tokens');
        await collection.deleteMany({'user_id': userId});
      }
    } catch (e) {
      debugPrint('❌ Error removing reset token: $e');
    }
  }

  /// Clean up expired tokens (should be called periodically)
  static Future<void> cleanupExpiredTokens() async {
    try {
      if (MongoDataBase.isConnected) {
        final collection = MongoDataBase.db!.collection('password_reset_tokens');
        final now = DateTime.now();
        
        await collection.deleteMany({
          'expires_at': {'\$lt': now.toIso8601String()}
        });
        
        debugPrint('✅ Cleaned up expired password reset tokens');
      }
    } catch (e) {
      debugPrint('❌ Error cleaning up expired tokens: $e');
    }
  }

  /// Store token locally for mobile app
  static Future<void> storeTokenLocally(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password_reset_token', token);
      await prefs.setString('password_reset_token_timestamp', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Error storing token locally: $e');
    }
  }

  /// Get stored token from local storage
  static Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('password_reset_token');
      final timestamp = prefs.getString('password_reset_token_timestamp');
      
      if (token != null && timestamp != null) {
        final tokenTime = DateTime.parse(timestamp);
        final now = DateTime.now();
        
        // Check if token is still valid (within 1 hour)
        if (now.difference(tokenTime).inHours < _tokenExpirationHours) {
          return token;
        } else {
          // Remove expired token
          await prefs.remove('password_reset_token');
          await prefs.remove('password_reset_token_timestamp');
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error getting stored token: $e');
      return null;
    }
  }

  /// Clear stored token
  static Future<void> clearStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('password_reset_token');
      await prefs.remove('password_reset_token_timestamp');
    } catch (e) {
      debugPrint('❌ Error clearing stored token: $e');
    }
  }
} 