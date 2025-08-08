import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventura_app_flutter_code/screens/event_list_screen.dart';
import 'package:eventura_app_flutter_code/models/user.dart';
import 'package:eventura_app_flutter_code/models/event.dart';

void main() {
  testWidgets('EventListScreen renders and shows empty state', (WidgetTester tester) async {
    // Use a dummy user for the required argument
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
    await tester.pumpWidget(
      MaterialApp(
        home: EventListScreen(
          currentUser: user,
          eventsProvider: () => <Event>[],
        ),
      ),
    );
    // Should show loading indicator first
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Wait for the async load to complete
    await tester.pumpAndSettle(const Duration(seconds: 2));
    // Should show empty state if no events
    expect(find.text('No events found.'), findsOneWidget);
  });
} 