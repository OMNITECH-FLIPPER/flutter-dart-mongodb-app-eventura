import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventura_app_flutter_code/screens/event_list_screen.dart';
import 'package:eventura_app_flutter_code/models/user.dart';
import 'package:eventura_app_flutter_code/models/event.dart';

void main() {
  testWidgets('EventListScreen shows event cards when events exist', (WidgetTester tester) async {
    final user = User(
      name: 'Test',
      userId: 'test',
      password: 'pw',
      role: 'User',
      age: 20,
      email: 'test@example.com',
      address: 'Test Lane',
      status: 'active',
      createdAt: DateTime.now(),
    );
    final events = [
      Event(
        id: '1',
        title: 'Event 1',
        description: 'Desc 1',
        organizerId: 'org',
        organizerName: 'Org',
        imageUrl: '',
        totalSlots: 10,
        availableSlots: 5,
        eventDate: DateTime.now(),
        location: 'Loc',
        status: 'upcoming',
        createdAt: DateTime.now(),
      ),
      Event(
        id: '2',
        title: 'Event 2',
        description: 'Desc 2',
        organizerId: 'org',
        organizerName: 'Org',
        imageUrl: '',
        totalSlots: 20,
        availableSlots: 10,
        eventDate: DateTime.now(),
        location: 'Loc',
        status: 'upcoming',
        createdAt: DateTime.now(),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: EventListScreen(
          currentUser: user,
          eventsProvider: () => events,
        ),
      ),
    );
    // Wait for the async load to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Should show event cards
    expect(find.text('Event 1'), findsOneWidget);
    expect(find.text('Event 2'), findsOneWidget);
    expect(find.byType(Card), findsNWidgets(2));
  });
} 