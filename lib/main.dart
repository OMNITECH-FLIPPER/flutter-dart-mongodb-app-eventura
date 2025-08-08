import 'package:flutter/material.dart';
import 'mongodb.dart';
import 'config.dart';
import 'env_config.dart';
import 'services/database_service.dart';
import 'services/mongodb_notification_service.dart';
import 'screens/introduction_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'utils/admin_setup.dart';
import 'screens/profile_screen.dart';
import 'models/user.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Validate environment configuration
  try {
    EnvConfig.validateConfig();
    EnvConfig.printConfig();
  } catch (e) {
    debugPrint('Configuration validation failed: $e');
    // Continue with app startup even if validation fails
  }
  
  // Initialize database service
  final dbService = DatabaseService();
  await dbService.initialize();
  
  // Initialize MongoDB notification service
  await MongoDBNotificationService.initialize();
  
  // Test database connection
  final isConnected = await dbService.testConnection();
  debugPrint('Database connection test: ${isConnected ? 'SUCCESS' : 'FAILED'}');
  
  // Initialize admin setup if connected
  if (isConnected && EnvConfig.shouldConnectToDatabase) {
    try {
      await AdminSetup.ensureAdminUserExists();
      await AdminSetup.testAdminAuthentication();
      await AdminSetup.listAllUsers();
    } catch (e) {
      debugPrint('Admin setup failed: $e');
    }
  }
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventura - Event Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Config.primaryColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        primaryColor: Config.primaryColor,
        scaffoldBackgroundColor: Config.secondaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Config.primaryColor,
          foregroundColor: Config.secondaryColor,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Config.primaryColor,
            foregroundColor: Config.secondaryColor,
          ),
        ),
        cardTheme: CardThemeData(
          color: Config.secondaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const IntroductionScreen(),
        Config.loginRoute: (context) => const LoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        Config.homeRoute: (context) => const MyHomePage(title: 'Eventura - Event Management'),
        Config.userManagementRoute: (context) => const UserManagementScreen(),
        '/profile': (context) {
          final user = ModalRoute.of(context)!.settings.arguments as User;
          return ProfileScreen(user: user);
        },
        '/qr-scanner': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return QRScannerScreen(
            currentUser: args['currentUser'] as User,
            eventId: args['eventId'] as String?,
          );
        },
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isConnected = false;
  String _connectionStatus = 'Checking connection...';

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  void _checkConnection() async {
    setState(() {
      _connectionStatus = 'Checking connection...';
    });
    
    try {
      await MongoDataBase.connect();
      setState(() {
        _isConnected = MongoDataBase.isConnected;
        _connectionStatus = _isConnected 
            ? 'Connected to MongoDB' 
            : 'Failed to connect';
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Connection error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _checkConnection,
            tooltip: 'Refresh connection',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Database Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Database Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_connectionStatus),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Welcome Section
            Text(
              'Welcome to Eventura',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your comprehensive event management solution',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildActionCard(
                    context,
                    'Create Event',
                    Icons.event,
                    Colors.blue,
                    () => _showComingSoon(context, 'Create Event'),
                  ),
                  _buildActionCard(
                    context,
                    'View Events',
                    Icons.list,
                    Colors.green,
                    () => _showComingSoon(context, 'View Events'),
                  ),
                  _buildActionCard(
                    context,
                    'Manage Users',
                    Icons.people,
                    Colors.orange,
                    () => Navigator.of(context).pushNamed('/users'),
                  ),
                  _buildActionCard(
                    context,
                    'Analytics',
                    Icons.analytics,
                    Colors.purple,
                    () => _showComingSoon(context, 'Analytics'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, 
      Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
