import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../mongodb.dart';

class QRCodeUtils {
  /// Generate QR code data for event check-in
  static String generateEventCheckInData(Event event, EventRegistration registration) {
    final Map<String, dynamic> data = {
      'type': 'event_checkin',
      'eventId': event.id,
      'eventTitle': event.title,
      'registrationId': registration.id,
      'userId': registration.userId,
      'userName': registration.userName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    return jsonEncode(data);
  }

  /// Generate QR code data for event info
  static String generateEventInfoData(Event event) {
    final Map<String, dynamic> data = {
      'type': 'event_info',
      'eventId': event.id,
      'eventTitle': event.title,
      'eventDate': event.eventDate.toIso8601String(),
      'location': event.location,
      'organizerName': event.organizerName,
      'availableSlots': event.availableSlots,
      'totalSlots': event.totalSlots,
    };
    return jsonEncode(data);
  }

  /// Parse QR code data
  static Map<String, dynamic>? parseQRCodeData(String qrData) {
    try {
      return jsonDecode(qrData) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing QR code data: $e');
      return null;
    }
  }

  /// Validate QR code data for check-in
  static bool isValidCheckInQR(String qrData) {
    final data = parseQRCodeData(qrData);
    if (data == null) return false;
    
    return data['type'] == 'event_checkin' &&
           data['eventId'] != null &&
           data['registrationId'] != null &&
           data['userId'] != null;
  }

  /// Validate QR code data for event info
  static bool isValidEventInfoQR(String qrData) {
    final data = parseQRCodeData(qrData);
    if (data == null) return false;
    
    return data['type'] == 'event_info' &&
           data['eventId'] != null &&
           data['eventTitle'] != null;
  }

  /// Get QR code version based on data length
  static int getQRVersion(String data) {
    final int dataLength = data.length;
    if (dataLength <= 25) return 1;
    if (dataLength <= 47) return 2;
    if (dataLength <= 77) return 3;
    if (dataLength <= 114) return 4;
    if (dataLength <= 154) return 5;
    if (dataLength <= 195) return 6;
    if (dataLength <= 224) return 7;
    if (dataLength <= 279) return 8;
    if (dataLength <= 335) return 9;
    return 10; // Default for larger data
  }

  /// Generate QR code widget for event check-in
  static Widget generateEventCheckInQR(Event event, EventRegistration reg, {double size = 200}) {
    final qrData = jsonEncode({
      'type': 'event_checkin',
      'eventId': event.id,
      'eventTitle': event.title,
      'registrationId': reg.id,
      'userId': reg.userId,
      'userName': reg.userName,
      'timestamp': DateTime.now().toIso8601String(),
      'unique': '${event.id}_${reg.id}_${reg.userId}',
    });
    MongoDataBase.saveQRCode(jsonDecode(qrData));
    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
    );
  }

  /// Generate QR code widget for event info
  static Widget generateEventInfoQR(Event event, {double size = 200}) {
    final String qrData = generateEventInfoData(event);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: qrData,
            version: getQRVersion(qrData),
            size: size,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Event QR Code',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Scan for event details',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 