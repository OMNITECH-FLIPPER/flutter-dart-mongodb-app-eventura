import 'package:flutter_test/flutter_test.dart';
import 'package:eventura_app_flutter_code/services/database_service.dart';
import 'package:eventura_app_flutter_code/models/user.dart';

void main() {
  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() {
      dbService = DatabaseService();
    });

    test('Database service initialization', () async {
      await dbService.initialize();
      // The service should be initialized regardless of connection status
      // Connection status depends on network availability
      expect(dbService.connectionStatus, isA<String>());
      expect(dbService.connectionStatus.isNotEmpty, isTrue);
    });

    test('Get all users returns list', () async {
      await dbService.initialize();
      final users = await dbService.getAllUsers();
      expect(users, isA<List<User>>());
      // Should return mock data even if database is not connected
      expect(users.isNotEmpty, isTrue);
    });

    test('Get all events returns list', () async {
      await dbService.initialize();
      final events = await dbService.getAllEvents();
      expect(events, isA<List>());
      // Should return mock data even if database is not connected
      expect(events.isNotEmpty, isTrue);
    });

    test('Authentication with valid credentials', () async {
      await dbService.initialize();
      final user = await dbService.authenticateUser('22-4957-735', 'KYLO.omni0');
      expect(user, isNotNull);
      expect(user!.role, equals('Admin'));
    });

    test('Authentication with invalid credentials', () async {
      await dbService.initialize();
      final user = await dbService.authenticateUser('invalid', 'invalid');
      expect(user, isNull);
    });

    test('Connection status is correct', () {
      expect(dbService.connectionStatus, isA<String>());
      expect(dbService.connectionStatus.isNotEmpty, isTrue);
    });

    test('Database service is singleton', () {
      final dbService1 = DatabaseService();
      final dbService2 = DatabaseService();
      expect(identical(dbService1, dbService2), isTrue);
    });

    test('Error handling for database operations', () async {
      await dbService.initialize();
      
      // These should not throw exceptions even if database is not connected
      final users = await dbService.getAllUsers();
      final events = await dbService.getAllEvents();
      
      expect(users, isA<List<User>>());
      expect(events, isA<List>());
    });
  });
} 