import 'package:flutter/material.dart';
import '../config.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../models/event_registration.dart';
import '../models/event.dart';
import 'certificate_download_screen.dart';

class UserAttendedEventsScreen extends StatefulWidget {
  final User currentUser;
  
  const UserAttendedEventsScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserAttendedEventsScreen> createState() => _UserAttendedEventsScreenState();
}

class _UserAttendedEventsScreenState extends State<UserAttendedEventsScreen> {
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
        _registrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load registrations: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsAttended(EventRegistration registration) async {
    try {
      await _dbService.confirmAttendance(registration.id!, true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attendance marked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadRegistrations(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(EventRegistration registration) {
    if (registration.isAttended) {
      return 'Attended';
    } else if (registration.isConfirmed) {
      return 'Confirmed';
    } else {
      return 'Registered';
    }
  }

  Color _getStatusColor(EventRegistration registration) {
    if (registration.isAttended) {
      return Colors.green;
    } else if (registration.isConfirmed) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Event Registrations'),
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
                          Icon(Icons.event, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No event registrations found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Register for events to see them here',
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
                                    backgroundColor: _getStatusColor(registration),
                                    child: Icon(
                                      registration.isAttended ? Icons.check : Icons.event,
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
                                      Text('Status: ${_getStatusText(registration)}'),
                                      if (registration.attendanceDate != null)
                                        Text('Attendance: ${registration.attendanceDate!.toString().split(' ')[0]}'),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!registration.isAttended && registration.isConfirmed)
                                        IconButton(
                                          icon: const Icon(Icons.check_circle, color: Colors.green),
                                          onPressed: () => _markAsAttended(registration),
                                          tooltip: 'Mark as Attended',
                                        ),
                                      if (registration.isAttended)
                                        IconButton(
                                          icon: const Icon(Icons.assignment, color: Colors.orange),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => CertificateDownloadScreen(
                                                  currentUser: widget.currentUser,
                                                ),
                                              ),
                                            );
                                          },
                                          tooltip: 'View Certificates',
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