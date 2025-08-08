import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../services/email_service.dart';

class CommunicationScreen extends StatefulWidget {
  final User currentUser;
  
  const CommunicationScreen({super.key, required this.currentUser});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  List<User> _users = [];
  List<Event> _events = [];
  List<User> _selectedUsers = [];
  List<Event> _selectedEvents = [];
  
  bool _isLoading = false;
  bool _selectAllUsers = false;
  bool _selectAllEvents = false;
  String _communicationType = 'message'; // 'message' or 'notification'
  String _targetType = 'all'; // 'all', 'users', 'events', 'role'
  String _selectedRole = 'User';
  String _selectedEventId = '';
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dbService.getAllUsers();
      final events = await _dbService.getAllEvents();
      
      setState(() {
        _users = users.where((user) => user.status == 'active').toList();
        _events = events.where((event) => !event.pendingApproval).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectAllUsers() {
    setState(() {
      _selectAllUsers = !_selectAllUsers;
      if (_selectAllUsers) {
        _selectedUsers = List.from(_users);
      } else {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleSelectAllEvents() {
    setState(() {
      _selectAllEvents = !_selectAllEvents;
      if (_selectAllEvents) {
        _selectedEvents = List.from(_events);
      } else {
        _selectedEvents.clear();
      }
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
        _selectAllUsers = false;
      } else {
        _selectedUsers.add(user);
        if (_selectedUsers.length == _users.length) {
          _selectAllUsers = true;
        }
      }
    });
  }

  void _toggleEventSelection(Event event) {
    setState(() {
      if (_selectedEvents.contains(event)) {
        _selectedEvents.remove(event);
        _selectAllEvents = false;
      } else {
        _selectedEvents.add(event);
        if (_selectedEvents.length == _events.length) {
          _selectAllEvents = true;
        }
      }
    });
  }

  List<User> get _targetUsers {
    switch (_targetType) {
      case 'all':
        return _users;
      case 'users':
        return _selectedUsers;
      case 'events':
        // Get users registered for selected events
        return _users.where((user) {
          // This would need to be implemented with actual registration data
          return true; // Placeholder
        }).toList();
      case 'role':
        return _users.where((user) => user.role == _selectedRole).toList();
      default:
        return _users;
    }
  }

  List<Map<String, String>> get _messageTemplates => [
    {
      'name': 'Event Reminder',
      'subject': 'Reminder: Upcoming Event',
      'message': 'Dear participant,\n\nThis is a friendly reminder about the upcoming event.\n\nPlease ensure you arrive on time.\n\nBest regards,\nEvent Team'
    },
    {
      'name': 'Welcome Message',
      'subject': 'Welcome to Our Platform',
      'message': 'Dear user,\n\nWelcome to our event management platform! We\'re excited to have you join us.\n\nBest regards,\nEvent Team'
    },
    {
      'name': 'Event Update',
      'subject': 'Important Event Update',
      'message': 'Dear participant,\n\nWe have an important update regarding your registered event.\n\nPlease check the event details for any changes.\n\nBest regards,\nEvent Team'
    },
    {
      'name': 'Certificate Available',
      'subject': 'Your Certificate is Ready',
      'message': 'Dear participant,\n\nYour certificate for the attended event is now available for download.\n\nThank you for participating!\n\nBest regards,\nEvent Team'
    },
  ];

  void _applyTemplate(Map<String, String> template) {
    setState(() {
      _subjectController.text = template['subject']!;
      _messageController.text = template['message']!;
    });
  }

  Future<void> _sendCommunication() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter subject and message'), backgroundColor: Colors.red),
      );
      return;
    }

    final targetUsers = _targetUsers;
    if (targetUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users selected'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int successCount = 0;
      int totalCount = targetUsers.length;

      for (final user in targetUsers) {
        try {
          bool success = false;
          
          if (_communicationType == 'message') {
            // Send email
            success = await EmailService.sendEmail(
              to: user.email,
              subject: _subjectController.text.trim(),
              htmlContent: _messageController.text.replaceAll('\n', '<br>'),
            );
          } else {
            // Send notification via backend API
            success = await _dbService.sendNotification(
              userId: user.userId,
              title: _subjectController.text.trim(),
              body: _messageController.text.trim(),
            );
          }
          
          if (success) successCount++;
        } catch (e) {
          debugPrint('Failed to send to ${user.email}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent successfully to $successCount out of $totalCount users'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
        
        // Clear form
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedUsers.clear();
          _selectedEvents.clear();
          _selectAllUsers = false;
          _selectAllEvents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending communication: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication Center'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Send Message', icon: Icon(Icons.message)),
            Tab(text: 'Recipients', icon: Icon(Icons.people)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMessageTab(),
                _buildRecipientsTab(),
              ],
            ),
    );
  }

  Widget _buildMessageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Communication Type Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Communication Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Email Message'),
                          value: 'message',
                          groupValue: _communicationType,
                          onChanged: (value) => setState(() => _communicationType = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Notification'),
                          value: 'notification',
                          groupValue: _communicationType,
                          onChanged: (value) => setState(() => _communicationType = value!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Target Selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Target Recipients',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _targetType,
                    decoration: const InputDecoration(
                      labelText: 'Target Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'users', child: Text('Selected Users')),
                      DropdownMenuItem(value: 'events', child: Text('Event Participants')),
                      DropdownMenuItem(value: 'role', child: Text('By Role')),
                    ],
                    onChanged: (value) => setState(() => _targetType = value!),
                  ),
                  if (_targetType == 'role') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'User', child: Text('Users')),
                        DropdownMenuItem(value: 'Organizer', child: Text('Organizers')),
                        DropdownMenuItem(value: 'Admin', child: Text('Admins')),
                      ],
                      onChanged: (value) => setState(() => _selectedRole = value!),
                    ),
                  ],
                  if (_targetType == 'events') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEventId,
                      decoration: const InputDecoration(
                        labelText: 'Event',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(value: '', child: Text('Select Event')),
                        ..._events.map((event) => DropdownMenuItem(
                          value: event.id,
                          child: Text(event.title),
                        )),
                      ],
                      onChanged: (value) => setState(() => _selectedEventId = value!),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message Templates
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message Templates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Message Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Message Content',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendCommunication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Config.primaryColor,
                        foregroundColor: Config.secondaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Send ${_communicationType == 'message' ? 'Email' : 'Notification'}'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientsTab() {
    return Column(
      children: [
        // Target Summary
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recipient Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Target Type: ${_targetType.toUpperCase()}'),
                Text('Total Recipients: ${_targetUsers.length}'),
                if (_targetType == 'role') Text('Selected Role: $_selectedRole'),
                if (_targetType == 'events') Text('Selected Events: ${_selectedEvents.length}'),
              ],
            ),
          ),
        ),

        // Users List
        Expanded(
          child: _users.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No users available'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    final isSelected = _selectedUsers.contains(user);
                    final isTarget = _targetUsers.contains(user);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isTarget ? Colors.blue.shade50 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.role),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(user.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(user.role),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user.role,
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                if (isTarget) ...[
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'TARGET',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: _targetType == 'users'
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (value) => _toggleUserSelection(user),
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case Config.roleAdmin:
        return Colors.red;
      case Config.roleOrganizer:
        return Colors.orange;
      case Config.roleUser:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
