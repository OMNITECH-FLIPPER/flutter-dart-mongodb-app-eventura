import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database_service.dart';
import '../config.dart';

class AdminEventListScreen extends StatefulWidget {
  const AdminEventListScreen({super.key});

  @override
  State<AdminEventListScreen> createState() => _AdminEventListScreenState();
}

class _AdminEventListScreenState extends State<AdminEventListScreen> {
  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getAllEvents();
      setState(() {
        _events = events;
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final pendingEvents = _events.where((e) => e.pendingApproval).toList();
    final regularEvents = _events.where((e) => !e.pendingApproval).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Events'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _events.isEmpty
                  ? const Center(child: Text('No events found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (pendingEvents.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pending Approval', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                              const SizedBox(height: 8),
                              ...pendingEvents.map((event) => Card(
                                color: Colors.orange.withAlpha(51),
                                margin: const EdgeInsets.only(bottom: 16),
                                child: ListTile(
                                  title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Edited by: ${event.lastEditedBy ?? 'Unknown'}'),
                                      if (event.editHistory.isNotEmpty)
                                        ...event.editHistory.map((edit) => Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text('Edited at: ${edit['edited_at']}, Changes: ${edit['changes'].toString()}'),
                                        )),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        tooltip: 'Approve',
                                        onPressed: () async {
                                          final databaseService = DatabaseService();
                                          await databaseService.updateEvent(event.id!, {'pending_approval': false}, isAdmin: true);
                                          if (!mounted) return;
                                          _loadEvents();
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.red),
                                        tooltip: 'Reject',
                                        onPressed: () async {
                                          final databaseService = DatabaseService();
                                          // Revert to previous state if available
                                          if (event.editHistory.length > 1) {
                                            final prev = event.editHistory[event.editHistory.length - 2]['changes'] as Map<String, dynamic>;
                                            await databaseService.updateEvent(event.id!, prev, isAdmin: true);
                                          } else {
                                            // No previous, just set pendingApproval to false
                                            await databaseService.updateEvent(event.id!, {'pending_approval': false}, isAdmin: true);
                                          }
                                          if (!mounted) return;
                                          _loadEvents();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                              const Divider(),
                            ],
                          ),
                        ...regularEvents.map((event) => Dismissible(
                          key: ValueKey(event.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            color: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(Icons.delete, color: Colors.white, size: 32),
                          ),
                          confirmDismiss: (_) async {
                            await _deleteEvent(event);
                            return false;
                          },
                          child: ListTile(
                            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Date: ${event.eventDate.toLocal().toString().split(" ")[0]}'),
                          ),
                        )),
                      ],
                    ),
    );
  }
} 