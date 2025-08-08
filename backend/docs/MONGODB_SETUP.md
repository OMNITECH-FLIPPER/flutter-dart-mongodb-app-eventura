# MongoDB Atlas Setup Guide

This guide walks you through setting up MongoDB Atlas for the Eventura application.

## Step 1: MongoDB Atlas Configuration

### 1.1 Whitelist IP Addresses

**Option A: Allow All IPs (Temporary for Development)**
1. Go to your MongoDB Atlas dashboard
2. Navigate to **Security** → **Network Access**
3. Click **Add IP Address**
4. Select **Allow Access from Anywhere** (0.0.0.0/0)
5. Click **Confirm**

**Option B: Whitelist Current IP (Recommended)**
1. Get your current IP address
2. In Atlas, go to **Security** → **Network Access**
3. Click **Add IP Address**
4. Select **Add Current IP Address**
5. Click **Confirm**

### 1.2 Database User Setup

1. Navigate to **Security** → **Database Access**
2. Click **Add New Database User**
3. Choose **Password** authentication
4. Set username and password (save these for your .env file)
5. Under **Database User Privileges**, select:
   - **Built-in Role**: `Read and write to any database`
6. Click **Add User**

### 1.3 Get Connection String

1. Go to **Deployment** → **Database**
2. Click **Connect** on your cluster
3. Choose **Connect your application**
4. Select **Node.js** and version **4.1 or later**
5. Copy the connection string
6. Replace `<password>` with your database user password
7. Replace `<database>` with your database name (e.g., `MongoDataBase`)

Example connection string format:
```
mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/MongoDataBase?retryWrites=true&w=majority
```

## Step 2: Environment Configuration

### 2.1 Update .env File

1. Open the `.env` file in the backend directory
2. Update the following variables:

```env
# MongoDB Connection - REQUIRED
MONGODB_URI=mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/MongoDataBase?retryWrites=true&w=majority

# JWT Secret - REQUIRED (generate a secure 32+ character string)
JWT_SECRET=your-super-secret-jwt-key-at-least-32-characters-long

# Email Configuration - REQUIRED (for notifications)
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-specific-password
```

### 2.2 Generate Secure JWT Secret

Generate a secure JWT secret using one of these methods:

**Option 1: Node.js**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

**Option 2: OpenSSL**
```bash
openssl rand -hex 32
```

**Option 3: Online Generator**
Use a secure online generator like: https://randomkeygen.com/

## Step 3: Test Connection

### 3.1 Using the Test Script

```bash
# Run the connection test
node scripts/test-connection.js
```

### 3.2 Expected Output

```
🔍 MongoDB Connection Test Started...
🔗 Attempting to connect to: mongodb+srv://***:***@cluster0.xxxxx.mongodb.net/MongoDataBase
✅ Successfully connected to MongoDB
✅ Ping test successful: { ok: 1 }
📊 Database Info:
   - MongoDB Version: 6.0.x
   - Database: MongoDataBase
   - Host: xxxxx
   - Collections: 0
✅ MongoDB connection test completed successfully!
🔌 Disconnected from MongoDB
```

### 3.3 Manual Connection Test (Alternative)

If you have MongoDB shell installed, you can test with:

```bash
# For mongosh (newer)
mongosh "mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/MongoDataBase" --eval "db.runCommand({ping:1})"

# For mongo (legacy)
mongo "mongodb+srv://username:password@cluster0.xxxxx.mongodb.net/MongoDataBase" --eval "db.runCommand({ping:1})"
```

## Step 4: Seed Database

### 4.1 Run the Seeder

```bash
npm run seed
```

### 4.2 Expected Output

```
🚀 Eventura Database Seeder Starting...
🔗 Connecting to: mongodb+srv://***:***@cluster0.xxxxx.mongodb.net/MongoDataBase
🔗 Attempting MongoDB connection (attempt 1/5)...
✅ Connected to MongoDB Atlas
✅ MongoDB connection test successful: { ok: 1 }
🌱 Starting database seeding...
🧹 Clearing existing data...
✅ Existing data cleared
👥 Seeding users...
✅ Created 4 users:
   - Admin: System Administrator (admin001)
   - Organizer: Sarah Johnson (org001)
   - Organizer: Michael Chen (org002)
   - User: Jane Doe (user001)
📅 Seeding events...
✅ Created 4 events:
   - "Tech Innovation Summit 2024" by Sarah Johnson
   - "Digital Marketing Workshop" by Michael Chen
   - "Startup Pitch Competition" by Sarah Johnson
   - "AI & Machine Learning Conference" by Michael Chen
🎉 Database seeding completed successfully!

📊 Database Summary:
   Total Users: 4
   - Admins: 1
   - Organizers: 2
   - Users: 1
   Total Events: 4

🔐 Default Login Credentials:
   Admin: admin001 / AdminPass123!
   Organizer 1: org001 / OrgPass123!
   Organizer 2: org002 / OrgPass123!
   User: user001 / UserPass123!

✅ Seeding process completed successfully!
🔌 Disconnected from MongoDB
```

## Step 5: Start the Server

### 5.1 Development Mode

```bash
npm run dev
```

### 5.2 Production Mode

```bash
npm start
```

### 5.3 Expected Server Output

```
✅ Environment variables validated successfully
🔧 Running in development mode
🔗 MongoDB: mongodb+srv://***:***@cluster0.xxxxx.mongodb.net/MongoDataBase
📧 Email: your-email@gmail.com
🔗 Attempting MongoDB connection (attempt 1/5)...
✅ Connected to MongoDB Atlas
✅ MongoDB connection test successful
🟢 Mongoose connected to MongoDB
🚀 Eventura Backend Server running on port 3000
📊 Health check: http://localhost:3000/health
🔗 API Base URL: http://localhost:3000/api
```

## Troubleshooting

### Common Issues

1. **Authentication Failed**
   - Verify username/password in connection string
   - Check database user permissions

2. **Network Timeout**
   - Confirm IP address is whitelisted
   - Check internet connection

3. **Connection String Format**
   - Ensure special characters in password are URL encoded
   - Verify database name is correct

4. **Environment Variables**
   - Ensure .env file is in the correct directory
   - Check for typos in variable names

### Health Check

Test if the server and database are running:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-XX-XXXXX",
  "mongodb": "connected"
}
```

## Security Notes

- **Never commit .env files to version control**
- **Use strong passwords for database users**
- **Regularly rotate JWT secrets in production**
- **Remove 0.0.0.0/0 IP whitelist in production**
- **Use specific IP addresses or VPN for production access**
