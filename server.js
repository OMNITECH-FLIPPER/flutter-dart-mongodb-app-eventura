const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const bodyParser = require('body-parser');
const { MongoClient, ServerApiVersion } = require('mongodb');
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const bcrypt = require('bcrypt');

// --- FCM Setup ---
const admin = require('firebase-admin');
let fcmInitialized = false;
try {
  if (!admin.apps.length) {
    // TODO: Place your Firebase service account key JSON in the project root and update the path below
    const serviceAccount = require('./firebase-service-account.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    fcmInitialized = true;
    console.log('✅ FCM initialized');
  }
} catch (e) {
  console.warn('⚠️ FCM not initialized. Push notifications will not be sent. Reason:', e.message);
}

async function sendPushNotificationFCM({ token, title, body, data }) {
  if (!fcmInitialized || !token) return false;
  try {
    const message = {
      token,
      notification: { title, body },
      data: data || {},
    };
    await admin.messaging().send(message);
    return true;
  } catch (e) {
    console.error('❌ FCM send error:', e.message);
    return false;
  }
}

const app = express();
const PORT = process.env.SERVER_PORT || 3000;

// MongoDB Connection
const uri = process.env.MONGO_URL || "mongodb://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority&connectTimeoutMS=0&socketTimeoutMS=0";
const client = new MongoClient(uri, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

// Database connection function
async function connectToDatabase() {
  try {
    if (!client.topology || !client.topology.isConnected()) {
      await client.connect();
      console.log('✅ Connected to MongoDB successfully');
    }
    return client.db(process.env.DB_NAME || 'MongoDataBase');
  } catch (error) {
    console.error('❌ MongoDB connection error:', error);
    throw error;
  }
}

// Middleware
app.use(helmet({
  crossOriginEmbedderPolicy: false,
  contentSecurityPolicy: false,
}));
app.use(cors({
  origin: true, // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  exposedHeaders: ['Content-Range', 'X-Content-Range']
}));
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Content-Type, Authorization, Content-Length, X-Requested-With');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});
app.use(morgan('combined'));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Eventura Backend Server is running',
    timestamp: new Date().toISOString(),
    port: PORT
  });
});

// API Routes
app.get('/api', (req, res) => {
  res.json({
    message: 'Eventura API is running',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      users: '/api/users',
      events: '/api/events',
      registrations: '/api/registrations',
      certificates: '/api/certificates',
      collections: '/api/collections'
    }
  });
});

// Collections endpoint
app.get('/api/collections', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collections = await database.listCollections().toArray();
    res.json(collections.map(col => col.name));
  } catch (error) {
    console.error('Error fetching collections:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Users API
app.get('/api/users', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('users');
    const users = await collection.find({}).toArray();
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('users');
    const user = req.body;
    if (user.password) {
      const saltRounds = 10;
      user.password = await bcrypt.hash(user.password, saltRounds);
    }
    const result = await collection.insertOne(user);
    res.status(201).json(result);
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/users/:userId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('users');
    const { userId } = req.params;
    const updates = req.body;
    
    const result = await collection.updateOne(
      { user_id: userId },
      { $set: updates }
    );
    
    if (result.matchedCount > 0) {
      res.json({ success: true, message: 'User updated successfully' });
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/users/:userId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('users');
    const { userId } = req.params;
    
    const result = await collection.deleteOne({ user_id: userId });
    
    if (result.deletedCount > 0) {
      res.json({ success: true, message: 'User deleted successfully' });
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Events API
app.get('/api/events', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('events');
    const events = await collection.find({}).toArray();
    res.json(events);
  } catch (error) {
    console.error('Error fetching events:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/events/:eventId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('events');
    const { eventId } = req.params;
    
    // Convert string ID to ObjectId
    const { ObjectId } = require('mongodb');
    let query = {};
    
    try {
      query._id = new ObjectId(eventId);
    } catch (e) {
      // If conversion fails, try with string ID
      query._id = eventId;
    }
    
    const event = await collection.findOne(query);
    
    if (event) {
      res.json(event);
    } else {
      res.status(404).json({ error: 'Event not found' });
    }
  } catch (error) {
    console.error('Error fetching event:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/events', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('events');
    const result = await collection.insertOne(req.body);
    res.status(201).json(result);
  } catch (error) {
    console.error('Error creating event:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/events/:eventId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('events');
    const { eventId } = req.params;
    const updates = req.body;
    
    // Convert string ID to ObjectId
    const { ObjectId } = require('mongodb');
    let query = {};
    
    try {
      query._id = new ObjectId(eventId);
    } catch (e) {
      // If conversion fails, try with string ID
      query._id = eventId;
    }
    
    const result = await collection.updateOne(
      query,
      { $set: updates }
    );
    
    if (result.matchedCount > 0) {
      res.json({ success: true, message: 'Event updated successfully' });
    } else {
      res.status(404).json({ error: 'Event not found' });
    }
  } catch (error) {
    console.error('Error updating event:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/events/:eventId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('events');
    const { eventId } = req.params;
    
    // Convert string ID to ObjectId
    const { ObjectId } = require('mongodb');
    let query = {};
    
    try {
      query._id = new ObjectId(eventId);
    } catch (e) {
      // If conversion fails, try with string ID
      query._id = eventId;
    }
    
    const result = await collection.deleteOne(query);
    
    if (result.deletedCount > 0) {
      res.json({ success: true, message: 'Event deleted successfully' });
    } else {
      res.status(404).json({ error: 'Event not found' });
    }
  } catch (error) {
    console.error('Error deleting event:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Registrations API
app.get('/api/registrations', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('event_registrations');
    const registrations = await collection.find({}).toArray();
    res.json(registrations);
  } catch (error) {
    console.error('Error fetching registrations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/registrations', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const registrationsCollection = database.collection('event_registrations');
    const eventsCollection = database.collection('events');
    
    const eventId = req.body.event_id;
    
    // Check if event exists and has available slots
    if (eventId) {
      const { ObjectId } = require('mongodb');
      let eventQuery = {};
      
      try {
        eventQuery._id = new ObjectId(eventId);
      } catch (e) {
        eventQuery._id = eventId;
      }
      
      const event = await eventsCollection.findOne(eventQuery);
      
      if (!event) {
        return res.status(404).json({ error: 'Event not found' });
      }
      
      if (event.available_slots <= 0) {
        return res.status(400).json({ error: 'No available slots for this event' });
      }
      
      // Insert the registration
      const result = await registrationsCollection.insertOne(req.body);
      
      // Update event available slots
      await eventsCollection.updateOne(
        eventQuery,
        { $inc: { available_slots: -1 } }
      );
      
      console.log(`✅ Registration created and slots updated for event ${eventId}: ${event.available_slots} -> ${event.available_slots - 1}`);
      
      res.status(201).json(result);
    } else {
      // Insert the registration without slot update
      const result = await registrationsCollection.insertOne(req.body);
      res.status(201).json(result);
    }
  } catch (error) {
    console.error('Error creating registration:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/registrations/:registrationId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('event_registrations');
    const { registrationId } = req.params;
    const updates = req.body;
    
    // Convert string ID to ObjectId
    const { ObjectId } = require('mongodb');
    let query = {};
    
    try {
      query._id = new ObjectId(registrationId);
    } catch (e) {
      query._id = registrationId;
    }
    
    // Convert field names to match database schema
    const dbUpdates = {};
    if (updates.attended !== undefined) {
      dbUpdates.is_confirmed = updates.attended;
      if (updates.attended) {
        dbUpdates.attendance_date = new Date().toISOString();
      }
    }
    if (updates.status !== undefined) {
      dbUpdates.status = updates.status;
    }
    if (updates.attendance_date !== undefined) {
      dbUpdates.attendance_date = updates.attendance_date;
    }
    if (updates.certificate_url !== undefined) {
      dbUpdates.certificate_url = updates.certificate_url;
    }
    
    const result = await collection.updateOne(
      query,
      { $set: dbUpdates }
    );
    
    if (result.matchedCount > 0) {
      console.log(`✅ Registration updated successfully: ${registrationId}`);
      res.json({ success: true, message: 'Registration updated successfully' });
    } else {
      console.log(`❌ Registration not found: ${registrationId}`);
      res.status(404).json({ error: 'Registration not found' });
    }
  } catch (error) {
    console.error('Error updating registration:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/registrations/user/:userId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('event_registrations');
    const { userId } = req.params;
    const registrations = await collection.find({ user_id: userId }).toArray();
    res.json(registrations);
  } catch (error) {
    console.error('Error fetching user registrations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/registrations/event/:eventId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('event_registrations');
    const { eventId } = req.params;
    const registrations = await collection.find({ event_id: eventId }).toArray();
    res.json(registrations);
  } catch (error) {
    console.error('Error fetching event registrations:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Attendance confirmation endpoint
app.post('/api/registrations/:registrationId/confirm-attendance', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('event_registrations');
    const { registrationId } = req.params;
    
    // Convert string ID to ObjectId
    const { ObjectId } = require('mongodb');
    let query = {};
    
    try {
      query._id = new ObjectId(registrationId);
    } catch (e) {
      query._id = registrationId;
    }
    
    const result = await collection.updateOne(
      query,
      { 
        $set: { 
          is_confirmed: true,
          attendance_date: new Date().toISOString(),
          status: 'attended'
        } 
      }
    );
    
    if (result.matchedCount > 0) {
      console.log(`✅ Attendance confirmed for registration: ${registrationId}`);
      res.json({ success: true, message: 'Attendance confirmed successfully' });
    } else {
      console.log(`❌ Registration not found for attendance: ${registrationId}`);
      res.status(404).json({ error: 'Registration not found' });
    }
  } catch (error) {
    console.error('Error confirming attendance:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Notifications API
app.get('/api/notifications', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('notifications');
    const { userId } = req.query;
    
    let query = {};
    if (userId) {
      query.userId = userId;
    }
    
    const notifications = await collection.find(query).toArray();
    res.json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/notifications', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('notifications');
    const usersCollection = database.collection('users');
    const notification = req.body;
    // Store notification in DB
    const result = await collection.insertOne(notification);
    // Try to send push notification if user has device token
    if (notification.userId) {
      const user = await usersCollection.findOne({ user_id: notification.userId });
      if (user && user.deviceToken) {
        await sendPushNotificationFCM({
          token: user.deviceToken,
          title: notification.title || 'Eventura Notification',
          body: notification.body || notification.message || '',
          data: { notificationId: result.insertedId.toString() },
        });
      }
    }
    res.status(201).json(result);
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.put('/api/notifications/:notificationId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('notifications');
    const { notificationId } = req.params;
    const updates = req.body;
    
    const result = await collection.updateOne(
      { id: notificationId },
      { $set: updates }
    );
    
    if (result.matchedCount > 0) {
      res.json({ success: true, message: 'Notification updated successfully' });
    } else {
      res.status(404).json({ error: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error updating notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.delete('/api/notifications/:notificationId', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('notifications');
    const { notificationId } = req.params;
    
    const result = await collection.deleteOne({ id: notificationId });
    
    if (result.deletedCount > 0) {
      res.json({ success: true, message: 'Notification deleted successfully' });
    } else {
      res.status(404).json({ error: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Image upload endpoint
app.post('/api/upload/image', async (req, res) => {
  try {
    const { imageData, fileName, fileType } = req.body;
    
    if (!imageData || !fileName) {
      return res.status(400).json({ error: 'Image data and filename are required' });
    }
    
    // Ensure uploads/images directory exists
    const uploadDir = path.join(__dirname, 'uploads', 'images');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    // Decode base64 and save file
    const filePath = path.join(uploadDir, fileName);
    const base64Data = imageData.replace(/^data:image\/(png|jpeg|jpg);base64,/, '');
    fs.writeFileSync(filePath, base64Data, 'base64');
    const imageUrl = `http://localhost:${PORT}/uploads/images/${encodeURIComponent(fileName)}`;
    console.log(`✅ Image uploaded: ${fileName} -> ${imageUrl}`);
    
    res.json({
      success: true,
      imageUrl: imageUrl,
      fileName: fileName
    });
  } catch (error) {
    console.error('Error uploading image:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Certificate upload endpoint
app.post('/api/upload/certificate', async (req, res) => {
  try {
    const { certificateData, fileName, userId, eventId, registrationId } = req.body;
    
    if (!certificateData || !fileName) {
      return res.status(400).json({ error: 'Certificate data and filename are required' });
    }
    
    const database = await connectToDatabase();
    const { ObjectId } = require('mongodb');
    
    // Store certificate in certificates collection
    const certificatesCollection = database.collection('certificates');
    const certificateDoc = {
      fileName: fileName,
      certificateData: certificateData,
      userId: userId,
      eventId: eventId,
      registrationId: registrationId,
      uploadDate: new Date(),
      fileType: fileName.split('.').pop() || 'pdf',
      fileSize: Buffer.from(certificateData, 'base64').length
    };
    
    const certificateResult = await certificatesCollection.insertOne(certificateDoc);
    const certificateId = certificateResult.insertedId;
    
    // Generate certificate URL
    const certificateUrl = `http://localhost:3000/api/certificates/${certificateId}`;
    
    // Update registration with certificate URL
    const registrationsCollection = database.collection('event_registrations');
    let query = {};
    if (registrationId) {
      try {
        query._id = new ObjectId(registrationId);
      } catch (e) {
        query.registration_id = registrationId;
      }
    } else {
      query.user_id = userId;
      query.event_id = eventId;
    }
    
    await registrationsCollection.updateOne(
      query,
      { 
        $set: { 
          certificate_url: certificateUrl,
          certificate_id: certificateId.toString(),
          certificate_upload_date: new Date()
        } 
      }
    );
    
    console.log(`✅ Certificate uploaded: ${fileName} -> ${certificateUrl}`);
    
    res.json({
      success: true,
      certificateUrl: certificateUrl,
      fileName: fileName,
      certificateId: certificateId.toString()
    });
  } catch (error) {
    console.error('Error uploading certificate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get certificate by ID
app.get('/api/certificates/:certificateId', async (req, res) => {
  try {
    const { certificateId } = req.params;
    const database = await connectToDatabase();
    const { ObjectId } = require('mongodb');
    
    const certificatesCollection = database.collection('certificates');
    const certificate = await certificatesCollection.findOne({ 
      _id: new ObjectId(certificateId) 
    });
    
    if (!certificate) {
      return res.status(404).json({ error: 'Certificate not found' });
    }
    
    // Set appropriate headers for file download
    res.setHeader('Content-Type', `application/${certificate.fileType}`);
    res.setHeader('Content-Disposition', `attachment; filename="${certificate.fileName}"`);
    
    // Convert base64 back to buffer and send
    const fileBuffer = Buffer.from(certificate.certificateData, 'base64');
    res.send(fileBuffer);
  } catch (error) {
    console.error('Error retrieving certificate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// List certificates for a user
app.get('/api/certificates/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const database = await connectToDatabase();
    
    const certificatesCollection = database.collection('certificates');
    const certificates = await certificatesCollection.find({ userId: userId }).toArray();
    
    res.json(certificates.map(cert => ({
      id: cert._id,
      fileName: cert.fileName,
      uploadDate: cert.uploadDate,
      eventId: cert.eventId,
      fileType: cert.fileType,
      fileSize: cert.fileSize
    })));
  } catch (error) {
    console.error('Error fetching user certificates:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete certificate
app.delete('/api/certificates/:certificateId', async (req, res) => {
  try {
    const { certificateId } = req.params;
    const database = await connectToDatabase();
    const { ObjectId } = require('mongodb');
    
    const certificatesCollection = database.collection('certificates');
    const result = await certificatesCollection.deleteOne({ 
      _id: new ObjectId(certificateId) 
    });
    
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: 'Certificate not found' });
    }
    
    // Also remove certificate reference from registration
    const registrationsCollection = database.collection('event_registrations');
    await registrationsCollection.updateMany(
      { certificate_id: certificateId },
      { 
        $unset: { 
          certificate_url: "",
          certificate_id: "",
          certificate_upload_date: ""
        } 
      }
    );
    
    res.json({ success: true, message: 'Certificate deleted successfully' });
  } catch (error) {
    console.error('Error deleting certificate:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// QR Code generation endpoint
app.post('/api/qr/generate', async (req, res) => {
  try {
    const { eventId, registrationId, type } = req.body;
    const database = await connectToDatabase();
    const { ObjectId } = require('mongodb');
    
    if (type === 'checkin' && registrationId) {
      // Generate check-in QR code for specific registration
      const registrationsCollection = database.collection('event_registrations');
      const registration = await registrationsCollection.findOne({ 
        _id: new ObjectId(registrationId) 
      });
      
      if (!registration) {
        return res.status(404).json({ error: 'Registration not found' });
      }
      
      const eventsCollection = database.collection('events');
      const event = await eventsCollection.findOne({ 
        _id: new ObjectId(registration.event_id) 
      });
      
      if (!event) {
        return res.status(404).json({ error: 'Event not found' });
      }
      
      const qrData = {
        type: 'event_checkin',
        eventId: event._id.toString(),
        eventTitle: event.title,
        registrationId: registration._id.toString(),
        userId: registration.user_id,
        userName: registration.user_name,
        timestamp: Date.now()
      };
      
      res.json({
        success: true,
        qrData: JSON.stringify(qrData),
        registration: registration,
        event: event
      });
    } else if (type === 'event_info' && eventId) {
      // Generate event info QR code
      const eventsCollection = database.collection('events');
      const event = await eventsCollection.findOne({ 
        _id: new ObjectId(eventId) 
      });
      
      if (!event) {
        return res.status(404).json({ error: 'Event not found' });
      }
      
      const qrData = {
        type: 'event_info',
        eventId: event._id.toString(),
        eventTitle: event.title,
        eventDate: event.event_date,
        location: event.location,
        organizerName: event.organizer_name,
        availableSlots: event.available_slots,
        totalSlots: event.total_slots
      };
      
      res.json({
        success: true,
        qrData: JSON.stringify(qrData),
        event: event
      });
    } else {
      res.status(400).json({ error: 'Invalid QR code type or missing parameters' });
    }
  } catch (error) {
    console.error('Error generating QR code:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Authentication endpoint
app.post('/api/auth/login', async (req, res) => {
  try {
    const { userId, password } = req.body;
    console.log(`🔐 Login attempt for user: ${userId}`);
    
    const database = await connectToDatabase();
    const collection = database.collection('users');
    const user = await collection.findOne({ user_id: userId });
    
    console.log(`👤 User found: ${user ? 'Yes' : 'No'}`);
    
    if (user && user.password) {
      console.log(`🔑 Stored password starts with: ${user.password.substring(0, 10)}...`);
      console.log(`🔑 Input password: ${password}`);
      
      let match = false;
      
      // Check if password is hashed (bcrypt hashes start with $2b$ or $2a$)
      if (user.password.startsWith('$2b$') || user.password.startsWith('$2a$')) {
        console.log('🔒 Using bcrypt comparison for hashed password');
        match = await bcrypt.compare(password, user.password);
      } else {
        console.log('🔓 Using plain text comparison');
        match = password === user.password;
      }
      
      console.log(`✅ Password match: ${match}`);
      
      if (match) {
        console.log(`✅ Authentication successful for user: ${userId}`);
        res.json({
          success: true,
          user: {
            id: user._id,
            userId: user.user_id,
            name: user.name,
            email: user.email,
            role: user.role
          }
        });
        return;
      }
    }
    
    console.log(`❌ Authentication failed for user: ${userId}`);
    res.status(401).json({ success: false, message: 'Invalid credentials' });
  } catch (error) {
    console.error('Error during authentication:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Analytics API
app.get('/api/analytics', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const usersCollection = database.collection('users');
    const eventsCollection = database.collection('events');
    const registrationsCollection = database.collection('event_registrations');
    
    // Get basic counts
    const totalUsers = await usersCollection.countDocuments();
    const totalEvents = await eventsCollection.countDocuments();
    const totalRegistrations = await registrationsCollection.countDocuments();
    
    // Calculate attendance rate
    const attendedCount = await registrationsCollection.countDocuments({ is_confirmed: true });
    const attendanceRate = totalRegistrations > 0 ? (attendedCount / totalRegistrations) * 100 : 0;
    
    // Get events by month (last 12 months)
    const twelveMonthsAgo = new Date();
    twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);
    
    const eventsByMonth = await eventsCollection.aggregate([
      { $match: { created_at: { $gte: twelveMonthsAgo } } },
      {
        $group: {
          _id: { 
            year: { $year: "$created_at" },
            month: { $month: "$created_at" }
          },
          count: { $sum: 1 }
        }
      },
      { $sort: { "_id.year": 1, "_id.month": 1 } }
    ]).toArray();
    
    // Get popular events (by registration count)
    const popularEvents = await registrationsCollection.aggregate([
      {
        $group: {
          _id: "$event_id",
          registrationCount: { $sum: 1 }
        }
      },
      { $sort: { registrationCount: -1 } },
      { $limit: 5 }
    ]).toArray();
    
    const analytics = {
      totalUsers,
      totalEvents,
      totalRegistrations,
      attendanceRate: Math.round(attendanceRate * 100) / 100,
      eventsByMonth,
      popularEvents,
      generatedAt: new Date().toISOString()
    };
    
    res.json(analytics);
  } catch (error) {
    console.error('Error fetching analytics:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get events by organizer
app.get('/api/events/organizer/:organizerId', async (req, res) => {
  try {
    const { organizerId } = req.params;
    const database = await connectToDatabase();
    const collection = database.collection('events');
    const events = await collection.find({ organizer_id: organizerId }).toArray();
    res.json(events);
  } catch (error) {
    console.error('Error fetching organizer events:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Password reset request
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const database = await connectToDatabase();
    const collection = database.collection('users');
    
    const user = await collection.findOne({ email: email });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    
    // Generate reset token (6 characters)
    const resetToken = Math.random().toString(36).substring(2, 8).toUpperCase();
    const resetExpiry = new Date(Date.now() + 3600000); // 1 hour from now
    
    // Store reset token in database
    await collection.updateOne(
      { email: email },
      { 
        $set: { 
          resetToken: resetToken,
          resetTokenExpiry: resetExpiry
        }
      }
    );
    
    console.log(`🔑 Password reset token generated for ${email}: ${resetToken}`);
    
    // In a real application, you would send an email here
    // For demo purposes, we'll return the token
    res.json({
      success: true,
      message: 'Reset token generated',
      resetToken: resetToken // Remove this in production!
    });
  } catch (error) {
    console.error('Error in forgot password:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Password reset
app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const { email, resetToken, newPassword } = req.body;
    const database = await connectToDatabase();
    const collection = database.collection('users');
    
    const user = await collection.findOne({ 
      email: email,
      resetToken: resetToken,
      resetTokenExpiry: { $gt: new Date() }
    });
    
    if (!user) {
      return res.status(400).json({ success: false, message: 'Invalid or expired reset token' });
    }
    
    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    
    // Update password and remove reset token
    await collection.updateOne(
      { email: email },
      { 
        $set: { password: hashedPassword },
        $unset: { resetToken: "", resetTokenExpiry: "" }
      }
    );
    
    res.json({ success: true, message: 'Password reset successful' });
  } catch (error) {
    console.error('Error in reset password:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// User profile update
app.put('/api/users/:userId/profile', async (req, res) => {
  try {
    const { userId } = req.params;
    const updates = req.body;
    const database = await connectToDatabase();
    const collection = database.collection('users');
    
    // Hash password if provided
    if (updates.password) {
      updates.password = await bcrypt.hash(updates.password, 10);
    }
    
    const result = await collection.updateOne(
      { user_id: userId },
      { $set: { ...updates, updated_at: new Date() } }
    );
    
    if (result.matchedCount > 0) {
      res.json({ success: true, message: 'Profile updated successfully' });
    } else {
      res.status(404).json({ error: 'User not found' });
    }
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Search events
app.get('/api/events/search', async (req, res) => {
  try {
    const { q, category, location, date } = req.query;
    const database = await connectToDatabase();
    const collection = database.collection('events');
    
    let query = {};
    
    if (q) {
      query.$or = [
        { title: { $regex: q, $options: 'i' } },
        { description: { $regex: q, $options: 'i' } }
      ];
    }
    
    if (category) {
      query.category = category;
    }
    
    if (location) {
      query.location = { $regex: location, $options: 'i' };
    }
    
    if (date) {
      const searchDate = new Date(date);
      const nextDay = new Date(searchDate);
      nextDay.setDate(nextDay.getDate() + 1);
      query.event_date = {
        $gte: searchDate,
        $lt: nextDay
      };
    }
    
    const events = await collection.find(query).toArray();
    res.json(events);
  } catch (error) {
    console.error('Error searching events:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Export data
app.get('/api/export/:dataType', async (req, res) => {
  try {
    const { dataType } = req.params;
    const database = await connectToDatabase();
    let data = [];
    
    switch (dataType) {
      case 'users':
        data = await database.collection('users').find({}).toArray();
        break;
      case 'events':
        data = await database.collection('events').find({}).toArray();
        break;
      case 'registrations':
        data = await database.collection('event_registrations').find({}).toArray();
        break;
      default:
        return res.status(400).json({ error: 'Invalid data type' });
    }
    
    // Convert to CSV format (simplified)
    if (data.length > 0) {
      const headers = Object.keys(data[0]).join(',');
      const rows = data.map(item => Object.values(item).join(','));
      const csv = [headers, ...rows].join('\n');
      
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', `attachment; filename="${dataType}_export_${Date.now()}.csv"`);
      res.send(csv);
    } else {
      res.json({ message: 'No data to export' });
    }
  } catch (error) {
    console.error('Error exporting data:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get notifications for user
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const database = await connectToDatabase();
    const collection = database.collection('notifications');
    
    const notifications = await collection.find({ userId: userId })
      .sort({ timestamp: -1 })
      .toArray();
      
    res.json(notifications);
  } catch (error) {
    console.error('Error fetching user notifications:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Mark notification as read
app.put('/api/notifications/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;
    const database = await connectToDatabase();
    const collection = database.collection('notifications');
    
    const result = await collection.updateOne(
      { _id: notificationId },
      { $set: { read: true, readAt: new Date() } }
    );
    
    if (result.matchedCount > 0) {
      res.json({ success: true, message: 'Notification marked as read' });
    } else {
      res.status(404).json({ error: 'Notification not found' });
    }
  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Get user statistics
app.get('/api/users/:userId/stats', async (req, res) => {
  try {
    const { userId } = req.params;
    const database = await connectToDatabase();
    const registrationsCollection = database.collection('event_registrations');
    
    const totalRegistrations = await registrationsCollection.countDocuments({ user_id: userId });
    const attendedEvents = await registrationsCollection.countDocuments({ 
      user_id: userId, 
      is_confirmed: true 
    });
    const upcomingEvents = await registrationsCollection.countDocuments({ 
      user_id: userId,
      status: 'registered'
    });
    
    const stats = {
      totalRegistrations,
      attendedEvents,
      upcomingEvents,
      attendanceRate: totalRegistrations > 0 ? (attendedEvents / totalRegistrations) * 100 : 0
    };
    
    res.json(stats);
  } catch (error) {
    console.error('Error fetching user stats:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Messaging API
app.post('/api/messages', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('messages');
    const { senderId, senderName, senderRole, message, replyTo } = req.body;
    const doc = {
      senderId,
      senderName,
      senderRole,
      message,
      replyTo: replyTo || null,
      createdAt: new Date(),
      replies: [],
    };
    const result = await collection.insertOne(doc);
    res.status(201).json({ success: true, id: result.insertedId });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/messages', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('messages');
    const { userId, role, thread } = req.query;
    let query = {};
    if (userId) query.senderId = userId;
    if (role) query.senderRole = role;
    if (thread) query.replyTo = thread;
    const messages = await collection.find(query).sort({ createdAt: -1 }).toArray();
    res.json(messages);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.get('/api/messages/:id', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('messages');
    const { id } = req.params;
    const { ObjectId } = require('mongodb');
    const message = await collection.findOne({ _id: new ObjectId(id) });
    if (!message) return res.status(404).json({ error: 'Message not found' });
    res.json(message);
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/api/messages/:id/reply', async (req, res) => {
  try {
    const database = await connectToDatabase();
    const collection = database.collection('messages');
    const { id } = req.params;
    const { senderId, senderName, senderRole, message } = req.body;
    const { ObjectId } = require('mongodb');
    const reply = {
      senderId,
      senderName,
      senderRole,
      message,
      createdAt: new Date(),
    };
    const result = await collection.updateOne(
      { _id: new ObjectId(id) },
      { $push: { replies: reply } }
    );
    if (result.matchedCount === 0) return res.status(404).json({ error: 'Message not found' });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Eventura Backend Server running on port ${PORT}`);
  console.log(`📊 Health check: http://eventura.local:${PORT}/health`);
  console.log(`🔗 API base URL: http://eventura.local:${PORT}/api`);
  console.log(`🌐 Available on all network interfaces`);
  console.log(`📝 MongoDB connected: ${uri.substring(0, uri.indexOf('@') + 1)}***`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down server...');
  await client.close();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Shutting down server...');
  await client.close();
  process.exit(0);
}); 