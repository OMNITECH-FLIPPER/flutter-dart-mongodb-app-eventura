import 'package:flutter/material.dart';
import '../config.dart';
import '../services/database_service.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../models/event_registration.dart';
import 'event_detail_screen.dart';

class EventsScreen extends StatefulWidget {
  final User currentUser;

  const EventsScreen({super.key, required this.currentUser});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with TickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  List<Event> _events = [];
  List<EventRegistration> _userRegistrations = [];
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      final events = await _dbService.getAllEvents();
      final registrations = await _dbService.getRegistrationsByUser(widget.currentUser.userId);
      
      setState(() {
        _events = events;
        _userRegistrations = registrations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _registerForEvent(Event event) async {
    // Check if user is already registered
    final existingRegistration = _userRegistrations.firstWhere(
      (reg) => reg.eventId == event.id,
      orElse: () => EventRegistration(
        id: '',
        userId: '',
        userName: '',
        userEmail: '',
        eventId: '',
        eventTitle: '',
        registrationDate: DateTime.now(),
        status: '',
        isConfirmed: false,
        attended: false,
        certificateUrl: null,
      ),
    );

    if (existingRegistration.id?.isNotEmpty == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You are already registered for this event'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if event has available slots
    if (event.availableSlots <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sorry, this event is full'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final registration = EventRegistration(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.currentUser.userId,
        userName: widget.currentUser.name,
        userEmail: widget.currentUser.email,
        eventId: event.id ?? '',
        eventTitle: event.title,
        registrationDate: DateTime.now(),
        status: 'registered',
        isConfirmed: false,
        attended: false,
        certificateUrl: null,
      );

      final success = await _dbService.registerForEvent(registration);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully registered for ${event.title}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData(); // Refresh data
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to register for event'),
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

  List<Event> _getRegisteredEvents() {
    final registeredEventIds = _userRegistrations.map((reg) => reg.eventId).toSet();
    return _events.where((event) => registeredEventIds.contains(event.id)).toList();
  }

  List<Event> _getAttendedEvents() {
    final attendedRegistrations = _userRegistrations.where((reg) => reg.attended).toList();
    final attendedEventIds = attendedRegistrations.map((reg) => reg.eventId).toSet();
    return _events.where((event) => attendedEventIds.contains(event.id)).toList();
  }

  List<Event> _getMissedEvents() {
    final missedRegistrations = _userRegistrations.where((reg) => 
      reg.status == 'registered' && !reg.attended && 
      _events.any((event) => event.id == reg.eventId && event.eventDate.isBefore(DateTime.now()))
    ).toList();
    final missedEventIds = missedRegistrations.map((reg) => reg.eventId).toSet();
    return _events.where((event) => missedEventIds.contains(event.id)).toList();
  }

  Widget _buildEventCard(Event event, {bool showRegisterButton = true}) {
    final isRegistered = _userRegistrations.any((reg) => reg.eventId == event.id);
    final registration = _userRegistrations.firstWhere(
      (reg) => reg.eventId == event.id,
      orElse: () => EventRegistration(
        id: '',
        userId: '',
        userName: '',
        userEmail: '',
        eventId: '',
        eventTitle: '',
        registrationDate: DateTime.now(),
        status: '',
        isConfirmed: false,
        attended: false,
        certificateUrl: null,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(
                event: event,
                currentUser: widget.currentUser,
                registration: registration.id?.isNotEmpty == true ? registration : null,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: event.status == 'active' ? Colors.green : Colors.grey,
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
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: TextStyle(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Config.primaryColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Config.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${event.eventDate.day}/${event.eventDate.month}/${event.eventDate.year}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Config.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${event.eventDate.hour.toString().padLeft(2, '0')}:${event.eventDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Config.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    '${event.availableSlots}/${event.totalSlots} slots available',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  if (isRegistered) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: registration.attended ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        registration.attended ? 'Attended' : 'Registered',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (showRegisterButton && !isRegistered && event.availableSlots > 0) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _registerForEvent(event),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Config.primaryColor,
                      foregroundColor: Config.secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Register for Event',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
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
        title: const Text('Events'),
        backgroundColor: Config.primaryColor,
        foregroundColor: Config.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Config.secondaryColor,
          labelColor: Config.secondaryColor,
          unselectedLabelColor: Config.secondaryColor.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'All Events'),
            Tab(text: 'Registered'),
            Tab(text: 'Attended'),
          ],
        ),
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
                    // All Events Tab
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _events.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No events available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final event = _events[index];
                                return _buildEventCard(event);
                              },
                            ),
                    ),
                    // Registered Events Tab
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _getRegisteredEvents().isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.how_to_reg, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No registered events',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _getRegisteredEvents().length,
                              itemBuilder: (context, index) {
                                final event = _getRegisteredEvents()[index];
                                return _buildEventCard(event, showRegisterButton: false);
                              },
                            ),
                    ),
                    // Attended Events Tab
                    RefreshIndicator(
                      onRefresh: _loadData,
                      child: _getAttendedEvents().isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 64, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text(
                                    'No attended events',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _getAttendedEvents().length,
                              itemBuilder: (context, index) {
                                final event = _getAttendedEvents()[index];
                                return _buildEventCard(event, showRegisterButton: false);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
} 