import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../utils/certificate_utils.dart';

class OrganizerAttendanceManagementScreen extends StatefulWidget {
  final User organizer;
  final Event event;
  
  const OrganizerAttendanceManagementScreen({
    super.key,
    required this.organizer,
    required this.event,
  });

  @override
  State<OrganizerAttendanceManagementScreen> createState() => _OrganizerAttendanceManagementScreenState();
}

class _OrganizerAttendanceManagementScreenState extends State<OrganizerAttendanceManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<EventRegistration> _registrations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'all'; // 'all', 'registered', 'attended', 'missed'
  final bool _showOnlyAttended = false;

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  Future<void> _loadRegistrations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registrations = await _dbService.getRegistrationsByEvent(widget.event.id ?? '');
      setState(() {
        _registrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load registrations: $e';
        _isLoading = false;
      });
    }
  }

  List<EventRegistration> get _filteredRegistrations {
    return _registrations.where((reg) {
      switch (_filterStatus) {
        case 'registered':
          return reg.isConfirmed && !reg.isAttended;
        case 'attended':
          return reg.isAttended;
        case 'missed':
          return reg.isConfirmed && !reg.isAttended && 
                 widget.event.eventDate.isBefore(DateTime.now());
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _markAttendance(EventRegistration registration, bool attended) async {
    try {
      final success = await _dbService.confirmAttendance(
        registration.id!,
        attended,
      );
      
      if (success && attended) {
        // Generate certificate if attendance is marked
        await _generateCertificate(registration);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${registration.userName} marked as ${attended ? 'attended' : 'not attended'}'),
            backgroundColor: attended ? Colors.green : Colors.orange,
          ),
        );
        _loadRegistrations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateCertificate(EventRegistration registration) async {
    try {
      final certificatePdf = await CertificateUtils.generateCertificate(
        registration,
        widget.event,
      );
      
      // Save certificate to device
      // For now, just confirm the certificate was generated
      final certificateUrl = 'generated-${registration.id}-${DateTime.now().millisecondsSinceEpoch}';
      
      // Update registration with certificate URL
      await _dbService.confirmAttendance(
        registration.id!,
        true,
        certificateUrl: certificateUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Certificate generated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bulkMarkAttendance(bool attended) async {
    final selectedRegistrations = _filteredRegistrations.where((reg) => 
      attended ? !reg.isAttended : reg.isAttended
    ).toList();
    
    if (selectedRegistrations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No registrations to mark as ${attended ? 'attended' : 'not attended'}'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bulk Mark Attendance'),
        content: Text('Mark ${selectedRegistrations.length} participants as ${attended ? 'attended' : 'not attended'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: attended ? Colors.green : Colors.orange,
            ),
            child: Text(attended ? 'Mark Attended' : 'Mark Not Attended'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      int successCount = 0;
      for (final registration in selectedRegistrations) {
        try {
          final success = await _dbService.confirmAttendance(
            registration.id!,
            attended,
          );
          if (success && attended) {
            await _generateCertificate(registration);
          }
          successCount++;
        } catch (e) {
          debugPrint('Error marking attendance for ${registration.userName}: $e');
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully marked $successCount out of ${selectedRegistrations.length} participants'),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );
        _loadRegistrations();
      }
    }
  }

  Widget _buildStatistics() {
    final totalRegistrations = _registrations.length;
    final attendedCount = _registrations.where((r) => r.isAttended).length;
    final registeredCount = _registrations.where((r) => r.isConfirmed && !r.isAttended).length;
    final missedCount = _registrations.where((r) => 
      r.isConfirmed && !r.isAttended && widget.event.eventDate.isBefore(DateTime.now())
    ).length;
    
    final attendanceRate = totalRegistrations > 0 ? (attendedCount / totalRegistrations * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', totalRegistrations.toString(), Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Attended', attendedCount.toString(), Colors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Registered', registeredCount.toString(), Colors.orange),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard('Missed', missedCount.toString(), Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: attendanceRate / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                attendanceRate >= 80 ? Colors.green : 
                attendanceRate >= 60 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Attendance Rate: ${attendanceRate.toStringAsFixed(1)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance - ${widget.event.title}'),
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
                        onPressed: _loadRegistrations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primaryColor,
                          foregroundColor: Config.secondaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStatistics(),
                    
                    // Filter and Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filterStatus,
                              decoration: const InputDecoration(
                                labelText: 'Filter',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All')),
                                DropdownMenuItem(value: 'registered', child: Text('Registered')),
                                DropdownMenuItem(value: 'attended', child: Text('Attended')),
                                DropdownMenuItem(value: 'missed', child: Text('Missed')),
                              ],
                              onChanged: (value) => setState(() => _filterStatus = value!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _bulkMarkAttendance(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Mark All Attended'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Registrations List
                    Expanded(
                      child: _filteredRegistrations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No registrations found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadRegistrations,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filteredRegistrations.length,
                                itemBuilder: (context, index) {
                                  final registration = _filteredRegistrations[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: registration.isAttended 
                                            ? Colors.green 
                                            : Colors.orange,
                                        child: Icon(
                                          registration.isAttended 
                                              ? Icons.check 
                                              : Icons.pending,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        registration.userName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Email: ${registration.userEmail}'),
                                          Text('Registration Date: ${registration.registrationDate.toString().split(' ')[0]}'),
                                          if (registration.isAttended && registration.attendanceDate != null)
                                            Text('Attendance Date: ${registration.attendanceDate!.toString().split(' ')[0]}'),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: registration.isAttended ? Colors.green : Colors.orange,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  registration.isAttended ? 'Attended' : 'Registered',
                                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                                ),
                                              ),
                                              if (registration.certificateUrl != null) ...[
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Text(
                                                    'Certificate',
                                                    style: TextStyle(color: Colors.white, fontSize: 10),
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
                                            case 'mark_attended':
                                              _markAttendance(registration, true);
                                              break;
                                            case 'mark_not_attended':
                                              _markAttendance(registration, false);
                                              break;
                                            case 'generate_certificate':
                                              if (registration.isAttended) {
                                                _generateCertificate(registration);
                                              }
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (!registration.isAttended)
                                            const PopupMenuItem(
                                              value: 'mark_attended',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.check, color: Colors.green),
                                                  SizedBox(width: 8),
                                                  Text('Mark Attended'),
                                                ],
                                              ),
                                            ),
                                          if (registration.isAttended)
                                            const PopupMenuItem(
                                              value: 'mark_not_attended',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.close, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Mark Not Attended'),
                                                ],
                                              ),
                                            ),
                                          if (registration.isAttended && registration.certificateUrl == null)
                                            const PopupMenuItem(
                                              value: 'generate_certificate',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.description, color: Colors.blue),
                                                  SizedBox(width: 8),
                                                  Text('Generate Certificate'),
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
                ),
    );
  }
} 