import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/event_registration.dart';
import '../utils/email_notification_utils.dart';

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final User currentUser;
  final EventRegistration? registration;

  const EventDetailScreen({
    super.key,
    required this.event,
    required this.currentUser,
    this.registration,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  Future<void> _registerForEvent() async {
        setState(() {
      _isLoading = true;
        });

    try {
      final registration = EventRegistration(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.currentUser.userId,
        userName: widget.currentUser.name,
        userEmail: widget.currentUser.email,
        eventId: widget.event.id ?? '',
        eventTitle: widget.event.title,
        registrationDate: DateTime.now(),
        status: 'registered',
        isConfirmed: false,
        attended: false,
        certificateUrl: null,
      );

      final success = await _dbService.registerForEvent(registration);
      if (success) {
        // Send registration confirmation notification
        final notificationSuccess = await EmailNotificationUtils.sendRegistrationConfirmationNotification(registration, widget.event);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully registered for ${widget.event.title}! ${EmailNotificationUtils.getNotificationStatus(notificationSuccess, "Registration confirmation")}'),
              backgroundColor: notificationSuccess ? Colors.green : Colors.orange,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate registration
        }
      } else {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to register for event'),
              backgroundColor: Colors.red,
          ),
        );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadCertificate() async {
    if (widget.registration?.certificateUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificate not available yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Generate certificate content
      final certificateContent = _generateCertificateContent();
      
      // Show download dialog
      final shouldDownload = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Download Certificate'),
          content: const Text('Your certificate is ready for download. Would you like to download it now?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Config.primaryColor,
                foregroundColor: Config.secondaryColor,
              ),
              child: const Text('Download'),
            ),
          ],
        ),
      );

      if (shouldDownload == true) {
        // Simulate download process
        await Future.delayed(const Duration(seconds: 2));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download certificate: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _generateCertificateContent() {
    final now = DateTime.now();
    final certificateNumber = 'CERT-${widget.event.id}-${widget.currentUser.userId}-${now.millisecondsSinceEpoch}';
    
    return '''
CERTIFICATE OF PARTICIPATION

This is to certify that

${widget.currentUser.name}
(${widget.currentUser.userId})

has successfully participated in

${widget.event.title}

Event Details:
- Date: ${DateFormat('MMMM dd, yyyy').format(widget.event.eventDate)}
- Location: ${widget.event.location}
- Organizer: ${widget.event.organizerName}

Certificate Number: $certificateNumber
Issued on: ${DateFormat('MMMM dd, yyyy').format(now)}

This certificate is awarded in recognition of active participation and successful completion of the event requirements.

---
Generated by Eventura App
    ''';
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Config.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    if (widget.registration == null) {
      // Not registered
      if (widget.event.availableSlots <= 0) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Event is Full',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        );
      }

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _registerForEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: Config.primaryColor,
            foregroundColor: Config.secondaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Register for Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      );
    } else {
      // Registered
      if (widget.registration!.attended) {
        // Attended - show certificate download
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Attendance Confirmed',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadCertificate,
                icon: const Icon(Icons.download),
                label: const Text('Download Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Config.primaryColor,
                  foregroundColor: Config.secondaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        // Registered but not attended
        if (widget.event.eventDate.isBefore(DateTime.now())) {
          // Event has passed
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Event Passed - Attendance Pending',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Event hasn't happened yet
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.how_to_reg, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registered - Event Pending',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            if (widget.event.imageUrl.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                      decoration: BoxDecoration(
                          color: Config.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                        child: Icon(
                          Icons.event,
                          size: 64,
                          color: Config.primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Config.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event,
                  size: 64,
                  color: Config.primaryColor,
                ),
            ),
            const SizedBox(height: 16),
            ],

            // Event Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.event.title,
                    style: const TextStyle(
                      fontSize: 24,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.event.status == 'active' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.event.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Event Description
            Text(
              widget.event.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Event Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Config.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_on,
                      'Location',
                      widget.event.location,
                    ),
                    _buildInfoRow(
                      Icons.calendar_today,
                      'Date',
                      '${widget.event.eventDate.day}/${widget.event.eventDate.month}/${widget.event.eventDate.year}',
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      'Time',
                      '${widget.event.eventDate.hour.toString().padLeft(2, '0')}:${widget.event.eventDate.minute.toString().padLeft(2, '0')}',
                    ),
                    _buildInfoRow(
                      Icons.people,
                      'Capacity',
                      '${widget.event.availableSlots}/${widget.event.totalSlots} slots available',
                    ),
                    _buildInfoRow(
                      Icons.person,
                      'Organizer',
                      widget.event.organizerName,
                    ),
                  ],
                          ),
                        ),
            ),
            const SizedBox(height: 24),

            // Registration Status Card
            if (widget.registration != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Registration Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Config.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        Icons.how_to_reg,
                        'Status',
                        widget.registration!.status,
                      ),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Registration Date',
                        '${widget.registration!.registrationDate.day}/${widget.registration!.registrationDate.month}/${widget.registration!.registrationDate.year}',
                      ),
                      if (widget.registration!.attended) ...[
                        _buildInfoRow(
                          Icons.check_circle,
                          'Attendance',
                          'Confirmed',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Action Button
            _buildActionButton(),
          ],
        ),
      ),
    );
  }
} 