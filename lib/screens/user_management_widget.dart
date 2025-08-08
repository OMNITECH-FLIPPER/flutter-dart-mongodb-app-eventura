import 'package:flutter/material.dart';

class UserManagementWidget extends StatelessWidget {
  const UserManagementWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('User Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(height: 8),
            Text('User management UI goes here.'),
          ],
        ),
      ),
    );
  }
}
