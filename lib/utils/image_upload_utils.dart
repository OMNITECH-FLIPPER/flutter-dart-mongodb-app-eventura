import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class ImageUploadUtils {
  static const int maxFileSizeBytes = 1024 * 1024 * 1024; // 1GB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'];
  static const List<String> allowedMimeTypes = [
    'image/jpeg',
    'image/jpg', 
    'image/png',
    'image/webp',
    'image/gif',
    'image/bmp'
  ];

  /// Request camera and storage permissions
  static Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Take photo with camera
  static Future<File?> takePhotoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error taking photo with camera: $e');
      return null;
    }
  }

  /// Validate image file
  static String? validateImageFile(File file) {
    // Check file size
    final int fileSize = file.lengthSync();
    if (fileSize > maxFileSizeBytes) {
      return 'File size exceeds 1GB limit. Current size: ${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
    }

    // Check file extension
    final String extension = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return 'Unsupported file format. Allowed formats: ${allowedExtensions.join(', ')}';
    }

    return null; // No error
  }

  /// Compress image if needed
  static Future<Uint8List> compressImageIfNeeded(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final img.Image? image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // If image is already small enough, return as is
      if (bytes.length < 1024 * 1024) { // Less than 1MB
        return bytes;
      }

      // Calculate new dimensions while maintaining aspect ratio
      int newWidth = image.width;
      int newHeight = image.height;
      
      if (image.width > 1920 || image.height > 1080) {
        if (image.width > image.height) {
          newWidth = 1920;
          newHeight = (image.height * 1920 / image.width).round();
        } else {
          newHeight = 1080;
          newWidth = (image.width * 1080 / image.height).round();
        }
      }

      // Resize image
      final img.Image resized = img.copyResize(image, width: newWidth, height: newHeight);
      
      // Encode as JPEG with quality 85
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // Return original bytes if compression fails
      return await file.readAsBytes();
    }
  }

  /// Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }
} 