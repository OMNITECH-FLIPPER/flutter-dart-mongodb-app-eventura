import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../config.dart';
import 'organizer_event_form_screen.dart';
import 'organizer_event_registered_users_screen.dart';
import 'organizer_messaging_screen.dart';
import 'organizer_certificate_upload_screen.dart';
import 'organizer_attendance_management_screen.dart';
import 'organizer_qr_management_screen.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class OrganizerEventListScreen extends StatefulWidget {
  final User organizer;
  const OrganizerEventListScreen({super.key, required this.organizer});

  @override
  State<OrganizerEventListScreen> createState() => _OrganizerEventListScreenState();
}

class _OrganizerEventListScreenState extends State<OrganizerEventListScreen> {
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;
  bool _selectionMode = false;
  final Set<String> _selectedEventIds = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getEventsByOrganizer(widget.organizer.userId);
      setState(() {
        _events = events;
        _isLoading = false;
        _selectedEventIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _deleteEvent(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        final databaseService = DatabaseService();
        final success = await databaseService.deleteEvent(event.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Event "${event.title}" deleted.'), backgroundColor: Colors.red),
          );
          _loadEvents();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: Unable to delete event.'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _bulkDeleteEvents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bulk Delete Events'),
        content: Text('Are you sure you want to delete ${_selectedEventIds.length} selected events?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final databaseService = DatabaseService();
      for (final event in _events.where((e) => _selectedEventIds.contains(e.id))) {
        await databaseService.deleteEvent(event.id!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedEventIds.length} events deleted.'), backgroundColor: Colors.red),
        );
        _loadEvents();
      }
    }
  }

  Future<void> _bulkUpdateStatus(String status) async {
    final databaseService = DatabaseService();
    for (final event in _events.where((e) => _selectedEventIds.contains(e.id))) {
      await databaseService.updateEvent(event.id!, {'status': status});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated for ${_selectedEventIds.length} events.'), backgroundColor: Colors.green),
      );
      _loadEvents();
    }
  }

  Future<void> _editEvent(Event event) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => OrganizerEventFormScreen(organizer: widget.organizer, eventToEdit: event),
      ),
    );
    if (updated == true) _loadEvents();
  }

  void _messageParticipants(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrganizerMessagingScreen(event: event),
      ),
    );
  }

  void _uploadCertificates(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrganizerCertificateUploadScreen(
          organizer: widget.organizer,
          event: event,
        ),
      ),
    );
  }

  void _manageAttendance(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrganizerAttendanceManagementScreen(
          organizer: widget.organizer,
          event: event,
        ),
      ),
    );
  }

  void _manageQR(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrganizerQRManagementScreen(
          organizer: widget.organizer,
          event: event,
        ),
      ),
    );
  }

  Future<void> _exportEventsToCSV() async {
    final rows = <List<String>>[
      [
        'Title',
        'Description',
        'Date',
        'Location',
        'Total Slots',
        'Available Slots',
        'Status',
      ],
      ..._events.map((e) => [
        e.title,
        e.description,
        e.eventDate.toIso8601String(),
        e.location,
        e.totalSlots.toString(),
        e.availableSlots.toString(),
        e.status,
      ]),
    ];
    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/my_events_export.csv');
    await file.writeAsString(csvData);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Events exported to ${file.path}'), backgroundColor: Colors.green),
      );
    }
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
            icon: const Icon(Icons.download),
            tooltip: 'Export Events to CSV',
            onPressed: _events.isEmpty ? null : _exportEventsToCSV,
          ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Selection',
              onPressed: () => setState(() { _selectionMode = false; _selectedEventIds.clear(); }),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _events.isEmpty
                  ? const Center(child: Text('No events found.'))
                  : Column(
                      children: [
                        if (_selectionMode)
                          Material(
                            color: Colors.grey[100],
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Bulk Delete',
                                  onPressed: _bulkDeleteEvents,
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Bulk Status Update',
                                  onSelected: (status) => _bulkUpdateStatus(status),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'upcoming', child: Text('Set as Upcoming')),
                                    const PopupMenuItem(value: 'ongoing', child: Text('Set as Ongoing')),
                                    const PopupMenuItem(value: 'completed', child: Text('Set as Completed')),
                                    const PopupMenuItem(value: 'cancelled', child: Text('Set as Cancelled')),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Text('${_selectedEventIds.length} selected'),
                              ],
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _events.length,
                            itemBuilder: (context, index) {
                              final event = _events[index];
                              final selected = _selectedEventIds.contains(event.id);
                              return GestureDetector(
                                onLongPress: () {
                                  setState(() {
                                    _selectionMode = true;
                                    _selectedEventIds.add(event.id!);
                                  });
                                },
                                child: Card(
                                  color: selected ? Colors.blue[50] : null,
                                  child: ListTile(
                                    leading: _selectionMode
                                        ? Checkbox(
                                            value: selected,
                                            onChanged: (checked) {
                                              setState(() {
                                                if (checked == true) {
                                                  _selectedEventIds.add(event.id!);
                                                } else {
                                                  _selectedEventIds.remove(event.id!);
                                                }
                                              });
                                            },
                                          )
                                        : (event.imageUrl.isNotEmpty
                                            ? Image.network(event.imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                                            : const Icon(Icons.event, size: 40, color: Config.primaryColor)),
                                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('Date: ${event.eventDate.toLocal().toString().split(" ")[0]}'),
                                    trailing: !_selectionMode
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.qr_code, color: Colors.indigo),
                                                onPressed: () => _manageQR(event),
                                                tooltip: 'Manage QR Codes',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.people, color: Colors.purple),
                                                onPressed: () => _manageAttendance(event),
                                                tooltip: 'Manage Attendance',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.assignment, color: Colors.orange),
                                                onPressed: () => _uploadCertificates(event),
                                                tooltip: 'Upload Certificates',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.message, color: Colors.blue),
                                                onPressed: () => _messageParticipants(event),
                                                tooltip: 'Message Participants',
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Config.primaryColor),
                                                onPressed: () => _editEvent(event),
                                                tooltip: 'Edit',
                                              ),
                                            ],
                                          )
                                        : null,
                                    onTap: !_selectionMode
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => OrganizerEventRegisteredUsersScreen(event: event),
                                              ),
                                            );
                                          }
                                        : () {
                                            setState(() {
                                              if (selected) {
                                                _selectedEventIds.remove(event.id!);
                                              } else {
                                                _selectedEventIds.add(event.id!);
                                              }
                                            });
                                          },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }
} 