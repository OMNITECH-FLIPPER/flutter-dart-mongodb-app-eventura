const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

// Auth middleware implemented inline for simplicity

// Load and validate environment variables using dotenv-safe
try {
  require('dotenv-safe').config({
    path: path.join(__dirname, '.env'),
    example: path.join(__dirname, '.env.example'),
    allowEmptyValues: false
  });
} catch (error) {
  console.error('❌ Environment validation failed:', error.message);
  console.error('\n📝 Required environment variables:');
  console.error('   - MONGODB_URI: MongoDB connection string');
  console.error('   - JWT_SECRET: Secure random string for JWT signing');
  console.error('   - EMAIL_USER: Email address for sending notifications');
  console.error('   - EMAIL_PASS: Email app-specific password');
  console.error('   - PORT: Server port (defaults to 3000)');
  console.error('\n💡 Copy .env.example to .env and fill in the required values.');
  process.exit(1);
}

// Additional validation for critical environment variables
const requiredEnvVars = {
  MONGODB_URI: 'MongoDB connection string',
  JWT_SECRET: 'JWT secret key',
  EMAIL_USER: 'Email user for notifications',
  EMAIL_PASS: 'Email password for notifications'
};

const missingVars = [];
const emptyVars = [];

Object.entries(requiredEnvVars).forEach(([key, description]) => {
  if (!process.env[key]) {
    missingVars.push(`${key} (${description})`);
  } else if (process.env[key].trim() === '' || process.env[key].includes('your-') || process.env[key].includes('change-this')) {
    emptyVars.push(`${key} (${description})`);
  }
});

if (missingVars.length > 0 || emptyVars.length > 0) {
  console.error('❌ Environment configuration errors detected:');
  
  if (missingVars.length > 0) {
    console.error('\n🚫 Missing required environment variables:');
    missingVars.forEach(varInfo => console.error(`   - ${varInfo}`));
  }
  
  if (emptyVars.length > 0) {
    console.error('\n⚠️  Environment variables with placeholder/empty values:');
    emptyVars.forEach(varInfo => console.error(`   - ${varInfo}`));
  }
  
  console.error('\n💡 Please update your .env file with proper values before starting the server.');
  process.exit(1);
}

// Validate JWT secret strength
if (process.env.JWT_SECRET.length < 32) {
  console.error('❌ JWT_SECRET must be at least 32 characters long for security.');
  process.exit(1);
}

// Validate MongoDB URI format
if (!process.env.MONGODB_URI.startsWith('mongodb://') && !process.env.MONGODB_URI.startsWith('mongodb+srv://')) {
  console.error('❌ MONGODB_URI must be a valid MongoDB connection string.');
  process.exit(1);
}

console.log('✅ Environment variables validated successfully');
console.log(`🔧 Running in ${process.env.NODE_ENV || 'development'} mode`);
console.log(`🔗 MongoDB: ${process.env.MONGODB_URI.replace(/:\/\/.*@/, '://***:***@')}`);
console.log(`📧 Email: ${process.env.EMAIL_USER}`);
console.log(`🛡️  Security configuration:`);
console.log(`   - CORS Origins: ${process.env.CORS_ORIGIN || '*'}`);
console.log(`   - Rate Limit: ${parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100} requests per ${(parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000) / 60000} minutes`);
console.log(`   - HTTPS Redirect: ${process.env.NODE_ENV === 'production' ? 'enabled' : 'disabled'}`);
console.log(`   - Security Headers: enabled (Helmet)`);
console.log(`   - Input Sanitization: enabled (XSS + NoSQL injection protection)`);

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy in production for HTTPS enforcement
if (process.env.NODE_ENV === 'production') {
  app.enable('trust proxy');
}

// Security middleware (order matters)
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'"],
      fontSrc: ["'self'"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: false
}));

// Compression middleware
app.use(compression());

// Rate limiting middleware
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes default
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
app.use(limiter);

// CORS configuration from environment
const corsOrigin = process.env.CORS_ORIGIN || '*';
const corsOptions = {
  origin: corsOrigin === '*' ? true : corsOrigin.split(','),
  credentials: true,
  optionsSuccessStatus: 200
};
app.use(cors(corsOptions));

// Input sanitization middleware
app.use(mongoSanitize()); // Prevent NoSQL injection attacks
app.use(express.json({ 
  limit: '10mb',
  verify: (req, res, buf, encoding) => {
    // Store raw body for webhook verification if needed
    req.rawBody = buf;
  }
}));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// XSS sanitization middleware
app.use((req, res, next) => {
  // Sanitize req.body
  if (req.body && typeof req.body === 'object') {
    req.body = sanitizeObject(req.body);
  }
  
  // Sanitize req.query
  if (req.query && typeof req.query === 'object') {
    req.query = sanitizeObject(req.query);
  }
  
  // Sanitize req.params
  if (req.params && typeof req.params === 'object') {
    req.params = sanitizeObject(req.params);
  }
  
  next();
});

// Static files with security headers
app.use('/uploads', express.static('uploads', {
  setHeaders: (res, path) => {
    // Set security headers for static files
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('Cache-Control', 'public, max-age=31536000');
  }
}));

// Force HTTPS in production
app.use((req, res, next) => {
  if (process.env.NODE_ENV === 'production' && !req.secure && req.get('x-forwarded-proto') !== 'https') {
    return res.redirect(301, `https://${req.get('host')}${req.url}`);
  }
  next();
});

// Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
const imagesDir = path.join(uploadsDir, 'images');
const certificatesDir = path.join(uploadsDir, 'certificates');

[uploadsDir, imagesDir, certificatesDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

// Multer configuration
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    const isImage = file.fieldname === 'image';
    cb(null, isImage ? imagesDir : certificatesDir);
  },
  filename: function (req, file, cb) {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB limit
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

// MongoDB Connection with Retry Logic
async function connectWithRetry(maxRetries = 5) {
  let retries = 0;
  
  while (retries < maxRetries) {
    try {
      console.log(`🔗 Attempting MongoDB connection (attempt ${retries + 1}/${maxRetries})...`);
      
      await mongoose.connect(process.env.MONGODB_URI, {
        serverSelectionTimeoutMS: 10000,
        socketTimeoutMS: 45000,
        maxPoolSize: 10,
        minPoolSize: 5,
        maxIdleTimeMS: 30000
      });
      
      console.log('✅ Connected to MongoDB Atlas');
      
      // Test the connection
      await mongoose.connection.db.admin().ping();
      console.log('✅ MongoDB connection test successful');
      
      return;
    } catch (error) {
      retries++;
      console.error(`❌ MongoDB connection attempt ${retries} failed:`, error.message);
      
      // Close any existing connections on failure
      try {
        await mongoose.disconnect();
      } catch (disconnectError) {
        // Ignore disconnect errors
      }
      
      if (retries < maxRetries) {
        // Exponential backoff with jitter: base delay * 2^retries + random jitter
        const baseDelay = 1000;
        const exponentialDelay = baseDelay * Math.pow(2, retries - 1);
        const jitter = Math.random() * 1000;
        const delay = Math.min(exponentialDelay + jitter, 30000); // Max 30 seconds
        
        console.log(`⏳ Waiting ${Math.round(delay)}ms before retry...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        console.error(`💥 Failed to connect to MongoDB after ${maxRetries} attempts`);
        throw new Error(`MongoDB connection failed after ${maxRetries} attempts: ${error.message}`);
      }
    }
  }
}

// Handle connection events
mongoose.connection.on('connected', () => {
  console.log('🟢 Mongoose connected to MongoDB');
});

mongoose.connection.on('error', (err) => {
  console.error('🔴 Mongoose connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('🟡 Mongoose disconnected from MongoDB');
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Received SIGINT, closing MongoDB connection...');
  try {
    await mongoose.connection.close();
    console.log('✅ MongoDB connection closed');
  } catch (error) {
    console.error('❌ Error closing MongoDB connection:', error);
  }
  process.exit(0);
});

// Initialize connection
connectWithRetry().catch(err => {
  console.error('💥 Critical error: Could not establish MongoDB connection');
  console.error('Error details:', err.message);
  process.exit(1);
});

// Schemas
const userSchema = new mongoose.Schema({
  userId: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['User', 'Organizer', 'Admin'], default: 'User' },
  age: { type: Number, required: true },
  address: { type: String, required: true },
  status: { type: String, enum: ['active', 'blocked'], default: 'active' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const eventSchema = new mongoose.Schema({
  title: { type: String, required: true },
  description: { type: String, required: true },
  eventDate: { type: Date, required: true },
  location: { type: String, required: true },
  organizerId: { type: String, required: true },
  organizerName: { type: String, required: true },
  totalSlots: { type: Number, required: true },
  availableSlots: { type: Number, required: true },
  status: { type: String, enum: ['upcoming', 'ongoing', 'completed', 'cancelled'], default: 'upcoming' },
  imageUrl: { type: String, default: '' },
  pendingApproval: { type: Boolean, default: false },
  lastEditedBy: { type: String, default: null },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const registrationSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  userName: { type: String, required: true },
  userEmail: { type: String, required: true },
  eventId: { type: String, required: true },
  eventTitle: { type: String, required: true },
  registrationDate: { type: Date, default: Date.now },
  isConfirmed: { type: Boolean, default: true },
  isAttended: { type: Boolean, default: false },
  attendanceDate: { type: Date, default: null },
  certificateUrl: { type: String, default: null },
  status: { type: String, enum: ['registered', 'attended', 'missed'], default: 'registered' },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

const notificationSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  data: { type: mongoose.Schema.Types.Mixed, default: {} },
  read: { type: Boolean, default: false },
  timestamp: { type: Date, default: Date.now },
  createdAt: { type: Date, default: Date.now }
});

// Models
const User = mongoose.model('User', userSchema);
const Event = mongoose.model('Event', eventSchema);
const Registration = mongoose.model('Registration', registrationSchema);
const Notification = mongoose.model('Notification', notificationSchema);

// Email configuration
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// JWT Secret
const JWT_SECRET = process.env.JWT_SECRET;

// XSS sanitization helper function
function sanitizeObject(obj) {
  if (obj && typeof obj === 'object') {
    if (Array.isArray(obj)) {
      return obj.map(item => sanitizeObject(item));
    } else {
      const sanitized = {};
      for (const [key, value] of Object.entries(obj)) {
        if (typeof value === 'string') {
          sanitized[key] = xss(value);
        } else if (value && typeof value === 'object') {
          sanitized[key] = sanitizeObject(value);
        } else {
          sanitized[key] = value;
        }
      }
      return sanitized;
    }
  }
  return typeof obj === 'string' ? xss(obj) : obj;
}

// Authentication middleware is imported from middlewares/auth.js

// Routes

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected'
  });
});

// Authentication Routes
app.post('/api/auth/login', async (req, res) => {
  try {
    const { userId, password } = req.body;
    
    const user = await User.findOne({ $or: [{ userId }, { user_id: userId }] });
    if (!user) {
      return res.status(400).json({ success: false, message: 'User not found' });
    }

    if (user.status === 'blocked') {
      return res.status(400).json({ success: false, message: 'Account is blocked' });
    }

    // Hash the input password using the same method as Flutter app (SHA-256)
    const crypto = require('crypto');
    const hashedInputPassword = crypto.createHash('sha256').update(password).digest('hex');
    
    // Compare hashed passwords
    const isValidPassword = hashedInputPassword === user.password;
    
    if (!isValidPassword) {
      return res.status(400).json({ success: false, message: 'Invalid password' });
    }

    const token = jwt.sign(
      { userId: user.userId, role: user.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      success: true,
      token,
      user: {
        userId: user.userId,
        name: user.name,
        email: user.email,
        role: user.role,
        status: user.status
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

// User Routes
app.get('/api/users', async (req, res) => {
  try {
    const users = await User.find({}, { password: 0 }).sort({ createdAt: -1 });
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/users/:userId', async (req, res) => {
  try {
    const user = await User.findOne({ $or: [{ userId: req.params.userId }, { user_id: req.params.userId }] }, { password: 0 });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    res.json(user);
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const userData = req.body;
    
    // Check if user already exists
    const existingUser = await User.findOne({ 
      $or: [{ userId: userData.userId }, { email: userData.email }] 
    });
    
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const user = new User(userData);
    await user.save();
    
    const { password, ...userResponse } = user.toObject();
    res.status(201).json(userResponse);
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.put('/api/users/:userId', async (req, res) => {
  try {
    const updates = { ...req.body, updatedAt: new Date() };
    const user = await User.findOneAndUpdate(
      { $or: [{ userId: req.params.userId }, { user_id: req.params.userId }] },
      updates,
      { new: true, select: { password: 0 } }
    );
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.delete('/api/users/:userId', async (req, res) => {
  try {
    const user = await User.findOneAndDelete({ $or: [{ userId: req.params.userId }, { user_id: req.params.userId }] });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({ message: 'User deleted successfully' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Event Routes
app.get('/api/events', async (req, res) => {
  try {
    const events = await Event.find({}).sort({ createdAt: -1 });
    res.json(events);
  } catch (error) {
    console.error('Get events error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/events/:eventId', async (req, res) => {
  try {
    const event = await Event.findById(req.params.eventId);
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    res.json(event);
  } catch (error) {
    console.error('Get event error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/events/organizer/:organizerId', async (req, res) => {
  try {
    const events = await Event.find({ organizerId: req.params.organizerId }).sort({ createdAt: -1 });
    res.json(events);
  } catch (error) {
    console.error('Get events by organizer error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/events', async (req, res) => {
  try {
    const eventData = req.body;
    eventData.id = new mongoose.Types.ObjectId().toString();
    
    const event = new Event(eventData);
    await event.save();
    
    res.status(201).json(event);
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.put('/api/events/:eventId', async (req, res) => {
  try {
    const updates = { ...req.body, updatedAt: new Date() };
    const event = await Event.findByIdAndUpdate(
      req.params.eventId,
      updates,
      { new: true }
    );
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    res.json(event);
  } catch (error) {
    console.error('Update event error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.delete('/api/events/:eventId', async (req, res) => {
  try {
    const event = await Event.findByIdAndDelete(req.params.eventId);
    
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    // Also delete related registrations
    await Registration.deleteMany({ eventId: req.params.eventId });
    
    res.json({ message: 'Event deleted successfully' });
  } catch (error) {
    console.error('Delete event error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Registration Routes
app.get('/api/registrations/user/:userId', async (req, res) => {
  try {
    const registrations = await Registration.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.json(registrations);
  } catch (error) {
    console.error('Get user registrations error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/registrations/event/:eventId', async (req, res) => {
  try {
    const registrations = await Registration.find({ eventId: req.params.eventId }).sort({ createdAt: -1 });
    res.json(registrations);
  } catch (error) {
    console.error('Get event registrations error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/registrations', async (req, res) => {
  try {
    const registrationData = req.body;
    registrationData.id = new mongoose.Types.ObjectId().toString();
    
    // Check if user is already registered for this event
    const existingRegistration = await Registration.findOne({
      userId: registrationData.userId,
      eventId: registrationData.eventId
    });
    
    if (existingRegistration) {
      return res.status(400).json({ message: 'User already registered for this event' });
    }
    
    // Check if event has available slots
    const event = await Event.findById(registrationData.eventId);
    if (!event) {
      return res.status(404).json({ message: 'Event not found' });
    }
    
    if (event.availableSlots <= 0) {
      return res.status(400).json({ message: 'Event is fully booked' });
    }
    
    const registration = new Registration(registrationData);
    await registration.save();
    
    // Update event available slots
    event.availableSlots -= 1;
    await event.save();
    
    res.status(201).json(registration);
  } catch (error) {
    console.error('Create registration error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.put('/api/registrations/:registrationId', async (req, res) => {
  try {
    const updates = { ...req.body, updatedAt: new Date() };
    const registration = await Registration.findByIdAndUpdate(
      req.params.registrationId,
      updates,
      { new: true }
    );
    
    if (!registration) {
      return res.status(404).json({ message: 'Registration not found' });
    }
    
    res.json(registration);
  } catch (error) {
    console.error('Update registration error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Notification Routes
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.params.userId }).sort({ timestamp: -1 });
    res.json(notifications);
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/notifications', async (req, res) => {
  try {
    const notification = new Notification(req.body);
    await notification.save();
    
    res.status(201).json(notification);
  } catch (error) {
    console.error('Send notification error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.put('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.notificationId,
      { read: true },
      { new: true }
    );
    
    if (!notification) {
      return res.status(404).json({ message: 'Notification not found' });
    }
    
    res.json(notification);
  } catch (error) {
    console.error('Mark notification read error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Upload Routes
app.post('/api/upload/image', async (req, res) => {
  try {
    const { image, fileName, fileType } = req.body;
    
    if (!image || !fileName) {
      return res.status(400).json({ message: 'Missing image data or filename' });
    }
    
    // Remove data URL prefix if present
    const base64Data = image.replace(/^data:image\/[a-z]+;base64,/, '');
    
    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = fileName.split('.').pop() || 'jpg';
    const newFileName = `image-${uniqueSuffix}.${extension}`;
    const filePath = path.join(imagesDir, newFileName);
    
    // Save file
    fs.writeFileSync(filePath, base64Data, 'base64');
    
    const fileUrl = `${req.protocol}://${req.get('host')}/uploads/images/${newFileName}`;
    
    res.json({ url: fileUrl });
  } catch (error) {
    console.error('Upload image error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/upload/certificate', async (req, res) => {
  try {
    const { certificate, fileName, userId, eventId } = req.body;
    
    if (!certificate || !fileName) {
      return res.status(400).json({ message: 'Missing certificate data or filename' });
    }
    
    // Remove data URL prefix if present
    const base64Data = certificate.replace(/^data:[a-z\/]+;base64,/, '');
    
    // Generate unique filename
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const extension = fileName.split('.').pop() || 'pdf';
    const newFileName = `cert-${userId}-${eventId}-${uniqueSuffix}.${extension}`;
    const filePath = path.join(certificatesDir, newFileName);
    
    // Save file
    fs.writeFileSync(filePath, base64Data, 'base64');
    
    const fileUrl = `${req.protocol}://${req.get('host')}/uploads/certificates/${newFileName}`;
    
    res.json({ url: fileUrl });
  } catch (error) {
    console.error('Upload certificate error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Analytics Routes
app.get('/api/analytics', async (req, res) => {
  try {
    const [totalUsers, totalEvents, totalRegistrations, attendedRegistrations] = await Promise.all([
      User.countDocuments(),
      Event.countDocuments(),
      Registration.countDocuments(),
      Registration.countDocuments({ isAttended: true })
    ]);

    const attendanceRate = totalRegistrations > 0 ? (attendedRegistrations / totalRegistrations * 100) : 0;

    const analytics = {
      totalUsers,
      totalEvents,
      totalRegistrations,
      attendedRegistrations,
      attendanceRate: Math.round(attendanceRate * 100) / 100
    };

    res.json(analytics);
  } catch (error) {
    console.error('Get analytics error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Export Routes
app.get('/api/export/:dataType', async (req, res) => {
  try {
    const { dataType } = req.params;
    let data = [];
    let filename = '';

    switch (dataType) {
      case 'users':
        data = await User.find({}, { password: 0 });
        filename = `users_export_${Date.now()}.csv`;
        break;
      case 'events':
        data = await Event.find({});
        filename = `events_export_${Date.now()}.csv`;
        break;
      case 'registrations':
        data = await Registration.find({});
        filename = `registrations_export_${Date.now()}.csv`;
        break;
      default:
        return res.status(400).json({ message: 'Invalid data type' });
    }

    // Convert to CSV (simplified)
    const csv = convertToCSV(data);
    const filePath = path.join(uploadsDir, filename);
    
    fs.writeFileSync(filePath, csv);
    
    const downloadUrl = `${req.protocol}://${req.get('host')}/uploads/${filename}`;
    
    res.json({ downloadUrl });
  } catch (error) {
    console.error('Export data error:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Utility function to convert JSON to CSV
function convertToCSV(data) {
  if (!data || data.length === 0) return '';
  
  const headers = Object.keys(data[0]).join(',');
  const rows = data.map(item => 
    Object.values(item).map(value => 
      typeof value === 'string' ? `"${value.replace(/"/g, '""')}"` : value
    ).join(',')
  );
  
  return [headers, ...rows].join('\n');
}

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Server error:', error);
  res.status(500).json({ message: 'Internal server error' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Endpoint not found' });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Eventura Backend Server running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔗 API Base URL: http://localhost:${PORT}/api`);
});

module.exports = app;
