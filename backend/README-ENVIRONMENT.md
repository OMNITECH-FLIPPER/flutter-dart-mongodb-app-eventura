# Backend Environment Setup

This guide explains how to set up the required environment variables for the Eventura backend server.

## 🚀 Quick Setup

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Fill in the required values in `.env`:**
   ```bash
   # MongoDB Connection - REQUIRED
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/database
   
   # Server Configuration - REQUIRED  
   PORT=3000
   NODE_ENV=development
   
   # JWT Secret - REQUIRED (use a secure random string, min 32 characters)
   JWT_SECRET=your-super-secure-jwt-secret-key-at-least-32-chars-long
   
   # Email Configuration - REQUIRED (for notifications)
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-app-specific-password
   ```

## 📋 Environment Variables Reference

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MONGODB_URI` | MongoDB connection string | `mongodb+srv://user:pass@cluster.mongodb.net/db` |
| `JWT_SECRET` | Secret key for JWT tokens (min 32 chars) | `super-secure-random-string-at-least-32-characters-long` |
| `EMAIL_USER` | Gmail address for sending notifications | `your-app@gmail.com` |
| `EMAIL_PASS` | Gmail app-specific password | `abcd efgh ijkl mnop` |
| `PORT` | Server port number | `3000` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `NODE_ENV` | Environment mode | `development` |
| `MAX_FILE_SIZE` | Maximum file upload size | `10485760` (10MB) |
| `ALLOWED_FILE_TYPES` | Allowed file extensions | `jpeg,jpg,png,gif,pdf,doc,docx` |
| `CORS_ORIGIN` | CORS allowed origins | `*` |

## 🔐 Security Setup Guide

### 1. MongoDB URI
- Create a MongoDB Atlas account or use local MongoDB
- Create a database user with read/write permissions
- Get the connection string from MongoDB Atlas

### 2. JWT Secret
Generate a secure random string (at least 32 characters):
```bash
# Using Node.js
node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"

# Using OpenSSL (Linux/Mac)
openssl rand -hex 32

# Or use an online generator (ensure it's secure)
```

### 3. Email Configuration
For Gmail app-specific password:
1. Enable 2-factor authentication on your Google account
2. Go to Google Account settings → Security → 2-Step Verification
3. Generate an "App Password" for "Mail"
4. Use this 16-character password (not your regular password)

## ⚡ Environment Validation

The server includes comprehensive environment validation:

- **Startup Check**: Server will not start if required variables are missing
- **Value Validation**: Checks for placeholder values and empty strings
- **Security Validation**: Ensures JWT_SECRET is at least 32 characters
- **Format Validation**: Validates MongoDB URI format

## 🔍 Troubleshooting

### Common Issues

1. **"Environment validation failed"**
   - Ensure all required variables are set in `.env`
   - Check that values don't contain placeholder text

2. **"JWT_SECRET must be at least 32 characters long"**
   - Generate a longer, more secure secret key

3. **"MONGODB_URI must be a valid MongoDB connection string"**
   - Ensure URI starts with `mongodb://` or `mongodb+srv://`

4. **Email sending fails**
   - Verify you're using an app-specific password, not your regular Gmail password
   - Ensure 2-factor authentication is enabled on your Google account

### Testing Your Configuration

1. **Start the server:**
   ```bash
   npm run dev
   ```

2. **Check the health endpoint:**
   ```bash
   curl http://localhost:3000/health
   ```

3. **Verify environment loading:**
   Look for these log messages on startup:
   ```
   ✅ Environment variables validated successfully
   🔧 Running in development mode
   🔗 MongoDB: mongodb+srv://***:***@...
   📧 Email: your-email@gmail.com
   ✅ Connected to MongoDB Atlas
   🚀 Eventura Backend Server running on port 3000
   ```

## 📁 File Security

- `.env` is automatically added to `.gitignore`
- Never commit environment files to version control
- Keep different `.env` files for different environments (dev, staging, production)
- Use environment-specific variable names if needed

## 🚨 Production Notes

For production deployment:
- Use strong, unique secrets
- Set `NODE_ENV=production`
- Use database connection pooling
- Consider using environment variable injection from your hosting platform
- Enable proper logging and monitoring
