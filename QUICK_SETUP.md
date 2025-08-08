# 🚀 Quick Environment Setup Guide

This guide will help you quickly set up your environment with the actual IP, API, URL, connection string, email, and password values.

## 📋 Current Working Values

### 🔗 MongoDB Connection (Already Working)
```
MONGO_URL=mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority
```

### 👤 Admin User Credentials
```
ADMIN_USER_ID=22-4957-735
ADMIN_EMAIL=kyleangelocabading@gmail.com
ADMIN_NAME=Kyle Angelo
```

### 📧 Email Configuration
```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=kyleangelocabading@gmail.com
SMTP_PASSWORD=your_gmail_app_password_here
```

## ⚡ Quick Setup (Choose One Method)

### Method 1: Automated Setup (Recommended)

**Windows (PowerShell):**
```powershell
.\scripts\setup_env.ps1 setup
```

**Python (Cross-platform):**
```bash
python scripts/setup_env.py setup
```

### Method 2: Manual Setup

1. **Copy the template:**
   ```bash
   cp env_actual_values.txt .env
   ```

2. **Edit the .env file** and update these values:
   - `SMTP_PASSWORD`: Your Gmail app password
   - `FIREBASE_API_KEY`: Your Firebase API key (removed - using MongoDB notifications)
   - `PUSH_SERVER_KEY`: Your FCM server key (if using push notifications)
   - `GA_TRACKING_ID`: Your Google Analytics tracking ID (if using analytics)

## 🔧 Values You Need to Update

### 1. Gmail App Password
To get your Gmail app password:
1. Go to your Google Account settings
2. Enable 2-factor authentication
3. Generate an app password for "Mail"
4. Replace `your_gmail_app_password_here` with the generated password

### 2. Firebase API Key (Removed)
Firebase has been replaced with MongoDB-based notifications. No external service setup required.

### 3. Push Notification Server Key (Optional)
If you're using Firebase Cloud Messaging:
1. Go to Firebase Console
2. Go to Project Settings > Cloud Messaging
3. Copy the Server key
4. Replace `your_fcm_server_key_here`

### 4. Google Analytics Tracking ID (Optional)
If you're using Google Analytics:
1. Go to Google Analytics
2. Create a new property or use existing
3. Copy the Measurement ID (starts with G-)
4. Replace `G-XXXXXXXXXX`

## 🧪 Test Your Configuration

After setting up, test your configuration:

**Windows:**
```powershell
.\scripts\load_env.ps1 --show-env run
```

**Unix/Mac:**
```bash
./scripts/load_env.sh --show-env run
```

**Python:**
```bash
python scripts/load_env.py --show-env run
```

## 🏃‍♂️ Run the App

**Windows:**
```powershell
.\scripts\load_env.ps1 run
```

**Unix/Mac:**
```bash
./scripts/load_env.sh run
```

**Python:**
```bash
python scripts/load_env.py run
```

## 🔒 Security Checklist

- [ ] `.env` file is in `.gitignore`
- [ ] Gmail app password is set (not regular password)
- [ ] MongoDB notification system is working
- [ ] All sensitive values are masked in logs
- [ ] Different credentials for development/production

## 🆘 Troubleshooting

### MongoDB Connection Issues
- ✅ Current connection string is working
- ✅ Database: `MongoDataBase`
- ✅ Collection: `users`
- ✅ Admin user: `22-4957-735`

### Email Issues
- Check Gmail app password (not regular password)
- Enable "Less secure app access" or use app password
- Verify SMTP settings

### Script Issues
- **Windows**: Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Unix/Mac**: Run `chmod +x scripts/load_env.sh`

## 📞 Support

If you encounter issues:
1. Check the console output for error messages
2. Verify your `.env` file format
3. Ensure all required values are set
4. Test with `--show-env` flag to see loaded values 