# MongoDB Atlas Connection Setup

## Overview

The Eventura app is configured to connect to MongoDB Atlas for all database operations. The app includes robust fallback mechanisms to ensure all features work regardless of network connectivity.

## Connection Details

### MongoDB Atlas Cluster
- **Cluster**: `cluster0.evanqft.mongodb.net`
- **Database**: `MongoDataBase`
- **Username**: `KyleAngelo`
- **Connection String**: Pre-configured in the app

### Connection String Format
```
mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority
```

## How to Run the App

### Option 1: Using PowerShell Script (Recommended)
```powershell
.\run_app.ps1
```

### Option 2: Using Batch Script
```cmd
run_app.bat
```

### Option 3: Manual Command
```bash
flutter run --dart-define=MONGO_URL="mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority"
```

## Database Features Connected

### ✅ User Management
- User authentication
- User registration
- Role management (Admin, Organizer, User)
- User blocking/unblocking
- User profile updates

### ✅ Event Management
- Event creation
- Event editing
- Event deletion
- Event listing and filtering
- Event details and images

### ✅ Event Registration
- User registration for events
- Registration status tracking
- Attendance confirmation
- Certificate generation (placeholders)

### ✅ Admin Features
- View all users
- Manage user roles
- Block/unblock users
- Delete users
- View all events
- Delete events

### ✅ Organizer Features
- Create events
- Manage own events
- View event registrations
- Confirm attendance
- Generate certificates

### ✅ User Features
- Browse events
- Register for events
- View registration history
- Track attended events

## Connection Status

The app displays real-time connection status:

- **"Connected to MongoDB Atlas"** - Real database operations
- **"Disconnected"** - Using mock data (fallback mode)

## Fallback Mechanism

When MongoDB Atlas is not accessible:
1. App attempts to connect to MongoDB Atlas
2. If connection fails, automatically switches to mock data
3. All features continue to work for testing/demo purposes
4. Clear status indicators show connection state

## Testing Database Connection

Run the database connection test:
```bash
flutter test test/database_connection_test.dart
```

This test validates:
- Database service initialization
- User authentication
- Event retrieval
- Error handling
- Connection status

## Troubleshooting

### Connection Issues
1. **DNS Resolution Error**: Network connectivity issue
   - Solution: App automatically uses mock data
   - Check internet connection
   - Try again later

2. **Authentication Error**: Invalid credentials
   - Solution: Contact administrator for correct credentials

3. **Timeout Error**: Slow network
   - Solution: App will retry with alternative connection method

### Network Issues
- The app is designed to work offline with mock data
- All features remain functional
- Real-time status indicators show connection state

## Security Notes

- Connection string includes credentials (for demo purposes)
- In production, use environment variables
- SSL is enabled for secure connections
- Authentication is required for all operations

## Performance

- Connection pooling for efficient database operations
- Automatic retry mechanisms
- Graceful degradation to mock data
- Real-time connection status monitoring 