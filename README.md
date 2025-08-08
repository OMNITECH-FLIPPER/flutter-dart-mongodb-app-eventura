# flutter-dart-mongodb-app-eventura
# Eventura - Complete Event Management App

## 🎉 100% Feature Complete & MongoDB Atlas Connected

Eventura is a comprehensive event management application built with Flutter and Node.js, featuring secure authentication, real-time notifications, QR code scanning, analytics, and full CRUD operations for events and users.

## ✨ Features Implemented

### 🔐 Authentication & Security
- **Secure Password Hashing**: All passwords are hashed using bcrypt
- **Role-based Access Control**: Admin, Organizer, and User roles
- **JWT Token Authentication**: Secure session management
- **Account Blocking/Unblocking**: Admin can manage user accounts

### 📱 User Management
- **User Registration & Login**: Complete user lifecycle management
- **Profile Management**: Users can view and update their profiles
- **Password Reset**: Email-based password reset functionality
- **User Status Management**: Active, blocked, and pending statuses

### 🎪 Event Management
- **Event Creation & Editing**: Full CRUD operations for events
- **Event Registration**: Users can register for events
- **Attendance Tracking**: QR code-based attendance management
- **Event Status Management**: Active, cancelled, completed statuses
- **Event Categories & Filtering**: Organized event browsing

### 📊 Analytics & Reporting
- **Dashboard Analytics**: Real-time statistics and metrics
- **Event Analytics**: Registration and attendance reports
- **User Analytics**: User engagement and activity tracking
- **Export Functionality**: PDF and CSV export capabilities

### 🔔 Notifications & Communication
- **Push Notifications**: Firebase Cloud Messaging integration
- **Email Notifications**: SMTP-based email sending
- **In-app Messaging**: Real-time communication between users
- **Notification Center**: Centralized notification management

### 📷 Media & File Management
- **Image Upload**: Secure image upload and storage
- **Certificate Generation**: Automated certificate creation
- **QR Code Generation**: Dynamic QR codes for events
- **File Download**: Secure file access and download

### 📱 Mobile Features
- **QR Code Scanning**: Camera-based QR code scanning
- **Offline Support**: Basic offline functionality
- **Cross-platform**: iOS, Android, and Web support
- **Responsive Design**: Adaptive UI for all screen sizes

## 🚀 Quick Start

### Prerequisites
- Node.js (v16 or higher)
- Flutter SDK (v3.8 or higher)
- MongoDB Atlas account
- Firebase project (optional, for push notifications)

### 1. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd eventura_app_flutter_code

# Run complete setup
npm run setup
```

### 2. Configure Environment
Update the `.env` file with your configuration:
```env
# MongoDB Configuration
MONGO_URL=mongodb+srv://your-username:your-password@cluster0.xxxxx.mongodb.net/your-database
DB_NAME=your-database-name

# Server Configuration
SERVER_PORT=3000
NODE_ENV=development

# Security
JWT_SECRET=your-secret-key-here
BCRYPT_ROUNDS=10

# Email Configuration (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Firebase Configuration (optional)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

### 3. Firebase Setup (Optional)
For push notifications, update `firebase-service-account.json` with your Firebase credentials.

### 4. Start the Application
```bash
# Start the backend server
npm start

# In a new terminal, start the Flutter app
flutter run
```

### 5. Run Tests
```bash
# Run comprehensive tests
npm run test-full-stack
```

## 📁 Project Structure

```
eventura_app_flutter_code/
├── lib/
│   ├── screens/           # All UI screens
│   ├── services/          # Business logic and API calls
│   ├── models/           # Data models
│   ├── utils/            # Utility functions
│   ├── widgets/          # Reusable UI components
│   └── main.dart         # App entry point
├── server.js             # Backend server
├── package.json          # Backend dependencies
├── pubspec.yaml          # Flutter dependencies
├── test_full_stack.js    # Comprehensive test suite
├── setup_complete.js     # Complete setup script
└── uploads/              # File storage directory
```

## 🔧 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/users` - User registration
- `PUT /api/users/:id` - Update user profile

### Events
- `GET /api/events` - List all events
- `POST /api/events` - Create new event
- `PUT /api/events/:id` - Update event
- `DELETE /api/events/:id` - Delete event
- `POST /api/events/:id/register` - Register for event

### Notifications
- `GET /api/notifications` - Get user notifications
- `POST /api/notifications` - Create notification
- `PUT /api/notifications/:id/read` - Mark as read

### File Management
- `POST /api/upload/image` - Upload image
- `GET /uploads/:filename` - Access uploaded files

## 🧪 Testing

The application includes comprehensive testing:

```bash
# Run all tests
npm run test-full-stack

# Test specific components
npm run test-connection
```

Tests cover:
- ✅ Database connectivity
- ✅ User authentication
- ✅ Event management
- ✅ File uploads
- ✅ Notifications
- ✅ API endpoints

## 🔒 Security Features

- **Password Hashing**: bcrypt with salt rounds
- **CORS Protection**: Configured for secure cross-origin requests
- **Helmet Security**: HTTP headers protection
- **Input Validation**: Server-side validation for all inputs
- **Rate Limiting**: Protection against abuse
- **Environment Variables**: Secure configuration management

## 📊 Database Schema

### Users Collection
```javascript
{
  _id: ObjectId,
  userId: String,
  name: String,
  email: String,
  password: String (hashed),
  role: String (Admin/Organizer/User),
  status: String (active/blocked/pending),
  createdAt: Date,
  updatedAt: Date
}
```

### Events Collection
```javascript
{
  _id: ObjectId,
  title: String,
  description: String,
  date: Date,
  location: String,
  organizerId: String,
  status: String,
  maxParticipants: Number,
  registeredUsers: Array,
  createdAt: Date,
  updatedAt: Date
}
```

### Notifications Collection
```javascript
{
  _id: ObjectId,
  userId: String,
  title: String,
  body: String,
  data: Object,
  read: Boolean,
  createdAt: Date
}
```

## 🚀 Deployment

### Backend Deployment
1. Set up environment variables on your hosting platform
2. Install dependencies: `npm install`
3. Start the server: `npm start`

### Flutter App Deployment
1. Build for target platform:
   ```bash
   # Android
   flutter build apk
   
   # iOS
   flutter build ios
   
   # Web
   flutter build web
   ```
2. Deploy to your chosen platform

## 🐛 Troubleshooting

### Common Issues

1. **MongoDB Connection Failed**
   - Check your connection string in `.env`
   - Ensure your IP is whitelisted in MongoDB Atlas
   - Verify network connectivity

2. **Flutter Dependencies Issues**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check Flutter version compatibility

3. **Push Notifications Not Working**
   - Verify Firebase configuration
   - Check device token registration
   - Ensure FCM is properly initialized

4. **Image Upload Fails**
   - Check uploads directory permissions
   - Verify file size limits
   - Ensure proper file format

## 📞 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the test logs: `npm run test-full-stack`
3. Check server logs for detailed error messages
4. Verify all environment variables are set correctly

## 🎯 Performance Optimization

- **Database Indexing**: Proper indexes on frequently queried fields
- **Caching**: Implement Redis for session caching (optional)
- **CDN**: Use CDN for static file serving
- **Compression**: Enable gzip compression
- **Connection Pooling**: Optimize database connections

## 🔄 Updates and Maintenance

- **Regular Updates**: Keep dependencies updated
- **Security Patches**: Monitor for security vulnerabilities
- **Backup Strategy**: Regular database backups
- **Monitoring**: Implement application monitoring
- **Logging**: Comprehensive error logging

---

## 🎉 Congratulations!

Your Eventura app is now 100% feature complete and connected to MongoDB Atlas Cluster0. All features are implemented, tested, and ready for production use.

**Next Steps:**
1. Customize the UI and branding
2. Add your specific business logic
3. Deploy to your preferred hosting platform
4. Set up monitoring and analytics
5. Train your team on the application

Happy event managing! 🎪✨
