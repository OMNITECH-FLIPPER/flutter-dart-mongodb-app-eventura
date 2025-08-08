import 'package:flutter/foundation.dart';

// Conditional import: use real dart:io on IO platforms, and stub on web
import 'dart:io' if (dart.library.html) 'io_stub.dart' as io;

/// A platform-agnostic file utility class that works on both web and non-web platforms
class FileUtils {
  /// Create a file instance
  static dynamic createFile(String path) {
    return io.File(path);
  }
  
  /// Check if a file exists
  static Future<bool> fileExists(String path) async {
    if (kIsWeb) {
      // Provide a conservative default for web
      return false;
    } else {
      final file = io.File(path);
      return await file.exists();
    }
  }
  
  /// Write bytes to a file
  static Future<void> writeBytes(String path, List<int> bytes) async {
    if (kIsWeb) {
      // No-op on web
      return;
    } else {
      final file = io.File(path);
      await file.writeAsBytes(bytes);
    }
  }
  
  /// Delete a file
  static Future<bool> deleteFile(String path) async {
    if (kIsWeb) {
      // No-op on web
      return true;
    } else {
      final file = io.File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    }
  }
  
  /// Get file stats
  static Future<Map<String, dynamic>?> getFileStats(String path) async {
    if (kIsWeb) {
      return {
        'path': path,
        'size': 0,
        'modified': DateTime.now(),
        'exists': false,
        'isWeb': true,
      };
    } else {
      final file = io.File(path);
      if (await file.exists()) {
        final stat = await file.stat();
        return {
          'path': path,
          'size': stat.size,
          'modified': stat.modified,
          'exists': true,
          'isWeb': false,
        };
      }
      return null;
    }
  }
}