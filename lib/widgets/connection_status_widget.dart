import 'package:flutter/material.dart';
import '../services/database_service.dart';
// Removed unused import

class ConnectionStatusWidget extends StatelessWidget {
  final DatabaseService dbService;

  const ConnectionStatusWidget({
    super.key,
    required this.dbService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dbService.isConnected ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dbService.isConnected ? Icons.cloud_done : Icons.cloud_off,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            dbService.isConnected ? 'DB' : 'OFF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectionStatusCard extends StatelessWidget {
  final DatabaseService dbService;

  const ConnectionStatusCard({
    super.key,
    required this.dbService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  dbService.isConnected ? Icons.check_circle : Icons.error,
                  color: dbService.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Database Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dbService.connectionStatus,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dbService.isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!dbService.isConnected) ...[
              const SizedBox(height: 8),
              Text(
                'Some features may be limited',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 