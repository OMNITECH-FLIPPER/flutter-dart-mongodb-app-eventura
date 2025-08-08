import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/event.dart';

class AdminManagementScreen extends StatefulWidget {
  final User currentUser;
  
  const AdminManagementScreen({super.key, required this.currentUser});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  List<User> _users = [];
  List<Event> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;
  String _searchQuery = '';
  String _userFilter = 'all';
  String _eventFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _dbService.getAllUsers();
      final events = await _dbService.getAllEvents();
      
      setState(() {
        _users = users;
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  List<User> get _filteredUsers {
    return _users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           user.userId.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _userFilter == 'all' ||
                           (_userFilter == 'active' && user.status == 'active') ||
                           (_userFilter == 'blocked' && user.status == 'blocked') ||
                           (_userFilter == 'admin' && user.role == Config.roleAdmin) ||
                           (_userFilter == 'organizer' && user.role == Config.roleOrganizer) ||
                           (_userFilter == 'user' && user.role == Config.roleUser);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  List<Event> get _filteredEvents {
    return _events.where((event) {
      final matchesSearch = event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           event.location.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFilter = _eventFilter == 'all' ||
                           (_eventFilter == 'pending' && event.pendingApproval) ||
                           (_eventFilter == 'approved' && !event.pendingApproval && event.status == 'upcoming') ||
                           (_eventFilter == 'ongoing' && event.status == 'ongoing') ||
                           (_eventFilter == 'completed' && event.status == 'completed') ||
                           (_eventFilter == 'cancelled' && event.status == 'cancelled');
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _dbService.deleteUser(user.userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete user'),
              backgroundColor: Colors.red,
            ),
          );
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
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _dbService.deleteEvent(event.id!);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.title}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete event'),
              backgroundColor: Colors.red,
            ),
          );
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
  }

  Future<void> _editUser(User user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final addressController = TextEditingController(text: user.address);
    final ageController = TextEditingController(text: user.age.toString());

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${user.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'name': nameController.text,
                'email': emailController.text,
                'address': addressController.text,
                'age': ageController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final success = await _dbService.updateUser(
          user.userId,
          {
            'name': result['name'],
            'email': result['email'],
            'address': result['address'],
            'age': int.tryParse(result['age'] ?? '0') ?? 0,
          },
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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
  }

  Future<void> _editEvent(Event event) async {
    final titleController = TextEditingController(text: event.title);
    final descriptionController = TextEditingController(text: event.description);
    final locationController = TextEditingController(text: event.location);
    final slotsController = TextEditingController(text: event.totalSlots.toString());

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${event.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextField(
                controller: slotsController,
                decoration: const InputDecoration(labelText: 'Total Slots'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'title': titleController.text,
                'description': descriptionController.text,
                'location': locationController.text,
                'totalSlots': slotsController.text,
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final success = await _dbService.updateEvent(
          event.id!,
          {
            'title': result['title'],
            'description': result['description'],
            'location': result['location'],
            'total_slots': int.tryParse(result['totalSlots'] ?? '0') ?? 0,
          },
          editorUserId: widget.currentUser.userId,
          isAdmin: true,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.title}" updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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
  }

  Future<void> _changeUserRole(User user) async {
    final roles = [Config.roleUser, Config.roleOrganizer, Config.roleAdmin];
        // final currentRoleIndex = roles.indexOf(user.role);
    
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change ${user.name}\'s Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) => RadioListTile<String>(
            title: Text(role),
            value: role,
            groupValue: user.role,
            onChanged: (value) => Navigator.of(context).pop(value),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != user.role) {
      try {
        final success = await _dbService.changeUserRole(user.userId, newRole);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} role changed to $newRole'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
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
  }

  Future<void> _approveEvent(Event event) async {
    try {
      final success = await _dbService.updateEvent(
        event.id!,
        {'pending_approval': false},
        editorUserId: widget.currentUser.userId,
        isAdmin: true,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" approved'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
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

  Future<void> _rejectEvent(Event event) async {
    try {
      final success = await _dbService.updateEvent(
        event.id!,
        {'status': 'cancelled', 'pending_approval': false},
        editorUserId: widget.currentUser.userId,
        isAdmin: true,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEventStatusColor(String status) {
    switch (status) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Management'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Events', icon: Icon(Icons.event)),
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
                        onPressed: _loadData,
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
                    // Users Tab
                    _buildUsersTab(),
                    // Events Tab
                    _buildEventsTab(),
                  ],
                ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search users...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _userFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter by',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                  DropdownMenuItem(value: 'organizer', child: Text('Organizers')),
                  DropdownMenuItem(value: 'user', child: Text('Users')),
                ],
                onChanged: (value) => setState(() => _userFilter = value!),
              ),
            ],
          ),
        ),
        // Users List
        Expanded(
          child: _filteredUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role),
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ID: ${user.userId}'),
                              Text('Email: ${user.email}'),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(user.role),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.role,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(user.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editUser(user);
                                  break;
                                case 'role':
                                  _changeUserRole(user);
                                  break;
                                case 'block':
                                  if (user.status == 'active') {
                                    _dbService.blockUser(user.userId).then((_) => _loadData());
                                  } else {
                                    _dbService.unblockUser(user.userId).then((_) => _loadData());
                                  }
                                  break;
                                case 'delete':
                                  _deleteUser(user);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'role',
                                child: Row(
                                  children: [
                                    Icon(Icons.swap_horiz),
                                    SizedBox(width: 8),
                                    Text('Change Role'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'block',
                                child: Row(
                                  children: [
                                    Icon(user.status == 'active' ? Icons.block : Icons.check_circle),
                                    const SizedBox(width: 8),
                                    Text(user.status == 'active' ? 'Block' : 'Unblock'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    return Column(
      children: [
        // Search and Filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search events...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _eventFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter by',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Events')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Approval')),
                  DropdownMenuItem(value: 'approved', child: Text('Approved')),
                  DropdownMenuItem(value: 'ongoing', child: Text('Ongoing')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) => setState(() => _eventFilter = value!),
              ),
            ],
          ),
        ),
        // Events List
        Expanded(
          child: _filteredEvents.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No events found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = _filteredEvents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getEventStatusColor(event.status),
                            child: Icon(
                              event.pendingApproval ? Icons.pending : Icons.event,
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
                              Text('Organizer: ${event.organizerName}'),
                              Text('Location: ${event.location}'),
                              Text('Date: ${event.eventDate.toString().split(' ')[0]}'),
                              Text('Slots: ${event.availableSlots}/${event.totalSlots}'),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getEventStatusColor(event.status),
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
                                  if (event.pendingApproval) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _editEvent(event);
                                  break;
                                case 'approve':
                                  if (event.pendingApproval) {
                                    _approveEvent(event);
                                  }
                                  break;
                                case 'reject':
                                  if (event.pendingApproval) {
                                    _rejectEvent(event);
                                  }
                                  break;
                                case 'delete':
                                  _deleteEvent(event);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              if (event.pendingApproval) ...[
                                const PopupMenuItem(
                                  value: 'approve',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Approve', style: TextStyle(color: Colors.green)),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'reject',
                                  child: Row(
                                    children: [
                                      Icon(Icons.close, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Reject', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
