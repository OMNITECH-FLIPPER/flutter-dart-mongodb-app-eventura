# Eventura Flutter App - Deployment Tutorial

## Table of Contents
1. [Project Overview](#project-overview)
2. [Hardware Requirements](#hardware-requirements)
3. [Software Requirements](#software-requirements)
4. [Development Environment Setup](#development-environment-setup)
5. [Database Setup](#database-setup)
6. [External Services Configuration](#external-services-configuration)
7. [Local Development Deployment](#local-development-deployment)
8. [Production Deployment Options](#production-deployment-options)
9. [Testing and Quality Assurance](#testing-and-quality-assurance)
10. [Troubleshooting](#troubleshooting)
11. [Maintenance and Updates](#maintenance-and-updates)

## Project Overview

Eventura is a comprehensive event management Flutter application with the following key features:
- **User Management & Authentication**: Multi-role system (Admin, User, Organizer) with secure password hashing
- **Event Management**: Create, edit, delete, and manage events with real-time updates
- **Email Notifications**: SendGrid integration with Gmail SMTP fallback and HTML templates
- **Password Reset System**: JWT-based secure password recovery with email integration
- **Push Notifications**: MongoDB-based notification system with topic subscriptions and offline support
- **Analytics Dashboard**: Real-time event and user statistics with interactive charts
- **Notification Center**: In-app notification management with read/unread status
- **QR Code Generation**: Event registration and check-in with certificate generation
- **Data Export**: CSV export functionality for reports and analytics
- **Offline Support**: Mock mode for development and local data storage
- **Connection Monitoring**: Real-time database connection status with automatic fallback

## Hardware Requirements

### Minimum Requirements (Development)
- **CPU**: Intel Core i3 or AMD equivalent (2.0 GHz or higher)
- **RAM**: 8 GB DDR4
- **Storage**: 20 GB available space (SSD recommended)
- **Display**: 1366x768 resolution minimum
- **Network**: Broadband internet connection

### Recommended Requirements (Development)
- **CPU**: Intel Core i5/i7 or AMD Ryzen 5/7 (3.0 GHz or higher)
- **RAM**: 16 GB DDR4
- **Storage**: 50 GB available space (NVMe SSD recommended)
- **Display**: 1920x1080 resolution or higher
- **Network**: High-speed internet connection (100+ Mbps)

### Production Server Requirements
- **CPU**: 4+ cores (2.0 GHz or higher)
- **RAM**: 8 GB minimum, 16 GB recommended
- **Storage**: 100 GB SSD storage
- **Network**: High-speed internet with static IP
- **Backup**: Automated backup solution

### Mobile Device Requirements (Target)
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **RAM**: 2 GB minimum, 4 GB recommended
- **Storage**: 100 MB available space

## Software Requirements

### Development Environment
- **Operating System**: Windows 10/11, macOS 10.15+, or Ubuntu 18.04+
- **Flutter SDK**: 3.16.0 or higher
- **Dart SDK**: 3.2.0 or higher
- **Android Studio**: 2023.1.1 or higher (for Android development)
- **Xcode**: 14.0+ (for iOS development, macOS only)
- **Git**: 2.30.0 or higher
- **Node.js**: 18.0.0 or higher (for some development tools)

### Database
- **MongoDB**: 6.0 or higher
- **MongoDB Atlas**: Cloud database service (recommended for production)

### External Services
- **SendGrid**: Email service (API key required)
- **MongoDB Atlas**: Cloud database with integrated notification system
- **Gmail SMTP**: Email fallback (app password required)
- **Mock Mode**: Development mode for offline testing

### Development Tools
- **VS Code**: 1.80.0 or higher (recommended editor)
- **Postman**: API testing tool
- **MongoDB Compass**: Database management tool

## Development Environment Setup

### Step 1: Install Flutter SDK

#### Windows
```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install/windows
# Extract to C:\flutter
# Add C:\flutter\bin to PATH environment variable

# Verify installation
flutter doctor
```

#### macOS
```bash
# Using Homebrew
brew install flutter

# Or manual installation
# Download from https://flutter.dev/docs/get-started/install/macos
# Extract to ~/flutter
# Add to PATH in ~/.zshrc or ~/.bash_profile

# Verify installation
flutter doctor
```

#### Linux (Ubuntu)
```bash
# Download Flutter SDK
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz
sudo mv flutter /opt/
echo 'export PATH="$PATH:/opt/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter doctor
```

### Step 2: Install Android Studio (for Android development)

1. Download Android Studio from https://developer.android.com/studio
2. Install with default settings
3. Open Android Studio and complete the setup wizard
4. Install Android SDK (API level 21+)
5. Create an Android Virtual Device (AVD) for testing

### Step 3: Install Xcode (macOS only, for iOS development)

1. Install Xcode from the Mac App Store
2. Open Xcode and accept license agreements
3. Install iOS Simulator
4. Install iOS development tools

### Step 4: Install VS Code and Extensions

1. Download VS Code from https://code.visualstudio.com/
2. Install the following extensions:
   - Flutter
   - Dart
   - Flutter Widget Snippets
   - Dart Import Sorter
   - Error Lens

### Step 5: Clone and Setup Project

```bash
# Clone the repository
git clone <repository-url>
cd eventura_app_flutter_code

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
```

## Database Setup

### Option 1: MongoDB Atlas (Recommended for Production)

1. **Create MongoDB Atlas Account**
   - Go to https://www.mongodb.com/atlas
   - Sign up for a free account
   - Create a new cluster (M0 Free tier is sufficient for development)

2. **Configure Database Access**
   - Go to Database Access
   - Create a new database user with read/write permissions
   - Note down username and password

3. **Configure Network Access**
   - Go to Network Access
   - Add your IP address or use 0.0.0.0/0 for all IPs (not recommended for production)

4. **Get Connection String**
   - Go to Clusters
   - Click "Connect"
   - Choose "Connect your application"
   - Copy the connection string

5. **Update Configuration**
   ```dart
   // In lib/env_config.dart
   static const String mongoUrl = 'your-mongodb-atlas-connection-string';
   ```

### Option 2: Local MongoDB Installation

#### Windows
```bash
# Download MongoDB Community Server from https://www.mongodb.com/try/download/community
# Install with default settings
# MongoDB will run as a Windows service automatically
```

#### macOS
```bash
# Using Homebrew
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb/brew/mongodb-community
```

#### Linux (Ubuntu)
```bash
# Import MongoDB public GPG key
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -

# Create list file for MongoDB
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

# Update package database
sudo apt-get update

# Install MongoDB
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod
```

### Database Initialization

```bash
# Run the seed data script
dart tool/seed_data.dart

# Or manually create admin user
dart lib/utils/admin_setup.dart
```

## External Services Configuration

### SendGrid Email Service

1. **Create SendGrid Account**
   - Go to https://sendgrid.com/
   - Sign up for a free account (100 emails/day free)

2. **Create API Key**
   - Go to Settings > API Keys
   - Create a new API key with "Mail Send" permissions
   - Copy the API key

3. **Update Configuration**
   ```dart
   // In lib/services/email_service.dart
   static const String sendGridApiKey = 'your-sendgrid-api-key';
   static const String fromEmail = 'your-verified-sender@domain.com';
   ```

### MongoDB Atlas Database & Notifications

The application uses MongoDB Atlas as the primary database with integrated notification system:

1. **Database Features**
   - Cloud-hosted MongoDB Atlas cluster
   - Automatic scaling and backup
   - Real-time data synchronization
   - Connection pooling and retry logic

2. **Notification System**
   - Notifications stored in `notifications` collection
   - User-specific and topic-based notifications
   - Read/unread status tracking
   - Real-time polling every 30 seconds
   - Local storage fallback for offline support

3. **Topic Subscriptions**
   - Automatic topic subscription based on user role
   - Support for admin, organizer, and user-specific topics
   - Bulk notification capabilities

4. **Connection Management**
   - Multiple connection methods with automatic fallback
   - Mock mode for development when connection fails
   - Real-time connection status monitoring
   - Automatic recovery and retry logic

5. **Development Support**
   - Mock mode for offline development
   - Local data storage for testing
   - Comprehensive error handling
   - Connection troubleshooting tools

### Gmail SMTP Fallback

1. **Enable 2-Factor Authentication**
   - Go to Google Account settings
   - Enable 2FA on your Gmail account

2. **Generate App Password**
   - Go to Security > App passwords
   - Generate a new app password for "Mail"
   - Copy the 16-character password

3. **Update Configuration**
   ```dart
   // In lib/services/email_service.dart
   static const String smtpUsername = 'your-gmail@gmail.com';
   static const String smtpPassword = 'your-app-password';
   ```

## Local Development Deployment

### Step 1: Environment Configuration

Create a `.env` file in the project root:
```env
# Database
MONGO_URL=your-mongodb-atlas-connection-string
MONGO_DB_NAME=eventura_db

# Email Services
SENDGRID_API_KEY=your-sendgrid-api-key
SMTP_USERNAME=your-gmail@gmail.com
SMTP_PASSWORD=your-app-password

# Development Mode
USE_MOCK_MODE=false

# App Configuration
APP_NAME=Eventura
APP_VERSION=1.0.0
DEBUG_MODE=true
```

### Step 2: Run the Application

```bash
# Check for connected devices
flutter devices

# Run on connected device or emulator
flutter run

# Run in release mode (for testing)
flutter run --release

# Run with specific device
flutter run -d <device-id>

# Run in mock mode (for development without database)
flutter run --dart-define=USE_MOCK_MODE=true
```

### Step 3: Build for Testing

```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build iOS (macOS only)
flutter build ios --release
```

## Production Deployment Options

### Option 1: Google Play Store (Android)

1. **Prepare App for Release**
   ```bash
   # Update version in pubspec.yaml
   version: 1.0.0+1

   # Build release APK
   flutter build appbundle --release
   ```

2. **Create Google Play Console Account**
   - Go to https://play.google.com/console
   - Pay $25 one-time registration fee
   - Complete account setup

3. **Upload App**
   - Create new app in Play Console
   - Upload the generated `.aab` file
   - Fill in app details, screenshots, and description
   - Submit for review

### Option 2: Apple App Store (iOS)

1. **Prepare App for Release**
   ```bash
   # Update version in pubspec.yaml
   version: 1.0.0+1

   # Build iOS app
   flutter build ios --release
   ```

2. **Create Apple Developer Account**
   - Go to https://developer.apple.com/
   - Pay $99/year membership fee
   - Complete account setup

3. **Upload App**
   - Use Xcode to archive the app
   - Upload to App Store Connect
   - Fill in app details and submit for review

### Option 3: Web Deployment

1. **Build Web Version**
   ```bash
   # Enable web support
   flutter config --enable-web

   # Build web app
   flutter build web --release
   ```

2. **Deploy to Web Server**
   - Upload `build/web/` contents to your web server
   - Configure server for single-page application routing
   - Set up HTTPS certificate

### Option 4: Desktop Deployment

1. **Build Desktop App**
   ```bash
   # Enable desktop support
   flutter config --enable-windows-desktop
   flutter config --enable-macos-desktop
   flutter config --enable-linux-desktop

   # Build for specific platform
   flutter build windows --release
   flutter build macos --release
   flutter build linux --release
   ```

2. **Package for Distribution**
   - Windows: Use Inno Setup or NSIS
   - macOS: Create DMG file
   - Linux: Create AppImage or Snap package

## Testing and Quality Assurance

### Unit Testing
```bash
# Run unit tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Integration Testing
```bash
# Run integration tests
flutter test integration_test/
```

### Manual Testing Checklist
- [ ] User registration and login
- [ ] Password reset functionality
- [ ] Email notifications
- [ ] Push notifications
- [ ] Event creation and management
- [ ] User role management
- [ ] Analytics dashboard
- [ ] QR code generation and scanning
- [ ] Data export functionality
- [ ] Cross-platform compatibility

### Performance Testing
```bash
# Run performance profiling
flutter run --profile

# Analyze performance
flutter run --trace-startup
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Flutter Doctor Issues
```bash
# Update Flutter
flutter upgrade

# Clean and rebuild
flutter clean
flutter pub get
```

#### 2. Database Connection Issues
- Verify MongoDB is running
- Check connection string format
- Ensure network access is configured
- Test connection with MongoDB Compass

#### 3. Email Service Issues
- Verify SendGrid API key
- Check Gmail app password
- Test SMTP connection
- Review email templates

#### 4. MongoDB Connection Issues
- Check MongoDB Atlas cluster status
- Verify network access settings
- Test connection with provided script
- Use mock mode for development
- Review connection troubleshooting guide

#### 5. Build Issues
```bash
# Clean build cache
flutter clean
flutter pub get

# Update dependencies
flutter pub upgrade

# Check for conflicts
flutter pub deps
```

### Debug Mode
```bash
# Run in debug mode with verbose logging
flutter run --verbose

# Enable debug prints
flutter run --debug

# Test MongoDB connection
dart test_mongodb_connection.dart

# Run with mock mode for development
flutter run --dart-define=USE_MOCK_MODE=true
```

## Maintenance and Updates

### Regular Maintenance Tasks

1. **Dependency Updates**
   ```bash
   # Check for outdated packages
   flutter pub outdated

   # Update dependencies
   flutter pub upgrade
   ```

2. **Database Maintenance**
   - Monitor database performance
   - Clean up expired tokens
   - Backup data regularly
   - Optimize queries

3. **Security Updates**
   - Keep Flutter SDK updated
   - Monitor security advisories
   - Update API keys regularly
   - Review access permissions

### Monitoring and Analytics

1. **App Performance**
   - Monitor crash reports
   - Track user engagement
   - Analyze performance metrics
   - Review user feedback

2. **Server Monitoring**
   - Monitor database performance
   - Track API response times
   - Monitor email delivery rates
   - Check push notification delivery

### Backup Strategy

1. **Database Backups**
   - Automated daily backups
   - Point-in-time recovery
   - Cross-region replication
   - Regular backup testing

2. **Code Backups**
   - Version control (Git)
   - Regular commits
   - Tagged releases
   - Documentation updates

## Conclusion

This deployment tutorial provides a comprehensive guide for setting up and deploying the Eventura Flutter application. The application is designed to be scalable, secure, and maintainable, with support for multiple deployment options and external service integrations.

For additional support or questions, refer to:
- Flutter Documentation: https://flutter.dev/docs
- MongoDB Documentation: https://docs.mongodb.com/
- SendGrid Documentation: https://sendgrid.com/docs/
- MongoDB Documentation: https://docs.mongodb.com/

---

**Note**: This tutorial assumes you have basic knowledge of Flutter development, database management, and cloud services. For production deployments, consider consulting with experienced DevOps professionals or cloud service providers. 