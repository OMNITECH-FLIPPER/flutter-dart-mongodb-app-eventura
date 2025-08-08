import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../models/user.dart';
import '../mongodb.dart';
import '../config.dart';
import '../utils/qr_code_utils.dart';
import '../utils/email_notification_utils.dart';
import 'qr_scanner_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class OrganizerEventRegisteredUsersScreen extends StatefulWidget {
  final Event event;
  const OrganizerEventRegisteredUsersScreen({super.key, required this.event});

  @override
  State<OrganizerEventRegisteredUsersScreen> createState() => _OrganizerEventRegisteredUsersScreenState();
}

class _OrganizerEventRegisteredUsersScreenState extends State<OrganizerEventRegisteredUsersScreen> {
  List<EventRegistration> _registrations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final regs = await MongoDataBase.getRegistrationsByEvent(widget.event.id!);
      setState(() {
        _registrations = regs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _confirmAttendance(EventRegistration reg, bool attended) async {
    setState(() => _isLoading = true);
    try {
      await MongoDataBase.confirmAttendance(reg.id!, attended);
      
      // Send attendance confirmation notification
      final notificationSuccess = await EmailNotificationUtils.sendAttendanceConfirmationNotification(reg, widget.event, attended);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${attended ? 'Attendance confirmed!' : 'Marked as missed.'} ${EmailNotificationUtils.getNotificationStatus(notificationSuccess, "Attendance confirmation")}'),
            backgroundColor: notificationSuccess ? Config.primaryColor : Colors.orange,
          ),
        );
        _loadRegistrations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registered Users'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'QR Scanner',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QRScannerScreen(
                    currentUser: User(
                      userId: 'organizer',
                      password: '',
                      role: Config.roleOrganizer,
                      name: 'Organizer',
                      age: 0,
                      email: '',
                      address: '',
                      status: 'active',
                    ),
                    eventId: widget.event.id,
                  ),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRegistrations),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _registrations.isEmpty
                  ? const Center(child: Text('No users registered.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _registrations.length,
                      itemBuilder: (context, index) {
                        final reg = _registrations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: const Icon(Icons.person, color: Config.primaryColor, size: 40),
                            title: Text(reg.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Status: ${reg.status}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // QR Code Generation Button
                                IconButton(
                                  icon: const Icon(Icons.qr_code, color: Colors.green),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('QR Code for Check-in'),
                                        content: QRCodeUtils.generateEventCheckInQR(widget.event, reg),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  tooltip: 'Generate QR Code',
                                ),
                                if (reg.isConfirmed && reg.isAttended)
                                  IconButton(
                                    icon: const Icon(Icons.upload, color: Colors.blue),
                                    onPressed: () async {
                                      // Pick file from device
                                      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'png']);
                                      if (result != null && result.files.single.path != null) {
                                        final file = File(result.files.single.path!);
                                        // Upload to backend and get URL
                                        final url = await MongoDataBase.uploadCertificateFile(file, reg.id!);
                                        await MongoDataBase.updateRegistrationCertificate(reg.id!, url);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Certificate uploaded successfully!'), backgroundColor: Colors.green),
                                        );
                                        _loadRegistrations();
                                      }
                                    },
                                    tooltip: 'Upload Certificate',
                                  )
                                else if (!reg.isConfirmed)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle, color: Colors.green),
                                        onPressed: () => _confirmAttendance(reg, true),
                                        tooltip: 'Mark as Attended',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () => _confirmAttendance(reg, false),
                                        tooltip: 'Mark as Missed',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 