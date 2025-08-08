import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../widgets/connection_status_widget.dart';
import 'admin_management_screen.dart';
import 'events_screen.dart';
import 'organizer_events_screen.dart';
import 'organizer_event_form_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'qr_scanner_screen.dart';
import 'notification_center_screen.dart';
import 'certificate_download_screen.dart';
import 'user_attended_events_screen.dart';
import 'communication_center_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User currentUser;

  const DashboardScreen({super.key, required this.currentUser});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  int _totalUsers = 0;
  int _totalEvents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _dbService.getAllUsers();
      final events = await _dbService.getAllEvents();
      
      setState(() {
        _totalUsers = users.length;
        _totalEvents = events.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildQuickStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Config.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Quick Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Config.primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadStats,
                  tooltip: 'Refresh Stats',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Users',
                    _totalUsers.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Total Events',
                    _totalEvents.toString(),
                    Icons.event,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, VoidCallback onTap, Color color) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.currentUser.name}'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          ConnectionStatusWidget(dbService: _dbService),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Connection Status Card
                    ConnectionStatusCard(dbService: _dbService),
                    const SizedBox(height: 16),

                    // Quick Stats
                    _buildQuickStatsCard(),
                    const SizedBox(height: 24),

                    // Role-based Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Config.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Common Actions for all users
                    _buildActionCard(
                      'Notifications',
                      'View your notifications',
                      Icons.notifications,
                      () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => NotificationCenterScreen(currentUser: widget.currentUser),
                          ),
                        );
                      },
                      Colors.indigo,
                    ),
                    const SizedBox(height: 12),

                                         // Admin Actions
                     if (widget.currentUser.role == Config.roleAdmin) ...[
                       _buildActionCard(
                         'QR Scanner',
                         'Scan QR codes for check-in',
                         Icons.qr_code_scanner,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => QRScannerScreen(
                                 currentUser: widget.currentUser,
                               ),
                             ),
                           );
                         },
                         Colors.orange,
                       ),
                       const SizedBox(height: 12),
                       _buildActionCard(
                         'Communication Center',
                         'Unified messaging, reply, and notifications',
                         Icons.forum,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => CommunicationCenterScreen(currentUser: widget.currentUser),
                             ),
                           );
                         },
                         Colors.teal,
                       ),
                       const SizedBox(height: 12),
                       _buildActionCard(
                         'Analytics Dashboard',
                         'View analytics and reports',
                         Icons.analytics,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => AnalyticsDashboardScreen(currentUser: widget.currentUser),
                             ),
                           );
                         },
                         Colors.purple,
                       ),
                       const SizedBox(height: 12),
                       _buildActionCard(
                         'Admin Management',
                         'Manage users and events',
                         Icons.admin_panel_settings,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => AdminManagementScreen(currentUser: widget.currentUser),
                             ),
                           );
                         },
                         Colors.red,
                       ),
                     ],

                                         // Organizer Actions
                     if (widget.currentUser.role == Config.roleOrganizer) ...[
                       _buildActionCard(
                         'QR Scanner',
                         'Scan QR codes for check-in',
                         Icons.qr_code_scanner,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => QRScannerScreen(
                                 currentUser: widget.currentUser,
                               ),
                             ),
                           );
                         },
                         Colors.orange,
                       ),
                       const SizedBox(height: 12),
                       _buildActionCard(
                         'My Events',
                         'Manage your created events',
                         Icons.event_note,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => OrganizerEventsScreen(currentUser: widget.currentUser),
                             ),
                           );
                         },
                         Colors.orange,
                       ),
                       const SizedBox(height: 12),
                       _buildActionCard(
                         'Create Event',
                         'Add a new event',
                         Icons.add_circle,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => OrganizerEventFormScreen(
                                 organizer: widget.currentUser,
                               ),
                             ),
                           );
                         },
                         Colors.green,
                       ),
                       const SizedBox(height: 12),
                       _buildActionCard(
                         'Communication Center',
                         'Unified messaging, reply, and notifications',
                         Icons.forum,
                         () {
                           Navigator.of(context).push(
                             MaterialPageRoute(
                               builder: (context) => CommunicationCenterScreen(currentUser: widget.currentUser),
                             ),
                           );
                         },
                         Colors.teal,
                       ),
                     ],

                    // User Actions
                    if (widget.currentUser.role == Config.roleUser) ...[
                      _buildActionCard(
                        'Browse Events',
                        'View and register for events',
                        Icons.event,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EventsScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        'My Registrations',
                        'View your registered events',
                        Icons.how_to_reg,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => UserAttendedEventsScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        'Attended Events',
                        'View your attended events and certificates',
                        Icons.check_circle,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CertificateDownloadScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        Colors.teal,
                      ),
                      const SizedBox(height: 12),
                      _buildActionCard(
                        'Communication Center',
                        'Unified messaging, reply, and notifications',
                        Icons.forum,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CommunicationCenterScreen(currentUser: widget.currentUser),
                            ),
                          );
                        },
                        Colors.teal,
                      ),
                    ],

                    const SizedBox(height: 24),

                    // User Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'User Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Config.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildUserInfoRow('Name', widget.currentUser.name),
                            _buildUserInfoRow('User ID', widget.currentUser.userId),
                            _buildUserInfoRow('Role', widget.currentUser.role),
                            _buildUserInfoRow('Email', widget.currentUser.email),
                            _buildUserInfoRow('Status', widget.currentUser.status),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
} 