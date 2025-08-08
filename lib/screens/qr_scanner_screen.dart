import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import '../config.dart';
import '../utils/qr_code_utils.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class QRScannerScreen extends StatefulWidget {
  final User currentUser;
  final String? eventId; // Optional: if scanning for specific event
  
  const QRScannerScreen({
    super.key, 
    required this.currentUser, 
    this.eventId,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isScanning = true;
  bool _hasPermission = false;
  final String _lastScannedData = '';

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _requestCameraPermission();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() => _isScanning = false);
    
    try {
      // Check if it's a valid check-in QR code
      if (QRCodeUtils.isValidCheckInQR(qrData)) {
        await _handleCheckInQR(qrData);
      } else if (QRCodeUtils.isValidEventInfoQR(qrData)) {
        await _handleEventInfoQR(qrData);
      } else {
        _showErrorDialog('Invalid QR Code', 'This QR code is not recognized by the app.');
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to process QR code: $e');
    }
  }

  Future<void> _handleCheckInQR(String qrData) async {
    final data = QRCodeUtils.parseQRCodeData(qrData);
    if (data == null) {
      _showErrorDialog('Invalid QR Code', 'Could not parse QR code data.');
      return;
    }

    final String registrationId = data['registrationId'];
    final String userId = data['userId'];
    final String userName = data['userName'];
    final String eventTitle = data['eventTitle'];

    // Verify the user has permission to check in this registration
    if (widget.currentUser.role == Config.roleAdmin || 
        widget.currentUser.role == Config.roleOrganizer) {
      // Admin/Organizer can check in anyone
    } else if (widget.currentUser.userId != userId) {
      _showErrorDialog('Access Denied', 'You can only check in for your own registration.');
      return;
    }

    try {
      // Update registration status to attended using database service
      final databaseService = DatabaseService();
      final success = await databaseService.confirmAttendance(registrationId, true);
      
      if (success && mounted) {
        _showSuccessDialog(
          'Check-in Successful!',
          '$userName has been successfully checked in for "$eventTitle".',
        );
      } else if (mounted) {
        _showErrorDialog('Check-in Failed', 'Failed to update registration status.');
      }
    } catch (e) {
      _showErrorDialog('Check-in Failed', 'Failed to update registration: $e');
    }
  }

  Future<void> _handleEventInfoQR(String qrData) async {
    final data = QRCodeUtils.parseQRCodeData(qrData);
    if (data == null) {
      _showErrorDialog('Invalid QR Code', 'Could not parse QR code data.');
      return;
    }

    final String eventTitle = data['eventTitle'];
    final String eventDate = data['eventDate'];
    final String location = data['location'];
    final String organizerName = data['organizerName'];
    final int availableSlots = data['availableSlots'];
    final int totalSlots = data['totalSlots'];

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Event Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: $eventTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Date: ${DateTime.parse(eventDate).toLocal().toString().split(' ')[0]}'),
              Text('Location: $location'),
              Text('Organizer: $organizerName'),
              Text('Available Slots: $availableSlots / $totalSlots'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: Colors.green.shade50,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isScanning = true);
            },
            child: const Text('Continue Scanning'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: Colors.red.shade50,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _isScanning = true);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog() {
    final TextEditingController qrDataController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual QR Code Input'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter QR code data manually:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: qrDataController,
              decoration: const InputDecoration(
                labelText: 'QR Code Data',
                border: OutlineInputBorder(),
                hintText: '{"type":"event_checkin",...}',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qrData = qrDataController.text.trim();
              if (qrData.isNotEmpty) {
                Navigator.of(context).pop();
                _processQRCode(qrData);
              }
            },
            child: const Text('Process'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show web-compatible UI
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Scanner'),
          backgroundColor: Config.primaryColor,
          foregroundColor: Config.secondaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.qr_code_scanner,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'QR Scanner Not Available on Web',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Please use the mobile app for QR scanning functionality.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  // Get real registration data for testing
                  try {
                    final dbService = DatabaseService();
                    final registrations = await dbService.getRegistrationsByEvent('688048fd31629f1c4c000000');
                    if (registrations.isNotEmpty) {
                      final registration = registrations.first;
                      final qrData = {
                        'type': 'event_checkin',
                        'eventId': registration.eventId,
                        'eventTitle': 'Flutter Workshop',
                        'registrationId': registration.id,
                        'userId': registration.userId,
                        'userName': registration.userName,
                        'timestamp': DateTime.now().millisecondsSinceEpoch
                      };
                      _processQRCode(jsonEncode(qrData));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No registrations found for testing'), backgroundColor: Colors.red),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error loading test data: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Config.primaryColor,
                  foregroundColor: Config.secondaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Simulate QR Scan (Test)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _showManualInputDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: const Text('Manual QR Input'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Show mobile QR scanner UI
    if (!_hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Scanner'),
          backgroundColor: Config.primaryColor,
          foregroundColor: Config.secondaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Camera Permission Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'This app needs camera access to scan QR codes.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _requestCameraPermission,
                child: const Text('Grant Permission'),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile QR scanner implementation would go here
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() => _isScanning = !_isScanning);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Config.primaryColor,
            ),
            const SizedBox(height: 20),
            const Text(
              'QR Scanner Ready',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _isScanning ? 'Scanning QR Code...' : 'Paused',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Simulate QR scan for testing with proper JSON format
                _processQRCode('{"type":"event_checkin","eventId":"688048fd31629e1c4c000000","eventTitle":"Flutter Workshop","registrationId":"test-reg-123","userId":"USER-001","userName":"Uma User","timestamp":1733123456789}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Config.primaryColor,
                foregroundColor: Config.secondaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Test QR Scan'),
            ),
          ],
        ),
      ),
    );
  }
} 