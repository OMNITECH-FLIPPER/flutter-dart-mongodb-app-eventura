import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import '../config.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../services/database_service.dart';

class OrganizerCertificateUploadScreen extends StatefulWidget {
  final User organizer;
  final Event event;
  
  const OrganizerCertificateUploadScreen({
    super.key,
    required this.organizer,
    required this.event,
  });

  @override
  State<OrganizerCertificateUploadScreen> createState() => _OrganizerCertificateUploadScreenState();
}

class _OrganizerCertificateUploadScreenState extends State<OrganizerCertificateUploadScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<EventRegistration> _registrations = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, PlatformFile?> _selectedFiles = {};
  final Map<String, bool> _uploadingStatus = {};

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
      final registrations = await _dbService.getRegistrationsByEvent(widget.event.id ?? '');
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

  Future<void> _pickCertificateForRegistration(EventRegistration registration) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles[registration.id!] = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadCertificateForRegistration(EventRegistration registration) async {
    final file = _selectedFiles[registration.id!];
    if (file == null) return;

    setState(() {
      _uploadingStatus[registration.id!] = true;
    });

    try {
      // Convert file to base64
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception('Could not read file bytes');
      }

      final base64Certificate = base64Encode(bytes);
      final fileName = file.name;
      
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
              content: Text('Certificate uploaded for ${registration.userName}'),
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
            content: Text('Error uploading certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _uploadingStatus[registration.id!] = false;
        _selectedFiles.remove(registration.id!);
      });
    }
  }

  Future<void> _uploadAllCertificates() async {
    final registrationsWithFiles = _registrations.where((r) => _selectedFiles.containsKey(r.id)).toList();
    
    if (registrationsWithFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select files to upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Uploading Certificates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing ${registrationsWithFiles.length} certificates...'),
          ],
        ),
      ),
    );

    int successCount = 0;
    for (final registration in registrationsWithFiles) {
      try {
        await _uploadCertificateForRegistration(registration);
        successCount++;
      } catch (e) {
        debugPrint('Failed to upload certificate for ${registration.userName}: $e');
      }
    }
    
    if (mounted) {
      Navigator.of(context).pop(); // Close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded $successCount out of ${registrationsWithFiles.length} certificates'),
          backgroundColor: successCount > 0 ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Certificates - ${widget.event.title}'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          if (_selectedFiles.isNotEmpty)
            TextButton(
              onPressed: _uploadAllCertificates,
              child: const Text(
                'Upload All',
                style: TextStyle(color: Colors.white),
              ),
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
                            'No attended registrations found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Participants must attend the event to upload certificates',
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
                          final selectedFile = _selectedFiles[registration.id];
                          final isUploading = _uploadingStatus[registration.id] ?? false;
                          final hasCertificate = registration.certificateUrl != null && 
                                               registration.certificateUrl!.isNotEmpty;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasCertificate ? Colors.green : Config.primaryColor,
                                child: Icon(
                                  hasCertificate ? Icons.check : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                registration.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Email: ${registration.userEmail}'),
                                  Text('Attendance: ${registration.attendanceDate?.toString().split(' ')[0] ?? 'Not recorded'}'),
                                  if (selectedFile != null)
                                    Text(
                                      'Selected: ${selectedFile.name}',
                                      style: TextStyle(
                                        color: Config.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (hasCertificate)
                                    Text(
                                      'Certificate: ${registration.certificateUrl!.split('/').last}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: hasCertificate
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                                  : isUploading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : selectedFile != null
                                          ? IconButton(
                                              icon: const Icon(Icons.upload, color: Config.primaryColor),
                                              onPressed: () => _uploadCertificateForRegistration(registration),
                                              tooltip: 'Upload Certificate',
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.upload_file, color: Config.primaryColor),
                                              onPressed: () => _pickCertificateForRegistration(registration),
                                              tooltip: 'Select Certificate',
                                            ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
} 