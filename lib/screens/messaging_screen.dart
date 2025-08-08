import 'package:flutter/material.dart';
import '../models/user.dart';

class MessagingScreen extends StatelessWidget {
  final User currentUser;
  const MessagingScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messaging'),
      ),
      body: const Center(
        child: Text('Messaging UI goes here.'),
      ),
    );
  }
}
