import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:eventura_app_flutter_code/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can login and navigate to event list', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Enter login credentials
    await tester.enterText(find.byType(TextFormField).at(0), '22-4957-735');
    await tester.enterText(find.byType(TextFormField).at(1), 'KYLO@omni0');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Should see dashboard
    expect(find.text('Welcome, Kyle Angelo!'), findsOneWidget);
    expect(find.text('Eventura'), findsNothing); // No login screen

    // Tap 'Browse Events' (for user role, but admin will see admin dashboard)
    if (find.text('Browse Events').evaluate().isNotEmpty) {
      await tester.tap(find.text('Browse Events'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Browse Events'), findsWidgets);
    }
  });
} 