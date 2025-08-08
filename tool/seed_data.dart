import 'package:mongo_dart/mongo_dart.dart';

Future<void> main() async {
  final db = await Db.create('mongodb+srv://KyleAngelo:KYLO%40omni0@cluster0.evanqft.mongodb.net/MongoDataBase');
  await db.open();
  // print('Connected to MongoDB');

  final users = db.collection('users');
  final events = db.collection('events');
  final registrations = db.collection('event_registrations');

  // Clear existing data
  await users.deleteMany({});
  await events.deleteMany({});
  await registrations.deleteMany({});

  // Insert sample users
  final adminId = '22-4957-735';
  final organizerId = 'ORG-001';
  final userId = 'USER-001';
  await users.insertMany([
    {
      'name': 'Kyle Angelo',
      'user_id': adminId,
      'password': 'KYLO@omni0',
      'role': 'Admin',
      'age': 25,
      'email': 'kyle.angelo@eventura.com',
      'address': 'Admin Address',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Olivia Organizer',
      'user_id': organizerId,
      'password': 'organizer123',
      'role': 'Organizer',
      'age': 30,
      'email': 'olivia@eventura.com',
      'address': 'Organizer Lane',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
    {
      'name': 'Uma User',
      'user_id': userId,
      'password': 'user123',
      'role': 'User',
      'age': 22,
      'email': 'uma@eventura.com',
      'address': 'User Street',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
  ]);

  // Insert sample events
  final event1Id = ObjectId();
  final event2Id = ObjectId();
  await events.insertMany([
    {
      '_id': event1Id,
      'title': 'Flutter Workshop',
      'description': 'A hands-on workshop for Flutter beginners.',
      'organizer_id': organizerId,
      'organizer_name': 'Olivia Organizer',
      'image_url': '',
      'total_slots': 50,
      'available_slots': 48,
      'event_date': DateTime.now().add(Duration(days: 7)),
      'location': 'Online',
      'status': 'upcoming',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
    {
      '_id': event2Id,
      'title': 'Networking Night',
      'description': 'Meet and connect with tech professionals.',
      'organizer_id': organizerId,
      'organizer_name': 'Olivia Organizer',
      'image_url': '',
      'total_slots': 100,
      'available_slots': 99,
      'event_date': DateTime.now().add(Duration(days: 14)),
      'location': 'Tech Hub',
      'status': 'upcoming',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
  ]);

  // Insert sample registrations
  await registrations.insertMany([
    {
      'user_id': userId,
      'user_name': 'Uma User',
      'event_id': event1Id.oid,
      'event_title': 'Flutter Workshop',
      'registration_date': DateTime.now().toIso8601String(),
      'status': 'registered',
      'is_confirmed': false,
    },
    {
      'user_id': userId,
      'user_name': 'Uma User',
      'event_id': event2Id.oid,
      'event_title': 'Networking Night',
      'registration_date': DateTime.now().toIso8601String(),
      'status': 'registered',
      'is_confirmed': false,
    },
  ]);

  // print('Sample data seeded!');
  await db.close();
} 