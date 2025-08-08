import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../models/event_registration.dart';
import '../services/database_service.dart';
import '../utils/qr_code_utils.dart';

class OrganizerQRManagementScreen extends StatefulWidget {
  final User organizer;
  final Event event;
  
  const OrganizerQRManagementScreen({
    super.key,
    required this.organizer,
    required this.event,
  });

  @override
  State<OrganizerQRManagementScreen> createState() => _OrganizerQRManagementScreenState();
}

class _OrganizerQRManagementScreenState extends State<OrganizerQRManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<EventRegistration> _registrations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedTab = 'event_info'; // 'event_info' or 'check_in'

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

  Widget _buildEventInfoQR() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Information QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Config.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This QR code contains general event information that anyone can scan to get event details.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: QRCodeUtils.generateEventInfoQR(widget.event, size: 250),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showQRDetails('event_info'),
                          icon: const Icon(Icons.info),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadQRCode('event_info'),
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
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
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Config.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Title', widget.event.title),
                  _buildInfoRow('Date', widget.event.eventDate.toString().split(' ')[0]),
                  _buildInfoRow('Time', widget.event.eventDate.toString().split(' ')[1].substring(0, 5)),
                  _buildInfoRow('Location', widget.event.location),
                  _buildInfoRow('Organizer', widget.event.organizerName),
                  _buildInfoRow('Available Slots', '${widget.event.availableSlots} / ${widget.event.totalSlots}'),
                  _buildInfoRow('Description', widget.event.description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInQRs() {
    if (_registrations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No registrations found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Participants must register for this event first',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registrations.length,
      itemBuilder: (context, index) {
        final registration = _registrations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: registration.isAttended 
                          ? Colors.green 
                          : registration.isConfirmed 
                              ? Colors.orange 
                              : Colors.blue,
                      child: Icon(
                        registration.isAttended ? Icons.check : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registration.userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            registration.userEmail,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Status: ${registration.isAttended ? 'Attended' : registration.isConfirmed ? 'Confirmed' : 'Registered'}',
                            style: TextStyle(
                              color: registration.isAttended 
                                  ? Colors.green 
                                  : registration.isConfirmed 
                                      ? Colors.orange 
                                      : Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: QRCodeUtils.generateEventCheckInQR(widget.event, registration, size: 200),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showQRDetails('check_in', registration),
                        icon: const Icon(Icons.info),
                        label: const Text('Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadQRCode('check_in', registration),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
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
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  void _showQRDetails(String type, [EventRegistration? registration]) {
    String qrData;
    String title;
    String description;

    if (type == 'event_info') {
      qrData = QRCodeUtils.generateEventInfoData(widget.event);
      title = 'Event Info QR Code Details';
      description = 'This QR code contains general event information.';
    } else {
      qrData = QRCodeUtils.generateEventCheckInData(widget.event, registration!);
      title = 'Check-in QR Code Details';
      description = 'This QR code is for checking in ${registration.userName}.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Code Data:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    qrData,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadQRCode(String type, [EventRegistration? registration]) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download feature is not available on web. Use mobile app for downloading QR codes.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // Mobile download implementation would go here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading ${type == 'event_info' ? 'Event Info' : 'Check-in'} QR code...'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Management - ${widget.event.title}'),
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
                    // Tab bar
                    Container(
                      color: Colors.grey.shade100,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              'Event Info QR',
                              'event_info',
                              Icons.qr_code,
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              'Check-in QR Codes',
                              'check_in',
                              Icons.qr_code_scanner,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Tab content
                    Expanded(
                      child: _selectedTab == 'event_info' 
                          ? _buildEventInfoQR()
                          : _buildCheckInQRs(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildTabButton(String label, String tab, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Config.primaryColor : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Config.primaryColor : Colors.grey.shade300,
              width: 2,
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Config.secondaryColor : Colors.grey.shade600,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Config.secondaryColor : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 