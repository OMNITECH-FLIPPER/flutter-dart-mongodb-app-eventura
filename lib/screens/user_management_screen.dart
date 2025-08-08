import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../utils/email_notification_utils.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _dbService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
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
        if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
            _loadUsers();
      }
        } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to delete user'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
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
              if (nameController.text.trim().isNotEmpty &&
                  emailController.text.trim().isNotEmpty &&
                  addressController.text.trim().isNotEmpty &&
                  ageController.text.trim().isNotEmpty) {
                Navigator.of(context).pop({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'address': addressController.text.trim(),
                  'age': ageController.text.trim(),
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Config.primaryColor,
              foregroundColor: Config.secondaryColor,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final updatedUser = User(
          name: result['name']!,
          userId: user.userId,
          password: user.password,
          role: user.role,
          age: int.parse(result['age']!),
          email: result['email']!,
          address: result['address']!,
          status: user.status,
        );

        final success = await _dbService.updateUser(updatedUser.userId, {
          'name': updatedUser.name,
          'age': updatedUser.age,
          'email': updatedUser.email,
          'address': updatedUser.address,
        });
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${user.name} updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadUsers();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update user'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

  Future<void> _blockUser(User user) async {
    try {
      final success = await _dbService.blockUser(user.userId);
      if (success) {
        // Send account status notification
        final notificationSuccess = await EmailNotificationUtils.sendAccountStatusNotification(user, 'blocked');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} blocked successfully. ${EmailNotificationUtils.getNotificationStatus(notificationSuccess, "Account status")}'),
              backgroundColor: notificationSuccess ? Colors.orange : Colors.red,
            ),
          );
          _loadUsers();
        }
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

  Future<void> _unblockUser(User user) async {
    try {
      final success = await _dbService.unblockUser(user.userId);
      if (success) {
        // Send account status notification
        final notificationSuccess = await EmailNotificationUtils.sendAccountStatusNotification(user, 'active');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.name} unblocked successfully. ${EmailNotificationUtils.getNotificationStatus(notificationSuccess, "Account status")}'),
              backgroundColor: notificationSuccess ? Colors.green : Colors.orange,
            ),
          );
          _loadUsers();
        }
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

  Future<void> _changeUserRole(User user) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change User Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current role: ${user.role}'),
            const SizedBox(height: 16),
            const Text('Select new role:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(Config.roleUser),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.primaryColor,
                    foregroundColor: Config.secondaryColor,
                  ),
                  child: const Text('User'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(Config.roleOrganizer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.primaryColor,
                    foregroundColor: Config.secondaryColor,
                  ),
                  child: const Text('Organizer'),
                ),
              ],
            ),
          ],
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
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${user.name} role changed to $newRole'),
                backgroundColor: Colors.green,
              ),
            );
            _loadUsers();
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
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
                        onPressed: _loadUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primaryColor,
                          foregroundColor: Config.secondaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: user.status == 'active' ? Colors.green : Colors.red,
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
                                        _blockUser(user);
                                      } else {
                                        _unblockUser(user);
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
    );
  }
} 