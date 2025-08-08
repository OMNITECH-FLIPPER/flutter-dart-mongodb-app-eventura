import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../utils/email_notification_utils.dart';

class NotificationManagementScreen extends StatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  State<NotificationManagementScreen> createState() => _NotificationManagementScreenState();
}

class _NotificationManagementScreenState extends State<NotificationManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  List<User> _users = [];
  List<User> _selectedUsers = [];
  bool _isLoading = false;
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dbService.getAllUsers();
      setState(() {
        _users = users.where((user) => user.status == 'active').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load users: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedUsers = List.from(_users);
      } else {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
        _selectAll = false;
      } else {
        _selectedUsers.add(user);
        if (_selectedUsers.length == _users.length) {
          _selectAll = true;
        }
      }
    });
  }

  Future<void> _sendBulkNotification() async {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both subject and message'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Bulk Notification'),
        content: Text('Are you sure you want to send this notification to ${_selectedUsers.length} users?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final success = await EmailNotificationUtils.sendBulkNotificationToUsers(
          _subjectController.text.trim(),
          _messageController.text.trim(),
          _selectedUsers,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(EmailNotificationUtils.getNotificationStatus(success, "Bulk notification")),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );

          if (success) {
            _subjectController.clear();
            _messageController.clear();
            setState(() {
              _selectedUsers.clear();
              _selectAll = false;
            });
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending notification: $e'), backgroundColor: Colors.red),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh Users',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Notification Form
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send Bulk Notification',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Config.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectedUsers.isEmpty ? null : _sendBulkNotification,
                              icon: const Icon(Icons.send),
                              label: Text('Send to ${_selectedUsers.length} Users'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Config.primaryColor,
                                foregroundColor: Config.secondaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // User Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'Select Recipients (${_users.length} active users)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _toggleSelectAll,
                        icon: Icon(_selectAll ? Icons.check_box : Icons.check_box_outline_blank),
                        label: Text(_selectAll ? 'Deselect All' : 'Select All'),
                      ),
                    ],
                  ),
                ),

                // User List
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final isSelected = _selectedUsers.contains(user);
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (_) => _toggleUserSelection(user),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${user.email} • ${user.role}'),
                          secondary: CircleAvatar(
                            backgroundColor: Config.primaryColor,
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: TextStyle(color: Config.secondaryColor),
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
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