import 'package:flutter_test/flutter_test.dart';
import 'package:eventura_app_flutter_code/models/user.dart';
import 'package:eventura_app_flutter_code/models/event.dart';
import 'package:eventura_app_flutter_code/models/event_registration.dart';

void main() {
  group('User model', () {
    final userMap = {
      'name': 'Test User',
      'user_id': 'test-001',
      'password': 'pw',
      'role': 'User',
      'age': 20,
      'email': 'test@example.com',
      'address': 'Test Lane',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    };
    test('fromMap/toMap', () {
      final user = User.fromMap(userMap);
      expect(user.name, 'Test User');
      expect(user.toMap()['name'], 'Test User');
    });
    test('copyWith', () {
      final user = User.fromMap(userMap);
      final updated = user.copyWith(name: 'Updated');
      expect(updated.name, 'Updated');
      expect(updated.userId, user.userId);
    });
  });

  group('Event model', () {
    final eventMap = {
      'title': 'Event',
      'description': 'Desc',
      'organizer_id': 'org-1',
      'organizer_name': 'Org',
      'image_url': '',
      'total_slots': 10,
      'available_slots': 5,
      'event_date': DateTime.now().toIso8601String(),
      'location': 'Loc',
      'status': 'upcoming',
      'created_at': DateTime.now().toIso8601String(),
    };
    test('fromMap/toMap', () {
      final event = Event.fromMap(eventMap);
      expect(event.title, 'Event');
      expect(event.toMap()['title'], 'Event');
    });
    test('copyWith', () {
      final event = Event.fromMap(eventMap);
      final updated = event.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.organizerId, event.organizerId);
    });
  });

  group('EventRegistration model', () {
    final regMap = {
      'user_id': 'user-1',
      'user_name': 'User',
      'event_id': 'event-1',
      'event_title': 'Event',
      'registration_date': DateTime.now().toIso8601String(),
      'status': 'registered',
      'is_confirmed': false,
    };
    test('fromMap/toMap', () {
      final reg = EventRegistration.fromMap(regMap);
      expect(reg.userId, 'user-1');
      expect(reg.toMap()['user_id'], 'user-1');
    });
    test('copyWith', () {
      final reg = EventRegistration.fromMap(regMap);
      final updated = reg.copyWith(status: 'attended');
      expect(updated.status, 'attended');
      expect(updated.userId, reg.userId);
    });
  });
} 