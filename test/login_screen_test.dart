import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eventura_app_flutter_code/screens/login_screen.dart';

void main() {
  group('LoginScreen Tests', () {
    testWidgets('should show error for blocked user', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      
      // Find form fields
      final userIdField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.byType(ElevatedButton);
      
      // Enter blocked user credentials
      await tester.enterText(userIdField, 'blocked-user');
      await tester.enterText(passwordField, 'password123');
      
      // Tap login button
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Wait for async operations
      
      // Verify error message appears
      expect(find.text('Account is blocked. Please contact administrator.'), findsOneWidget);
    });

    testWidgets('should show error for non-existing account', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      
      // Find form fields
      final userIdField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.byType(ElevatedButton);
      
      // Enter non-existing user credentials
      await tester.enterText(userIdField, 'non-existing-user');
      await tester.enterText(passwordField, 'password123');
      
      // Tap login button
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Wait for async operations
      
      // Verify error message appears
      expect(find.text('Account does not exist. Please check your User ID.'), findsOneWidget);
    });

    testWidgets('should show error for invalid password', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      
      // Find form fields
      final userIdField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      final loginButton = find.byType(ElevatedButton);
      
      // Enter valid user ID but wrong password
      await tester.enterText(userIdField, '22-4957-735');
      await tester.enterText(passwordField, 'wrong-password');
      
      // Tap login button
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Wait for async operations
      
      // Verify error message appears
      expect(find.text('Invalid password. Please try again.'), findsOneWidget);
    });

    testWidgets('should show form validation errors for empty fields', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      
      // Find login button
      final loginButton = find.byType(ElevatedButton);
      
      // Tap login button without entering any data
      await tester.tap(loginButton);
      await tester.pump();
      
      // Verify validation errors appear
      expect(find.text('Please enter your User ID'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('should have proper form structure', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      
      // Verify form elements exist
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('User ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
} 