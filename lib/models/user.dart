import '../config.dart';

class User {
  final String? id;
  final String name;
  final String userId;
  final String password;
  final String role;
  final int age;
  final String email;
  final String address;
  final String status; // 'active', 'blocked', 'deleted'
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.userId,
    required this.password,
    required this.role,
    required this.age,
    required this.email,
    required this.address,
    String? status,
    DateTime? createdAt,
  }) : status = status ?? 'active',
       createdAt = createdAt ?? DateTime.now();

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id']?.toString(),
      name: map['name'] ?? '',
      userId: map['user_id'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'User',
      age: map['age'] ?? 0,
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'user_id': userId,
      'password': password,
      'role': role,
      'age': age,
      'email': email,
      'address': address,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, userId: $userId, role: $role, status: $status, age: $age, email: $email, address: $address, createdAt: $createdAt)';
  }

  User copyWith({
    String? id,
    String? name,
    String? userId,
    String? password,
    String? role,
    int? age,
    String? email,
    String? address,
    String? status,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      userId: userId ?? this.userId,
      password: password ?? this.password,
      role: role ?? this.role,
      age: age ?? this.age,
      email: email ?? this.email,
      address: address ?? this.address,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper methods
  bool get isActive => status == 'active';
  bool get isBlocked => status == 'blocked';
  bool get isDeleted => status == 'deleted';
  bool get isAdmin => role == Config.roleAdmin;
  bool get isOrganizer => role == Config.roleOrganizer;
  bool get isUser => role == Config.roleUser;
} 