import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventura_app_flutter_code/screens/dashboard_screen.dart';
import 'package:eventura_app_flutter_code/models/user.dart';

void main() {
  testWidgets('DashboardScreen shows user dashboard', (WidgetTester tester) async {
    final user = User(
      name: 'Uma User',
      userId: 'user-1',
      password: 'pw',
      role: 'User',
      age: 22,
      email: 'uma@eventura.com',
      address: 'User Street',
      status: 'active',
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(currentUser: user)));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Uma User!'), findsOneWidget);
    expect(find.text('Event Participant'), findsOneWidget);
    expect(find.text('Browse Events'), findsOneWidget);
    expect(find.text('My Registrations'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows admin dashboard', (WidgetTester tester) async {
    final admin = User(
      name: 'Kyle Angelo',
      userId: '22-4957-735',
      password: 'pw',
      role: 'Admin',
      age: 25,
      email: 'kyle.angelo@eventura.com',
      address: 'Admin Address',
      status: 'active',
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(currentUser: admin)));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Kyle Angelo!'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Manage Users'), findsOneWidget);
    expect(find.text('View Events'), findsOneWidget);
  });

  testWidgets('DashboardScreen shows organizer dashboard', (WidgetTester tester) async {
    final organizer = User(
      name: 'Olivia Organizer',
      userId: 'ORG-001',
      password: 'pw',
      role: 'Organizer',
      age: 30,
      email: 'olivia@eventura.com',
      address: 'Organizer Lane',
      status: 'active',
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(currentUser: organizer)));
    await tester.pumpAndSettle();
    expect(find.text('Welcome, Olivia Organizer!'), findsOneWidget);
    expect(find.text('Event Organizer'), findsOneWidget);
    expect(find.text('Add Event'), findsOneWidget);
    expect(find.text('My Events'), findsOneWidget);
  });
} 