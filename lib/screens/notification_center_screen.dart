import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/user.dart';
import '../services/mongodb_notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  final User currentUser;

  const NotificationCenterScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<NotificationData> _notifications = [];
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _checkNotificationSettings();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final notifications = await MongoDBNotificationService.getStoredNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  Future<void> _checkNotificationSettings() async {
    try {
      final settings = await MongoDBNotificationService.getNotificationSettings();
      setState(() {
        _notificationsEnabled = settings['enabled'] ?? true;
      });
    } catch (e) {
      debugPrint('Error checking notification settings: $e');
    }
  }

  Future<void> _markAsRead(NotificationData notification) async {
    try {
      await MongoDBNotificationService.markNotificationAsRead(notification.id);
      await _loadNotifications(); // Reload to update UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      // Get current user ID from shared preferences or use a default
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('current_user_id') ?? 'default_user';
      
      await MongoDBNotificationService.clearAllNotifications(currentUserId);
      await _loadNotifications(); // Reload to update UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications cleared')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing notifications: $e')),
        );
      }
    }
  }

  Future<void> _toggleNotifications() async {
    try {
      if (_notificationsEnabled) {
        // Disable notifications
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notifications_enabled', false);
        setState(() => _notificationsEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications disabled')),
          );
        }
      } else {
        // Enable notifications
        final success = await MongoDBNotificationService.requestNotificationPermissions();
        setState(() => _notificationsEnabled = success);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? 'Notifications enabled' : 'Failed to enable notifications'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error toggling notifications: $e')),
        );
      }
    }
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'welcome':
        return '👋';
      case 'registration_confirmed':
        return '✅';
      case 'event_creation':
        return '🎉';
      case 'event_update':
        return '📢';
      case 'event_cancellation':
        return '❌';
      case 'attendance_confirmed':
        return '🎓';
      case 'certificate_ready':
        return '🏆';
      case 'account_status':
        return '🔒';
      case 'reminder':
        return '⏰';
      case 'capacity_alert':
        return '⚠️';
      default:
        return '📱';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'welcome':
        return Colors.blue;
      case 'registration_confirmed':
        return Colors.green;
      case 'event_creation':
        return Colors.purple;
      case 'event_update':
        return Colors.orange;
      case 'event_cancellation':
        return Colors.red;
      case 'attendance_confirmed':
        return Colors.teal;
      case 'certificate_ready':
        return Colors.amber;
      case 'account_status':
        return Colors.indigo;
      case 'reminder':
        return Colors.cyan;
      case 'capacity_alert':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: Icon(_notificationsEnabled ? Icons.notifications_active : Icons.notifications_off),
            onPressed: _toggleNotifications,
            tooltip: _notificationsEnabled ? 'Disable notifications' : 'Enable notifications',
          ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllNotifications,
              tooltip: 'Clear all notifications',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when you receive them',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationData notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.read ? 1 : 3,
      color: notification.read ? Colors.grey[50] : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type).withOpacity(0.1),
          child: Text(
            _getNotificationIcon(notification.type),
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
            color: notification.read ? Colors.grey[600] : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: TextStyle(
                color: notification.read ? Colors.grey[500] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : IconButton(
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _markAsRead(notification),
                tooltip: 'Mark as read',
              ),
        onTap: () {
          if (!notification.read) {
            _markAsRead(notification);
          }
          _handleNotificationTap(notification);
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    // Handle navigation based on notification type
    final type = notification.data['type'];
    final eventId = notification.data['eventId'];

    switch (type) {
      case 'registration_confirmed':
      case 'event_update':
      case 'event_cancellation':
      case 'attendance_confirmed':
      case 'certificate_ready':
        if (eventId != null) {
          // Navigate to event details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigate to event: $eventId')),
          );
        }
        break;
      case 'account_status':
        // Navigate to profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigate to profile')),
        );
        break;
      default:
        // Show notification details
        _showNotificationDetails(notification);
        break;
    }
  }

  void _showNotificationDetails(NotificationData notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'Type: ${notification.type}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Time: ${_formatTimestamp(notification.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Data: ${notification.data}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 