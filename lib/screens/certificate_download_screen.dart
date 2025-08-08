import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../config.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../services/database_service.dart';
import '../utils/certificate_utils.dart';

class CertificateDownloadScreen extends StatefulWidget {
  final User currentUser;
  
  const CertificateDownloadScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CertificateDownloadScreen> createState() => _CertificateDownloadScreenState();
}

class _CertificateDownloadScreenState extends State<CertificateDownloadScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<EventRegistration> _registrations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registrations = await _dbService.getRegistrationsByUser(widget.currentUser.userId);
      setState(() {
        _registrations = registrations.where((r) => r.isAttended).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load registrations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndDownloadCertificate(EventRegistration registration) async {
    try {
      // Get event details
      final event = await _dbService.getEventById(registration.eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      // Generate certificate
      final certificateBytes = await CertificateUtils.generateCertificate(registration, event);
      
      // Convert to base64 for upload
      final base64Certificate = base64Encode(certificateBytes);
      final fileName = 'certificate_${registration.userId}_${registration.eventId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Upload certificate via API
      final certificateUrl = await DatabaseService.uploadCertificate(
        base64Certificate,
        fileName,
        registration.userId,
        registration.eventId,
      );

      if (certificateUrl != null) {
        // Update registration with certificate URL
        await _dbService.confirmAttendance(
          registration.id!,
          true,
          certificateUrl: certificateUrl,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Certificate generated and uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRegistrations(); // Refresh the list
        }
      } else {
        throw Exception('Failed to upload certificate');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadCertificateFromDevice(EventRegistration registration) async {
    try {
      // Pick certificate file from device
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploading certificate...'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Convert file to base64
        final bytes = file.bytes;
        if (bytes == null) {
          throw Exception('Could not read file bytes');
        }

        final base64Certificate = base64Encode(bytes);
        final fileName = file.name;
        // final fileType = file.extension ?? 'pdf';
        
        // Upload certificate via API
        final certificateUrl = await DatabaseService.uploadCertificate(
          base64Certificate,
          fileName,
          registration.userId,
          registration.eventId,
        );

        if (certificateUrl != null) {
          // Update registration with certificate URL
          await _dbService.confirmAttendance(
            registration.id!,
            true,
            certificateUrl: certificateUrl,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Certificate uploaded successfully: $fileName'),
                backgroundColor: Colors.green,
              ),
            );
            _loadRegistrations(); // Refresh the list
          }
        } else {
          throw Exception('Failed to upload certificate');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadExistingCertificate(EventRegistration registration) async {
    try {
      // Get event details
      final event = await _dbService.getEventById(registration.eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      if (kIsWeb) {
        // On web, show a message about certificate generation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate generated successfully! On web platform, certificates are stored in memory.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // On mobile/desktop, check if certificate exists
        final exists = await CertificateUtils.certificateExists(registration.certificateUrl ?? '');
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Certificate downloaded: ${registration.certificateUrl}'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Generate new certificate if it doesn't exist
          await _generateAndDownloadCertificate(registration);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCertificatePreview(EventRegistration registration, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Certificate Preview - ${event.title}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: CertificateUtils.generateCertificatePreview(registration, event),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateAndDownloadCertificate(registration);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Config.primaryColor,
            ),
            child: const Text('Generate PDF', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Certificates'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegistrations,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRegistrations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primaryColor,
                          foregroundColor: Config.secondaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _registrations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No certificates available',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Complete events to generate certificates',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRegistrations,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _registrations.length,
                        itemBuilder: (context, index) {
                          final registration = _registrations[index];
                          return FutureBuilder<Event?>(
                            future: _dbService.getEventById(registration.eventId),
                            builder: (context, snapshot) {
                              final event = snapshot.data;
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Card(
                                  child: ListTile(
                                    leading: CircularProgressIndicator(),
                                    title: Text('Loading event...'),
                                  ),
                                );
                              }
                              
                              if (event == null) {
                                return const Card(
                                  child: ListTile(
                                    leading: Icon(Icons.error, color: Colors.red),
                                    title: Text('Event not found'),
                                  ),
                                );
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Config.primaryColor,
                                    child: const Icon(
                                      Icons.assignment,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Text(
                                    event.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Date: ${event.eventDate.toString().split(' ')[0]}'),
                                      Text('Location: ${event.location}'),
                                      Text('Attendance: ${registration.attendanceDate?.toString().split(' ')[0] ?? 'Not recorded'}'),
                                    ],
                                  ),
                                  trailing: registration.certificateUrl != null && registration.certificateUrl!.isNotEmpty
                                       ? Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             IconButton(
                                               icon: const Icon(Icons.download, color: Colors.green),
                                               onPressed: () => _downloadExistingCertificate(registration),
                                               tooltip: 'Download Certificate',
                                             ),
                                             IconButton(
                                               icon: const Icon(Icons.visibility, color: Colors.blue),
                                               onPressed: () => _showCertificatePreview(registration, event),
                                               tooltip: 'Preview Certificate',
                                             ),
                                           ],
                                         )
                                       : Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             IconButton(
                                               icon: const Icon(Icons.add, color: Config.primaryColor),
                                               onPressed: () => _generateAndDownloadCertificate(registration),
                                               tooltip: 'Generate Certificate',
                                             ),
                                             IconButton(
                                               icon: const Icon(Icons.upload_file, color: Config.primaryColor),
                                               onPressed: () => _uploadCertificateFromDevice(registration),
                                               tooltip: 'Upload from Device',
                                             ),
                                           ],
                                         ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}
