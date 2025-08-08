import 'package:flutter/foundation.dart';

// Import dart:io for non-web platforms
// ignore: unused_import
import 'dart:io' if (dart.library.html) 'dart:html';

// Import our web file stub
import 'web_file_stub.dart' if (dart.library.io) 'dart:io' as io;

/// A platform-agnostic file utility class that works on both web and non-web platforms
class FileUtils {
  /// Create a file instance
  static dynamic createFile(String path) {
    if (kIsWeb) {
      // For web, return a stub implementation
      return WebFile(path);
    } else {
      // For non-web platforms, return a real File
      return io.File(path);
    }
  }
  
  /// Check if a file exists
  static Future<bool> fileExists(String path) async {
    if (kIsWeb) {
      // For web, we'll just check if it's a web path
      return path.startsWith('web_');
    } else {
      // For non-web platforms, use the real File API
      final file = io.File(path);
      return await file.exists();
    }
  }
  
  /// Write bytes to a file
  static Future<void> writeBytes(String path, List<int> bytes) async {
    if (kIsWeb) {
      // For web, we'll just log it
      print('Web platform: Would write ${bytes.length} bytes to $path');
    } else {
      // For non-web platforms, use the real File API
      final file = io.File(path);
      await file.writeAsBytes(bytes);
    }
  }
  
  /// Delete a file
  static Future<bool> deleteFile(String path) async {
    if (kIsWeb) {
      // For web, we'll just log it
      print('Web platform: Would delete file at $path');
      return true;
    } else {
      // For non-web platforms, use the real File API
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
      // For web, return mock stats
      return {
        'path': path,
        'size': 1024, // Mock size
        'modified': DateTime.now(),
        'exists': path.startsWith('web_'),
        'isWeb': true,
      };
    } else {
      // For non-web platforms, use the real File API
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