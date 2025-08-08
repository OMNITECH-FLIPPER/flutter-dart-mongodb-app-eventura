import 'package:flutter/material.dart';
import '../config.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../services/database_service.dart';
import '../services/email_service.dart';

class OrganizerMessagingScreen extends StatefulWidget {
  final Event event;
  
  const OrganizerMessagingScreen({
    super.key,
    required this.event,
  });

  @override
  State<OrganizerMessagingScreen> createState() => _OrganizerMessagingScreenState();
}

class _OrganizerMessagingScreenState extends State<OrganizerMessagingScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _dbService = DatabaseService();
  List<EventRegistration> _registrations = [];
  List<EventRegistration> _filteredRegistrations = [];
  bool _isLoading = true;
  String? _error;
  bool _isSending = false;
  String _filterType = 'all'; // all, attended, confirmed, registered
  Set<String> _selectedParticipants = {};

  // Message templates
  List<Map<String, String>> get _messageTemplates => [
    {
      'name': 'Event Reminder',
      'subject': 'Reminder: ${widget.event.title}',
      'message': 'Dear participant,\n\nThis is a friendly reminder about the upcoming event "${widget.event.title}" scheduled for ${widget.event.eventDate.toString().split(' ')[0]}.\n\nPlease ensure you arrive on time.\n\nBest regards,\nEvent Organizer'
    },
    {
      'name': 'Welcome Message',
      'subject': 'Welcome to ${widget.event.title}',
      'message': 'Dear participant,\n\nWelcome to "${widget.event.title}"! We\'re excited to have you join us.\n\nEvent Details:\n- Date: ${widget.event.eventDate.toString().split(' ')[0]}\n- Location: ${widget.event.location}\n\nSee you there!\n\nBest regards,\nEvent Organizer'
    },
    {
      'name': 'Attendance Confirmation',
      'subject': 'Attendance Confirmed - ${widget.event.title}',
      'message': 'Dear participant,\n\nYour attendance for "${widget.event.title}" has been confirmed. Thank you for participating!\n\nYour certificate will be available for download soon.\n\nBest regards,\nEvent Organizer'
    },
    {
      'name': 'Event Update',
      'subject': 'Important Update - ${widget.event.title}',
      'message': 'Dear participant,\n\nWe have an important update regarding "${widget.event.title}".\n\nPlease check the event details for any changes.\n\nBest regards,\nEvent Organizer'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final registrations = await _dbService.getRegistrationsByEvent(widget.event.id!);
      setState(() {
        _registrations = registrations;
        _filteredRegistrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _filterParticipants(String filterType) {
    setState(() {
      _filterType = filterType;
      switch (filterType) {
        case 'all':
          _filteredRegistrations = _registrations;
          break;
        case 'attended':
          _filteredRegistrations = _registrations.where((r) => r.isAttended).toList();
          break;
        case 'confirmed':
          _filteredRegistrations = _registrations.where((r) => r.isConfirmed && !r.isAttended).toList();
          break;
        case 'registered':
          _filteredRegistrations = _registrations.where((r) => !r.isConfirmed).toList();
          break;
      }
      _selectedParticipants.clear();
    });
  }

  void _selectAllParticipants() {
    setState(() {
      if (_selectedParticipants.length == _filteredRegistrations.length) {
        _selectedParticipants.clear();
      } else {
        _selectedParticipants = _filteredRegistrations.map((r) => r.id!).toSet();
      }
    });
  }

  void _selectParticipant(String registrationId) {
    setState(() {
      if (_selectedParticipants.contains(registrationId)) {
        _selectedParticipants.remove(registrationId);
      } else {
        _selectedParticipants.add(registrationId);
      }
    });
  }

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _subjectController.text = template['subject']!;
      _messageController.text = template['message']!;
    });
  }

  Future<void> _sendMessage() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both subject and message.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final subject = _subjectController.text.trim();
      final message = _messageController.text.trim();
      int successCount = 0;
      int totalCount = _selectedParticipants.length;

      final selectedRegistrations = _registrations.where((r) => _selectedParticipants.contains(r.id)).toList();

      for (final registration in selectedRegistrations) {
        try {
          final success = await EmailService.sendEmail(
            to: registration.userEmail,
            subject: subject,
            htmlContent: message.replaceAll('\n', '<br>'),
          );
          if (success) successCount++;
        } catch (e) {
          debugPrint('Failed to send message to ${registration.userName}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to $successCount out of $totalCount participants.'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
        
        if (successCount > 0) {
          _subjectController.clear();
          _messageController.clear();
          _selectedParticipants.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: Text('All (${_registrations.length})'),
            selected: _filterType == 'all',
            onSelected: (_) => _filterParticipants('all'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Attended (${_registrations.where((r) => r.isAttended).length})'),
            selected: _filterType == 'attended',
            onSelected: (_) => _filterParticipants('attended'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Confirmed (${_registrations.where((r) => r.isConfirmed && !r.isAttended).length})'),
            selected: _filterType == 'confirmed',
            onSelected: (_) => _filterParticipants('confirmed'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text('Registered (${_registrations.where((r) => !r.isConfirmed).length})'),
            selected: _filterType == 'registered',
            onSelected: (_) => _filterParticipants('registered'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTemplates() {
    return ExpansionTile(
      title: const Text('Message Templates'),
      leading: const Icon(Icons.email),
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _messageTemplates.length,
          itemBuilder: (context, index) {
            final template = _messageTemplates[index];
            return ListTile(
              title: Text(template['name']!),
              subtitle: Text(template['subject']!),
              trailing: ElevatedButton(
                onPressed: () => _applyTemplate(template),
                child: const Text('Use'),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Message Participants - ${widget.event.title}'),
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
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    // Filter chips
                    _buildFilterChips(),
                    const SizedBox(height: 16),
                    
                    // Message templates
                    _buildMessageTemplates(),
                    
                    // Message Form
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.subject),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Message',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.message),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 5,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _filteredRegistrations.isEmpty ? null : _selectAllParticipants,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(_selectedParticipants.length == _filteredRegistrations.length 
                                      ? 'Deselect All' 
                                      : 'Select All'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isSending || _selectedParticipants.isEmpty ? null : _sendMessage,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Config.primaryColor,
                                    foregroundColor: Config.secondaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: _isSending
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Sending...'),
                                          ],
                                        )
                                      : Text('Send to ${_selectedParticipants.length} Selected'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Participants List
                    Expanded(
                      child: _filteredRegistrations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, size: 64, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No participants found',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try changing the filter or register participants first',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredRegistrations.length,
                              itemBuilder: (context, index) {
                                final registration = _filteredRegistrations[index];
                                final isSelected = _selectedParticipants.contains(registration.id);
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  color: isSelected ? Config.primaryColor.withOpacity(0.1) : null,
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: isSelected,
                                      onChanged: (_) => _selectParticipant(registration.id!),
                                    ),
                                    title: Text(
                                      registration.userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Config.primaryColor : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(registration.userEmail),
                                        Text('Registered: ${registration.registrationDate.toString().split(' ')[0]}'),
                                      ],
                                    ),
                                    trailing: Chip(
                                      label: Text(
                                        registration.isAttended 
                                            ? 'Attended' 
                                            : registration.isConfirmed 
                                                ? 'Confirmed' 
                                                : 'Registered'
                                      ),
                                      backgroundColor: registration.isAttended 
                                          ? Colors.green 
                                          : registration.isConfirmed 
                                              ? Colors.orange 
                                              : Colors.blue,
                                      labelStyle: const TextStyle(color: Colors.white),
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