import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/event_registration.dart';
import 'create_event_screen.dart';

class OrganizerEventsScreen extends StatefulWidget {
  final User currentUser;

  const OrganizerEventsScreen({super.key, required this.currentUser});

  @override
  State<OrganizerEventsScreen> createState() => _OrganizerEventsScreenState();
}

class _OrganizerEventsScreenState extends State<OrganizerEventsScreen> with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  List<Event> _myEvents = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allEvents = await _dbService.getAllEvents();
      final myEvents = allEvents.where((event) => event.organizerId == widget.currentUser.userId).toList();
      
      setState(() {
        _myEvents = myEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showEventRegistrations(Event event) async {
    try {
      final registrations = await _dbService.getRegistrationsByEvent(event.id ?? '');
      
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Registrations - ${event.title}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: registrations.isEmpty
                ? const Center(
                    child: Text('No registrations yet'),
                  )
                : ListView.builder(
                    itemCount: registrations.length,
                    itemBuilder: (context, index) {
                      final registration = registrations[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: registration.attended ? Colors.green : Colors.blue,
                            child: Icon(
                              registration.attended ? Icons.check : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text('User ID: ${registration.userId}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${registration.status}'),
                              Text('Registered: ${registration.registrationDate.day}/${registration.registrationDate.month}/${registration.registrationDate.year}'),
                              if (registration.attended)
                                const Text('✅ Attendance Confirmed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: !registration.attended && event.eventDate.isBefore(DateTime.now())
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => _confirmAttendance(registration, true),
                                      tooltip: 'Confirm Attendance',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _confirmAttendance(registration, false),
                                      tooltip: 'Mark as Absent',
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading registrations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmAttendance(EventRegistration registration, bool attended) async {
    try {
      final success = await _dbService.confirmAttendance(
        registration.id ?? '',
        attended,
        certificateUrl: attended ? 'certificate_${registration.id ?? ''}.pdf' : null,
      );

      if (success) {
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(attended ? 'Attendance confirmed' : 'Marked as absent'),
              backgroundColor: Colors.green,
            ),
          );
          _loadMyEvents(); // Refresh events
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update attendance'),
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
    }
  }

  Future<bool> _checkEventRegistrations(Event event) async {
    try {
      final registrations = await _dbService.getRegistrationsByEvent(event.id ?? '');
      return registrations.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _uploadCertificate(Event event) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Certificate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the certificate URL or upload a file:'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Certificate URL',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/certificate.pdf',
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value),
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
              // Simulate file upload
              Navigator.of(context).pop('https://eventura.com/certificates/${event.id}.pdf');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Config.primaryColor,
              foregroundColor: Config.secondaryColor,
            ),
            child: const Text('Upload File'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        // Update event with certificate URL
        final success = await _dbService.updateEvent(
          event.id ?? '',
          {'certificateUrl': result},
          editorUserId: widget.currentUser.userId,
          isAdmin: false,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Certificate uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadMyEvents();
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
  }

  Future<void> _generateCertificate(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Certificates'),
        content: Text('Generate certificates for all participants of "${event.title}"?'),
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
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Simulate certificate generation process
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Certificates generated for ${event.title}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error generating certificates: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEventCard(Event event) {
    final isPastEvent = event.eventDate.isBefore(DateTime.now());
    // Check registrations asynchronously
    return FutureBuilder<bool>(
      future: _checkEventRegistrations(event),
      builder: (context, snapshot) {
        final hasRegistrations = snapshot.data ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: event.status == 'active' ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.status,
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
            Text(
              event.description,
              style: TextStyle(color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Config.primaryColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Config.primaryColor),
                const SizedBox(width: 4),
                Text(
                  '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: Config.primaryColor),
                const SizedBox(width: 4),
                Text(
                  '${event.availableSlots}/${event.totalSlots} slots',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showEventRegistrations(event),
                    icon: const Icon(Icons.people),
                    label: const Text('View Registrations'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Config.primaryColor,
                      foregroundColor: Config.secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (isPastEvent) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _generateCertificate(event),
                      icon: const Icon(Icons.description),
                      label: const Text('Generate Cert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _uploadCertificate(event),
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Cert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyEvents,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Config.secondaryColor,
          labelColor: Config.secondaryColor,
          unselectedLabelColor: Config.secondaryColor.withOpacity(0.7),
          tabs: const [
            Tab(text: 'My Events'),
            Tab(text: 'Create Event'),
          ],
        ),
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
                        onPressed: _loadMyEvents,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primaryColor,
                          foregroundColor: Config.secondaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // My Events Tab
                    RefreshIndicator(
                      onRefresh: _loadMyEvents,
                      child: _myEvents.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_note, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No events created yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Create your first event!',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _myEvents.length,
                              itemBuilder: (context, index) {
                                final event = _myEvents[index];
                                return _buildEventCard(event);
                              },
                            ),
                    ),
                    // Create Event Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 50),
                          Icon(Icons.add_circle, size: 64, color: Config.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Create New Event',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Config.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Click the + button below to create a new event',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CreateEventScreen(organizer: widget.currentUser),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Create Event'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Config.primaryColor,
                              foregroundColor: Config.secondaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateEventScreen(organizer: widget.currentUser),
            ),
          );
        },
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
} 