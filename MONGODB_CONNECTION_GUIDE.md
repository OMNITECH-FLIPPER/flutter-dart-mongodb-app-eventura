# MongoDB Atlas Connection Troubleshooting Guide

## 🔗 Connection Issues and Solutions

### **Issue 1: DNS Resolution Problems**
**Error**: `Failed host lookup: 'cluster0-shard-00-00.evanqft.mongodb.net'`

**Solutions**:
1. **Check Internet Connection**
   - Ensure you have a stable internet connection
   - Try accessing other websites to verify connectivity

2. **DNS Issues**
   - Try using a different DNS server (8.8.8.8 or 1.1.1.1)
   - Clear DNS cache: `ipconfig /flushdns` (Windows) or `sudo dscacheutil -flushcache` (macOS)

3. **Firewall/Proxy Issues**
   - Check if your firewall is blocking MongoDB connections
   - Configure proxy settings if using corporate network

### **Issue 2: MongoDB Atlas Network Access**
**Error**: `Connection refused` or `Authentication failed`

**Solutions**:
1. **Check MongoDB Atlas Network Access**
   - Go to MongoDB Atlas Dashboard
   - Navigate to Network Access
   - Add your current IP address or use `0.0.0.0/0` (not recommended for production)

2. **Verify Database User**
   - Check Database Access in MongoDB Atlas
   - Ensure user has correct permissions
   - Reset password if needed

### **Issue 3: Connection String Format**
**Error**: `Invalid scheme in uri: mongodb+srv`

**Solutions**:
1. **Use Correct Protocol**
   - `mongo_dart` package only supports `mongodb://` (not `mongodb+srv://`)
   - Use the connection string from MongoDB Atlas "Connect" button

2. **Connection String Format**:
   ```
   mongodb://username:password@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/database?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority
   ```

## 🛠️ Testing Connection

### **Step 1: Test Basic Connectivity**
```bash
# Test DNS resolution
nslookup cluster0-shard-00-00.evanqft.mongodb.net

# Test port connectivity
telnet cluster0-shard-00-00.evanqft.mongodb.net 27017
```

### **Step 2: Test with Dart Script**
```bash
dart test_mongodb_connection.dart
```

### **Step 3: Check MongoDB Atlas Status**
1. Go to [MongoDB Atlas Status Page](https://status.cloud.mongodb.com/)
2. Check if there are any ongoing issues
3. Verify your cluster is running

## 🔧 Development Mode

### **Enable Mock Mode**
If you're having persistent connection issues during development:

```bash
# Run Flutter with mock mode enabled
flutter run --dart-define=USE_MOCK_MODE=true
```

### **Mock Mode Features**
- ✅ All UI functionality works
- ✅ Local data storage
- ✅ Offline capabilities
- ✅ Development and testing

## 📱 Production Deployment

### **Environment Variables**
Set these in your production environment:

```bash
MONGO_URL=your_mongodb_atlas_connection_string
USE_MOCK_MODE=false
```

### **Connection Pooling**
For production, consider:
- Connection pooling settings
- Retry logic
- Health checks
- Monitoring

## 🚨 Emergency Solutions

### **If All Else Fails**:

1. **Use Mock Mode for Development**
   ```bash
   flutter run --dart-define=USE_MOCK_MODE=true
   ```

2. **Check MongoDB Atlas Dashboard**
   - Verify cluster is active
   - Check billing status
   - Review recent changes

3. **Contact Support**
   - MongoDB Atlas support
   - Network administrator
   - ISP support

## 📊 Connection Status Monitoring

The app includes built-in connection monitoring:
- Real-time connection status
- Automatic fallback to mock mode
- Connection retry logic
- Error logging

## 🔄 Automatic Recovery

The app automatically:
- Tries multiple connection methods
- Falls back to mock mode if needed
- Retries connections periodically
- Provides offline functionality

---

**Note**: This guide covers the most common MongoDB Atlas connection issues. If you continue to experience problems, please check the MongoDB Atlas documentation or contact support. 