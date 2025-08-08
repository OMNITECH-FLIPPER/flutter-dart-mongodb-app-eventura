import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommunicationCenterScreen extends StatefulWidget {
  final User currentUser;
  const CommunicationCenterScreen({super.key, required this.currentUser});

  @override
  State<CommunicationCenterScreen> createState() => _CommunicationCenterScreenState();
}

class _CommunicationCenterScreenState extends State<CommunicationCenterScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Message> _inbox = [];
  List<Message> _sent = [];
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await Future.wait([
        _fetchInbox(),
        _fetchSent(),
        _fetchNotifications(),
      ]);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _fetchInbox() async {
    final res = await http.get(Uri.parse('${Config.apiBaseUrl}/api/messages?userId=${widget.currentUser.userId}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() { _inbox = data.map((e) => Message.fromMap(e)).toList(); });
    }
  }

  Future<void> _fetchSent() async {
    final res = await http.get(Uri.parse('${Config.apiBaseUrl}/api/messages?senderId=${widget.currentUser.userId}'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List;
      setState(() { _sent = data.map((e) => Message.fromMap(e)).toList(); });
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final res = await http.get(Uri.parse('${Config.apiBaseUrl}/api/notifications?userId=${widget.currentUser.userId}'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() { _notifications = data; });
      } else {
        setState(() { _notifications = []; });
      }
    } catch (e) {
      setState(() { _notifications = []; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(icon: Icon(Icons.inbox), text: 'Inbox'),
            Tab(icon: Icon(Icons.send), text: 'Sent'),
            Tab(icon: Icon(Icons.edit), text: 'Compose'),
            Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInboxTab(),
                    _buildSentTab(),
                    _buildComposeTab(),
                    _buildNotificationsTab(),
                  ],
                ),
    );
  }

  Widget _buildInboxTab() {
    if (_inbox.isEmpty) {
      return const Center(child: Text('No messages in inbox.'));
    }
    return ListView.builder(
      itemCount: _inbox.length,
      itemBuilder: (context, idx) {
        final msg = _inbox[idx];
        return ListTile(
          leading: const Icon(Icons.mail),
          title: Text(msg.senderName),
          subtitle: Text(msg.message, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_formatDate(msg.createdAt)),
          onTap: () => _showMessageThread(msg),
        );
      },
    );
  }

  Widget _buildSentTab() {
    if (_sent.isEmpty) {
      return const Center(child: Text('No sent messages.'));
    }
    return ListView.builder(
      itemCount: _sent.length,
      itemBuilder: (context, idx) {
        final msg = _sent[idx];
        return ListTile(
          leading: const Icon(Icons.send),
          title: Text(msg.message, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('To: ${msg.replyTo ?? 'All/Unknown'}'),
          trailing: Text(_formatDate(msg.createdAt)),
          onTap: () => _showMessageThread(msg),
        );
      },
    );
  }

  Widget _buildComposeTab() {
    final recipientController = TextEditingController();
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();
    bool sending = false;
    String? sendError;

    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: recipientController,
              decoration: const InputDecoration(
                labelText: 'Recipient User ID (leave blank for all)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            if (sendError != null)
              Text(sendError!, style: const TextStyle(color: Colors.red)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: sending
                    ? null
                    : () async {
                        setState(() { sending = true; sendError = null; });
                        try {
                          final res = await http.post(
                            Uri.parse('${Config.apiBaseUrl}/api/messages'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'senderId': widget.currentUser.userId,
                              'senderName': widget.currentUser.name,
                              'senderRole': widget.currentUser.role,
                              'message': bodyController.text,
                              'replyTo': null,
                            }),
                          );
                          if (res.statusCode == 201) {
                            setState(() { sending = false; });
                            bodyController.clear();
                            subjectController.clear();
                            recipientController.clear();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Message sent!')));
                          } else {
                            setState(() { sendError = 'Failed to send message.'; sending = false; });
                          }
                        } catch (e) {
                          setState(() { sendError = e.toString(); sending = false; });
                        }
                      },
                child: sending ? const CircularProgressIndicator() : const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return const Center(child: Text('No notifications.'));
    }
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, idx) {
        final notif = _notifications[idx];
        return ListTile(
          leading: const Icon(Icons.notifications),
          title: Text(notif['title'] ?? 'Notification'),
          subtitle: Text(notif['body'] ?? ''),
          trailing: Text(_formatDate(DateTime.tryParse(notif['createdAt'] ?? '') ?? DateTime.now())),
        );
      },
    );
  }

  void _showMessageThread(Message msg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => MessageThreadView(
        message: msg,
        currentUser: widget.currentUser,
        onReply: _fetchAll,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class MessageThreadView extends StatefulWidget {
  final Message message;
  final User currentUser;
  final VoidCallback onReply;
  const MessageThreadView({super.key, required this.message, required this.currentUser, required this.onReply});

  @override
  State<MessageThreadView> createState() => _MessageThreadViewState();
}

class _MessageThreadViewState extends State<MessageThreadView> {
  final _replyController = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Material(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.mail),
                title: Text(msg.senderName),
                subtitle: Text(msg.message),
                trailing: Text(_formatDate(msg.createdAt)),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: msg.replies.length,
                  itemBuilder: (context, idx) {
                    final reply = msg.replies[idx];
                    return ListTile(
                      leading: const Icon(Icons.reply),
                      title: Text(reply.senderName),
                      subtitle: Text(reply.message),
                      trailing: Text(_formatDate(reply.createdAt)),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        decoration: const InputDecoration(
                          labelText: 'Reply...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _sending
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              if (_replyController.text.trim().isEmpty) return;
                              setState(() { _sending = true; _error = null; });
                              try {
                                final res = await http.post(
                                  Uri.parse('${Config.apiBaseUrl}/api/messages/${msg.id}/reply'),
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'senderId': widget.currentUser.userId,
                                    'senderName': widget.currentUser.name,
                                    'senderRole': widget.currentUser.role,
                                    'message': _replyController.text.trim(),
                                  }),
                                );
                                if (res.statusCode == 200) {
                                  _replyController.clear();
                                  widget.onReply();
                                  Navigator.of(context).pop();
                                } else {
                                  setState(() { _error = 'Failed to send reply.'; _sending = false; });
                                }
                              } catch (e) {
                                setState(() { _error = e.toString(); _sending = false; });
                              }
                            },
                          ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
