# MongoDB Setup Guide for Eventura App

## 🚀 Quick Setup

### 1. Install Dependencies
```bash
npm install
```

### 2. Set Up Environment Configuration
```bash
npm run setup
```

### 3. Configure MongoDB Connection
Edit the `.env` file and replace `<db_password>` with your actual MongoDB password:

```env
MONGO_URL=mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0
```

### 4. Test Connection
```bash
npm run test-connection
```

### 5. Start the Server
```bash
npm start
```

## 🔧 What Was Fixed

### MongoDB Driver Issues
- ✅ MongoDB driver is already installed (`mongodb@^6.18.0`)
- ✅ Updated connection string format to match MongoDB Atlas requirements
- ✅ Fixed inefficient connection management (was calling `connect()` multiple times)
- ✅ Added proper connection pooling and error handling

### Connection String Updates
- ✅ Updated to new format: `mongodb+srv://KyleAngelo:<db_password>@cluster0.evanqft.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0`
- ✅ Added `appName=Cluster0` parameter
- ✅ Removed hardcoded password for security

### Server Improvements
- ✅ Added `connectToDatabase()` function for efficient connection management
- ✅ Updated all API endpoints to use the new connection function
- ✅ Added proper error handling and logging
- ✅ Added connection status monitoring

## 📁 New Files Created

1. **`setup_env.js`** - Automated environment setup script
2. **`test_connection.js`** - MongoDB connection testing script
3. **`MONGODB_SETUP.md`** - This setup guide

## 🔍 Troubleshooting

### Connection Issues
If you get connection errors:

1. **Check your password**: Make sure you've replaced `<db_password>` with your actual password
2. **Network access**: Ensure your IP is whitelisted in MongoDB Atlas
3. **Cluster status**: Verify your MongoDB cluster is running
4. **Connection string**: Double-check the connection string format

### Common Error Messages

**"Authentication failed"**
- Check your username and password
- Verify the user exists in MongoDB Atlas

**"Network timeout"**
- Check your internet connection
- Verify IP whitelist in MongoDB Atlas

**"Invalid connection string"**
- Ensure the connection string format is correct
- Check for special characters in password

## 🛠️ Available Scripts

- `npm start` - Start the production server
- `npm run dev` - Start development server with auto-reload
- `npm run setup` - Set up environment configuration
- `npm run test-connection` - Test MongoDB connection

## 📊 API Endpoints

Once running, your server will be available at `http://localhost:3000`:

- `GET /health` - Health check
- `GET /api` - API information
- `GET /api/users` - Get all users
- `POST /api/users` - Create a new user
- `GET /api/events` - Get all events
- `POST /api/events` - Create a new event
- `GET /api/registrations` - Get all registrations
- `POST /api/registrations` - Create a new registration
- `POST /api/auth/login` - User authentication

## 🔒 Security Notes

- Never commit the `.env` file to version control
- Use strong passwords for MongoDB
- Consider using environment-specific configurations
- Implement proper authentication in production

## 📞 Support

If you encounter issues:
1. Run `npm run test-connection` to diagnose connection problems
2. Check the server logs for detailed error messages
3. Verify your MongoDB Atlas configuration 