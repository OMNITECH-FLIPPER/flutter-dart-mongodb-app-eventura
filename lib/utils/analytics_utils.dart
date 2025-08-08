import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AnalyticsUtils {
  /// Get event statistics
  static Future<Map<String, dynamic>> getEventStatistics() async {
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getAllEvents();
      final registrations = await databaseService.getAllRegistrations();
      
      final totalEvents = events.length;
      final upcomingEvents = events.where((e) => e.status == 'upcoming').length;
      final ongoingEvents = events.where((e) => e.status == 'ongoing').length;
      final completedEvents = events.where((e) => e.status == 'completed').length;
      final cancelledEvents = events.where((e) => e.status == 'cancelled').length;
      
      final totalRegistrations = registrations.length;
      final attendedRegistrations = registrations.where((r) => r.isAttended).length;
      final missedRegistrations = registrations.where((r) => r.status == 'missed').length;
      
      final totalSlots = events.fold<int>(0, (sum, event) => sum + event.totalSlots);
      final availableSlots = events.fold<int>(0, (sum, event) => sum + event.availableSlots);
      final occupiedSlots = totalSlots - availableSlots;
      
      return {
        'totalEvents': totalEvents,
        'upcomingEvents': upcomingEvents,
        'ongoingEvents': ongoingEvents,
        'completedEvents': completedEvents,
        'cancelledEvents': cancelledEvents,
        'totalRegistrations': totalRegistrations,
        'attendedRegistrations': attendedRegistrations,
        'missedRegistrations': missedRegistrations,
        'totalSlots': totalSlots,
        'availableSlots': availableSlots,
        'occupiedSlots': occupiedSlots,
        'attendanceRate': totalRegistrations > 0 ? (attendedRegistrations / totalRegistrations * 100) : 0,
        'occupancyRate': totalSlots > 0 ? (occupiedSlots / totalSlots * 100) : 0,
      };
    } catch (e) {
      debugPrint('Error getting event statistics: $e');
      return {};
    }
  }

  /// Get user statistics
  static Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final databaseService = DatabaseService();
      final users = await databaseService.getAllUsers();
      
      final totalUsers = users.length;
      final activeUsers = users.where((u) => u.status == 'active').length;
      final blockedUsers = users.where((u) => u.status == 'blocked').length;
      
      final adminUsers = users.where((u) => u.role == 'Admin').length;
      final organizerUsers = users.where((u) => u.role == 'Organizer').length;
      final regularUsers = users.where((u) => u.role == 'User').length;
      
      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'blockedUsers': blockedUsers,
        'adminUsers': adminUsers,
        'organizerUsers': organizerUsers,
        'regularUsers': regularUsers,
        'activeRate': totalUsers > 0 ? (activeUsers / totalUsers * 100) : 0,
      };
    } catch (e) {
      debugPrint('Error getting user statistics: $e');
      return {};
    }
  }

  /// Get monthly event data for line chart
  static Future<List<FlSpot>> getMonthlyEventData() async {
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getAllEvents();
      final Map<int, int> monthlyData = {};
      
      // Initialize all months with 0
      for (int i = 1; i <= 12; i++) {
        monthlyData[i] = 0;
      }
      
      // Count events by month
      for (final event in events) {
        final month = event.eventDate.month;
        monthlyData[month] = (monthlyData[month] ?? 0) + 1;
      }
      
      // Convert to FlSpot list
      return monthlyData.entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.toDouble());
      }).toList();
    } catch (e) {
      debugPrint('Error getting monthly event data: $e');
      return [];
    }
  }

  /// Get event status distribution for pie chart
  static Future<List<PieChartSectionData>> getEventStatusDistribution() async {
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getAllEvents();
      final Map<String, int> statusCount = {};
      
      for (final event in events) {
        statusCount[event.status] = (statusCount[event.status] ?? 0) + 1;
      }
      
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.red,
        Colors.purple,
      ];
      
      int colorIndex = 0;
      return statusCount.entries.map((entry) {
        final percentage = events.isNotEmpty ? (entry.value / events.length * 100) : 0;
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        
        return PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting event status distribution: $e');
      return [];
    }
  }

  /// Get user role distribution for pie chart
  static Future<List<PieChartSectionData>> getUserRoleDistribution() async {
    try {
      final databaseService = DatabaseService();
      final users = await databaseService.getAllUsers();
      final Map<String, int> roleCount = {};
      
      for (final user in users) {
        roleCount[user.role] = (roleCount[user.role] ?? 0) + 1;
      }
      
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
      ];
      
      int colorIndex = 0;
      return roleCount.entries.map((entry) {
        final percentage = users.isNotEmpty ? (entry.value / users.length * 100) : 0;
        final color = colors[colorIndex % colors.length];
        colorIndex++;
        
        return PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting user role distribution: $e');
      return [];
    }
  }

  /// Get attendance data for bar chart
  static Future<List<BarChartGroupData>> getAttendanceData() async {
    try {
      final databaseService = DatabaseService();
      final registrations = await databaseService.getAllRegistrations();
      
      // Get top 10 events by registration count
      final Map<String, int> eventRegistrations = {};
      final Map<String, int> eventAttendances = {};
      
      for (final registration in registrations) {
        eventRegistrations[registration.eventId] = (eventRegistrations[registration.eventId] ?? 0) + 1;
        if (registration.isAttended) {
          eventAttendances[registration.eventId] = (eventAttendances[registration.eventId] ?? 0) + 1;
        }
      }
      
      // Sort by registration count and take top 10
      final sortedEvents = eventRegistrations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topEvents = sortedEvents.take(10).toList();
      
      return List.generate(topEvents.length, (index) {
        final eventId = topEvents[index].key;
        final registrations = topEvents[index].value;
        final attendances = eventAttendances[eventId] ?? 0;
        
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: registrations.toDouble(),
              color: Colors.blue,
              width: 20,
            ),
            BarChartRodData(
              toY: attendances.toDouble(),
              color: Colors.green,
              width: 20,
            ),
          ],
        );
      });
    } catch (e) {
      debugPrint('Error getting attendance data: $e');
      return [];
    }
  }

  /// Get monthly registration trend
  static Future<List<FlSpot>> getMonthlyRegistrationTrend() async {
    try {
      final databaseService = DatabaseService();
      final registrations = await databaseService.getAllRegistrations();
      final Map<int, int> monthlyData = {};
      
      // Initialize all months with 0
      for (int i = 1; i <= 12; i++) {
        monthlyData[i] = 0;
      }
      
      // Count registrations by month
      for (final registration in registrations) {
        final month = registration.registrationDate.month;
        monthlyData[month] = (monthlyData[month] ?? 0) + 1;
      }
      
      // Convert to FlSpot list
      return monthlyData.entries.map((entry) {
        return FlSpot(entry.key.toDouble(), entry.value.toDouble());
      }).toList();
    } catch (e) {
      debugPrint('Error getting monthly registration trend: $e');
      return [];
    }
  }

  /// Get organizer performance data
  static Future<List<Map<String, dynamic>>> getOrganizerPerformance() async {
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getAllEvents();
      final registrations = await databaseService.getAllRegistrations();
      final users = await databaseService.getAllUsers();
      
      final Map<String, Map<String, dynamic>> organizerStats = {};
      
      for (final event in events) {
        final organizerId = event.organizerId;
        if (!organizerStats.containsKey(organizerId)) {
          final organizer = users.firstWhere(
            (u) => u.userId == organizerId,
            orElse: () => User(
              userId: organizerId,
              password: '',
              role: 'Organizer',
              name: 'Unknown',
              age: 0,
              email: '',
              address: '',
              status: 'active',
            ),
          );
          
          organizerStats[organizerId] = {
            'name': organizer.name,
            'events': 0,
            'totalSlots': 0,
            'occupiedSlots': 0,
            'registrations': 0,
            'attendances': 0,
          };
        }
        
        organizerStats[organizerId]!['events'] = organizerStats[organizerId]!['events'] + 1;
        organizerStats[organizerId]!['totalSlots'] = organizerStats[organizerId]!['totalSlots'] + event.totalSlots;
        organizerStats[organizerId]!['occupiedSlots'] = organizerStats[organizerId]!['occupiedSlots'] + (event.totalSlots - event.availableSlots);
      }
      
      for (final registration in registrations) {
        final event = events.firstWhere(
          (e) => e.id == registration.eventId,
          orElse: () => Event(
            id: registration.eventId,
            title: registration.eventTitle,
            description: '',
            organizerId: '',
            organizerName: '',
            imageUrl: '',
            totalSlots: 0,
            availableSlots: 0,
            eventDate: registration.registrationDate,
            location: '',
            status: '',
          ),
        );
        
        final organizerId = event.organizerId;
        if (organizerStats.containsKey(organizerId)) {
          organizerStats[organizerId]!['registrations'] = organizerStats[organizerId]!['registrations'] + 1;
          if (registration.isAttended) {
            organizerStats[organizerId]!['attendances'] = organizerStats[organizerId]!['attendances'] + 1;
          }
        }
      }
      
      return organizerStats.values.toList();
    } catch (e) {
      debugPrint('Error getting organizer performance: $e');
      return [];
    }
  }

  /// Get recent activity data
  static Future<List<Map<String, dynamic>>> getRecentActivity() async {
    try {
      final databaseService = DatabaseService();
      final events = await databaseService.getAllEvents();
      final registrations = await databaseService.getAllRegistrations();
      final users = await databaseService.getAllUsers();
      
      final List<Map<String, dynamic>> activities = [];
      
      // Add recent events
      final recentEvents = events.take(5).toList();
      for (final event in recentEvents) {
        activities.add({
          'type': 'event_created',
          'title': 'Event Created: ${event.title}',
          'description': 'New event created by ${event.organizerName}',
          'date': event.eventDate,
          'icon': Icons.event,
          'color': Colors.blue,
        });
      }
      
      // Add recent registrations
      final recentRegistrations = registrations.take(5).toList();
      for (final registration in recentRegistrations) {
        final user = users.firstWhere(
          (u) => u.userId == registration.userId,
          orElse: () => User(
            userId: registration.userId,
            password: '',
            role: 'User',
            name: registration.userName,
            age: 0,
            email: '',
            address: '',
            status: 'active',
          ),
        );
        
        activities.add({
          'type': 'registration',
          'title': 'Registration: ${registration.eventTitle}',
          'description': '${user.name} registered for the event',
          'date': registration.registrationDate,
          'icon': Icons.person_add,
          'color': Colors.green,
        });
      }
      
      // Sort by date (most recent first)
      activities.sort((a, b) => b['date'].compareTo(a['date']));
      
      return activities.take(10).toList();
    } catch (e) {
      debugPrint('Error getting recent activity: $e');
      return [];
    }
  }

  /// Format percentage for display
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Format number with commas
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  /// Get color for status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get color for role
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'organizer':
        return Colors.blue;
      case 'user':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 