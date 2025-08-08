import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/event_registration.dart';
import '../models/event.dart';
import '../mongodb.dart';
import '../config.dart';
import 'package:printing/printing.dart';
import 'dart:io';
import 'certificate_download_screen.dart';

class UserEventsScreen extends StatefulWidget {
  final User currentUser;
  const UserEventsScreen({super.key, required this.currentUser});

  @override
  State<UserEventsScreen> createState() => _UserEventsScreenState();
}

class _UserEventsScreenState extends State<UserEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<EventRegistration> _registrations = [];
  List<Event> _allEvents = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int && args >= 0 && args < 3) {
        _tabController.index = args;
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final regs = await MongoDataBase.getRegistrationsByUser(widget.currentUser.userId);
      final events = await MongoDataBase.getAllEvents();
      setState(() {
        _registrations = regs;
        _allEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
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
        title: const Text('My Events'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Config.secondaryColor,
          tabs: const [
            Tab(text: 'Registered'),
            Tab(text: 'Attended'),
            Tab(text: 'Missed'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CertificateDownloadScreen(currentUser: widget.currentUser),
                ),
              );
            },
            tooltip: 'My Certificates',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventList('registered'),
                    _buildEventList('attended'),
                    _buildEventList('missed'),
                  ],
                ),
    );
  }

  Widget _buildEventList(String status) {
    final regs = _registrations.where((r) => r.status == status).toList();
    if (regs.isEmpty) {
      return Center(child: Text('No $status events.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: regs.length,
      itemBuilder: (context, index) {
        final reg = regs[index];
        final event = _allEvents.firstWhere((e) => e.id == reg.eventId, orElse: () => Event(
          id: reg.eventId,
          title: reg.eventTitle,
          description: '',
          organizerId: '',
          organizerName: '',
          imageUrl: '',
          totalSlots: 0,
          availableSlots: 0,
          eventDate: reg.registrationDate,
          location: '',
          status: '',
        ));
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: event.imageUrl.isNotEmpty
                ? Image.network(event.imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                : const Icon(Icons.event, size: 40, color: Config.primaryColor),
            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Date: ${event.eventDate.toLocal().toString().split(" ")[0]}'),
            trailing: status == 'attended' && reg.certificateUrl != null
                ? IconButton(
                    icon: const Icon(Icons.download, color: Config.primaryColor),
                    onPressed: () async {
                      final url = reg.certificateUrl!;
                      if (url.startsWith('http')) {
                        // Download from server
                        await Printing.layoutPdf(
                          onLayout: (_) async {
                            final response = await http.get(Uri.parse(url));
                            return response.bodyBytes;
                          },
                        );
                      } else {
                        final file = File(url);
                        if (await file.exists()) {
                          if (!mounted) return;
                          await Printing.layoutPdf(
                            onLayout: (_) async => await file.readAsBytes(),
                          );
                        } else {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Certificate file not found.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
} 