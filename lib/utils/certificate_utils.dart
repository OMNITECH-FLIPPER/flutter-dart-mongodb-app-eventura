import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/event.dart';
import '../models/event_registration.dart';

// Import dart:io only for non-web platforms
import 'file_utils.dart';

class CertificateUtils {
  /// Generate a certificate of attendance
  static Future<Uint8List> generateCertificate(
    EventRegistration registration,
    Event event,
  ) async {
    final pdf = pw.Document();
    
    // Add certificate page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue, width: 3),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Text(
                  'CERTIFICATE OF ATTENDANCE',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // Main content
              pw.Text(
                'This is to certify that',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.grey700,
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Text(
                registration.userName,
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
                textAlign: pw.TextAlign.center,
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Text(
                'has successfully attended the event',
                style: pw.TextStyle(
                  fontSize: 18,
                  color: PdfColors.grey700,
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  event.title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Event details
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    _buildDetailRow('Event Date:', event.eventDate.toString().split(' ')[0]),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Location:', event.location),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Organizer:', event.organizerName),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Registration Date:', registration.registrationDate.toString().split(' ')[0]),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 40),
              
              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Organizer signature
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 120,
                        height: 2,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Organizer Signature',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  
                  // Certificate ID
                  pw.Column(
                    children: [
                      pw.Text(
                        'Certificate ID:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'CERT-${registration.id}-${event.id}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  
                  // Date
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 120,
                        height: 2,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Date',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Disclaimer
              pw.Text(
                'This certificate is automatically generated and serves as proof of attendance.',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                  fontStyle: pw.FontStyle.italic,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    
    return await pdf.save();
  }
  
  /// Build a detail row for the certificate
  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Save certificate to file
  static Future<String> saveCertificate(
    Uint8List certificateBytes,
    String userId,
    String eventId,
  ) async {
    try {
      if (kIsWeb) {
        // On web platform, we'll store the certificate data in memory or localStorage
        debugPrint('🌐 Web platform - certificate data generated (${certificateBytes.length} bytes)');
        // For web, we'll return a placeholder path since we can't save files directly
        final fileName = 'web_certificate_${userId}_${eventId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        
        // Here we could implement web storage using IndexedDB or localStorage
        // For now, we'll just return the filename
        return fileName;
      }
      
      // For mobile/desktop platforms
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'certificate_${userId}_${eventId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final filePath = '${directory.path}/$fileName';
        
        // Create file and write bytes using FileUtils
        await FileUtils.writeBytes(filePath, certificateBytes);
        
        debugPrint('Certificate saved to: $filePath');
        return filePath; // Return full path for non-web platforms
      } catch (e) {
        debugPrint('Error in file operations: $e');
        return 'certificate_${userId}_${eventId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }
    } catch (e) {
      debugPrint('Error saving certificate: $e');
      rethrow;
    }
  }
  
  /// Get certificate file size in human readable format
  static String getCertificateSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  /// Check if certificate exists for a registration
  static Future<bool> certificateExists(String certificateUrl) async {
    if (certificateUrl.isEmpty) return false;
    
    try {
      if (kIsWeb) {
        // On web platform, check if it's a web certificate
        return certificateUrl.startsWith('web_certificate_');
      }
      
      // For mobile/desktop platforms, use FileUtils
      return await FileUtils.fileExists(certificateUrl);
    } catch (e) {
      debugPrint('Error checking certificate existence: $e');
      return false;
    }
  }
  
  /// Delete certificate file
  static Future<bool> deleteCertificate(String certificateUrl) async {
    if (certificateUrl.isEmpty) return false;
    
    try {
      if (kIsWeb) {
        // File operations not available on web platform
        debugPrint('File operations not available on web platform');
        return false;
      }
      
      // For mobile/desktop platforms, use FileUtils
      return await FileUtils.deleteFile(certificateUrl);
    } catch (e) {
      debugPrint('Error deleting certificate: $e');
      return false;
    }
  }
  
  /// Get certificate file info
  static Future<Map<String, dynamic>?> getCertificateInfo(String certificateUrl) async {
    if (certificateUrl.isEmpty) return null;
    
    try {
      if (kIsWeb) {
        // On web platform, return mock info for web certificates
        if (certificateUrl.startsWith('web_certificate_')) {
          return {
            'path': certificateUrl,
            'size': 1024, // Mock size
            'sizeString': getCertificateSizeString(1024),
            'modified': DateTime.now(),
            'exists': true,
            'isWeb': true,
          };
        }
        return null;
      }
      
      // For mobile/desktop platforms, use FileUtils
      final stats = await FileUtils.getFileStats(certificateUrl);
      if (stats != null) {
        return {
          'path': certificateUrl,
          'size': stats['size'],
          'sizeString': getCertificateSizeString(stats['size']),
          'modified': stats['modified'],
          'exists': true,
          'isWeb': false,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting certificate info: $e');
      return null;
    }
  }
  
  /// Generate certificate preview (for UI display)
  static Widget generateCertificatePreview(
    EventRegistration registration,
    Event event,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue, width: 2),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'CERTIFICATE PREVIEW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'This certifies that',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            registration.userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'attended',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Date: ${event.eventDate.toString().split(' ')[0]}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Location: ${event.location}',
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