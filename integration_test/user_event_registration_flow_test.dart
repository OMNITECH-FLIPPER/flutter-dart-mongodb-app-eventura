import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eventura_app_flutter_code/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can register for an event and see registration', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login as seeded user
    await tester.enterText(find.byType(TextFormField).at(0), 'USER-001');
    await tester.enterText(find.byType(TextFormField).at(1), 'user123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Should see dashboard
    expect(find.text('Welcome, Uma User!'), findsOneWidget);
    expect(find.text('Browse Events'), findsOneWidget);

    // Go to event list
    await tester.tap(find.text('Browse Events'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Browse Events'), findsWidgets);

    // Tap the first event card
    final eventCard = find.byType(Card).first;
    await tester.tap(eventCard);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Register for the event (if not already registered)
    final registerButton = find.text('Register for Event');
    if (registerButton.evaluate().isNotEmpty) {
      await tester.tap(registerButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.textContaining('registered for this event'), findsOneWidget);
    } else {
      // Already registered
      expect(find.textContaining('registered for this event'), findsOneWidget);
    }
  });
} 