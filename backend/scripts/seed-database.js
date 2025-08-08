const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const path = require('path');

// Load environment variables
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// MongoDB Connection with retry logic
async function connectWithRetry(maxRetries = 5) {
  let retries = 0;
  
  while (retries < maxRetries) {
    try {
      console.log(`🔗 Attempting MongoDB connection (attempt ${retries + 1}/${maxRetries})...`);
      
      await mongoose.connect(process.env.MONGODB_URI, {
        serverSelectionTimeoutMS: 10000,
        socketTimeoutMS: 45000,
        maxPoolSize: 10,
        minPoolSize: 2,
        maxIdleTimeMS: 30000,
        bufferCommands: false,
      });
      
      console.log('✅ Connected to MongoDB Atlas');
      return;
    } catch (error) {
      retries++;
      console.error(`❌ MongoDB connection attempt ${retries} failed:`, error.message);
      
      if (retries < maxRetries) {
        const delay = Math.min(1000 * Math.pow(2, retries), 30000); // Exponential backoff with max 30s
        console.log(`⏳ Waiting ${delay}ms before retry...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        throw new Error(`Failed to connect to MongoDB after ${maxRetries} attempts: ${error.message}`);
      }
    }
  }
}

// Test connection function
async function testConnection() {
  try {
    const result = await mongoose.connection.db.admin().ping();
    console.log('✅ MongoDB connection test successful:', result);
    return true;
  } catch (error) {
    console.error('❌ MongoDB connection test failed:', error.message);
    return false;
  }
}

// Schemas (matching server.js)
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

// Models
const User = mongoose.model('User', userSchema);
const Event = mongoose.model('Event', eventSchema);

// Seed data
const seedUsers = [
  {
    userId: 'admin001',
    name: 'System Administrator',
    email: 'admin@eventura.com',
    password: 'AdminPass123!', // In production, this should be hashed
    role: 'Admin',
    age: 30,
    address: '123 Admin Street, Tech City, TC 12345',
    status: 'active'
  },
  {
    userId: 'org001',
    name: 'Sarah Johnson',
    email: 'sarah.organizer@eventura.com',
    password: 'OrgPass123!', // In production, this should be hashed
    role: 'Organizer',
    age: 28,
    address: '456 Event Avenue, Organizer Town, OT 67890',
    status: 'active'
  },
  {
    userId: 'org002',
    name: 'Michael Chen',
    email: 'michael.organizer@eventura.com',
    password: 'OrgPass123!', // In production, this should be hashed
    role: 'Organizer',
    age: 32,
    address: '789 Conference Blvd, Event City, EC 54321',
    status: 'active'
  },
  {
    userId: 'user001',
    name: 'Jane Doe',
    email: 'jane.user@example.com',
    password: 'UserPass123!', // In production, this should be hashed
    role: 'User',
    age: 25,
    address: '321 User Lane, Participant City, PC 98765',
    status: 'active'
  }
];

const seedEvents = [
  {
    title: 'Tech Innovation Summit 2024',
    description: 'Join industry leaders and innovators for a day of cutting-edge technology discussions, networking, and insights into the future of tech.',
    eventDate: new Date('2024-03-15T09:00:00Z'),
    location: 'Tech Convention Center, Silicon Valley, CA',
    organizerId: 'org001',
    organizerName: 'Sarah Johnson',
    totalSlots: 200,
    availableSlots: 180,
    status: 'upcoming',
    imageUrl: '',
    pendingApproval: false
  },
  {
    title: 'Digital Marketing Workshop',
    description: 'Learn the latest digital marketing strategies, social media optimization, and data-driven marketing techniques from industry experts.',
    eventDate: new Date('2024-03-22T10:00:00Z'),
    location: 'Marketing Hub, New York, NY',
    organizerId: 'org002',
    organizerName: 'Michael Chen',
    totalSlots: 50,
    availableSlots: 35,
    status: 'upcoming',
    imageUrl: '',
    pendingApproval: false
  },
  {
    title: 'Startup Pitch Competition',
    description: 'Witness the next generation of entrepreneurs pitch their innovative ideas to top investors and industry leaders.',
    eventDate: new Date('2024-04-10T14:00:00Z'),
    location: 'Innovation Center, Austin, TX',
    organizerId: 'org001',
    organizerName: 'Sarah Johnson',
    totalSlots: 150,
    availableSlots: 120,
    status: 'upcoming',
    imageUrl: '',
    pendingApproval: false
  },
  {
    title: 'AI & Machine Learning Conference',
    description: 'Deep dive into artificial intelligence and machine learning with hands-on workshops and presentations from AI pioneers.',
    eventDate: new Date('2024-04-25T09:30:00Z'),
    location: 'AI Research Center, Boston, MA',
    organizerId: 'org002',
    organizerName: 'Michael Chen',
    totalSlots: 300,
    availableSlots: 275,
    status: 'upcoming',
    imageUrl: '',
    pendingApproval: false
  }
];

// Seeding functions
async function seedDatabase() {
  try {
    console.log('🌱 Starting database seeding...');
    
    // Clear existing data
    console.log('🧹 Clearing existing data...');
    await User.deleteMany({});
    await Event.deleteMany({});
    console.log('✅ Existing data cleared');
    
    // Seed users
    console.log('👥 Seeding users...');
    const createdUsers = await User.insertMany(seedUsers);
    console.log(`✅ Created ${createdUsers.length} users:`);
    createdUsers.forEach(user => {
      console.log(`   - ${user.role}: ${user.name} (${user.userId})`);
    });
    
    // Seed events
    console.log('📅 Seeding events...');
    const createdEvents = await Event.insertMany(seedEvents);
    console.log(`✅ Created ${createdEvents.length} events:`);
    createdEvents.forEach(event => {
      console.log(`   - "${event.title}" by ${event.organizerName}`);
    });
    
    console.log('🎉 Database seeding completed successfully!');
    
    // Display summary
    console.log('\n📊 Database Summary:');
    console.log(`   Total Users: ${await User.countDocuments()}`);
    console.log(`   - Admins: ${await User.countDocuments({ role: 'Admin' })}`);
    console.log(`   - Organizers: ${await User.countDocuments({ role: 'Organizer' })}`);
    console.log(`   - Users: ${await User.countDocuments({ role: 'User' })}`);
    console.log(`   Total Events: ${await Event.countDocuments()}`);
    
    console.log('\n🔐 Default Login Credentials:');
    console.log('   Admin: admin001 / AdminPass123!');
    console.log('   Organizer 1: org001 / OrgPass123!');
    console.log('   Organizer 2: org002 / OrgPass123!');
    console.log('   User: user001 / UserPass123!');
    
  } catch (error) {
    console.error('❌ Database seeding failed:', error);
    throw error;
  }
}

// Main function
async function main() {
  try {
    console.log('🚀 Eventura Database Seeder Starting...');
    
    // Validate environment
    if (!process.env.MONGODB_URI) {
      throw new Error('MONGODB_URI environment variable is required');
    }
    
    console.log(`🔗 Connecting to: ${process.env.MONGODB_URI.replace(/\/\/.*@/, '//***:***@')}`);
    
    // Connect with retry logic
    await connectWithRetry();
    
    // Test connection
    const connectionTest = await testConnection();
    if (!connectionTest) {
      throw new Error('Connection test failed');
    }
    
    // Seed database
    await seedDatabase();
    
    console.log('✅ Seeding process completed successfully!');
    
  } catch (error) {
    console.error('💥 Seeding process failed:', error.message);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
    console.log('🔌 Disconnected from MongoDB');
    process.exit(0);
  }
}

// Handle unhandled rejections
process.on('unhandledRejection', (err) => {
  console.error('💥 Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('💥 Uncaught Exception:', err);
  process.exit(1);
});

// Run the seeder
if (require.main === module) {
  main();
}

module.exports = { main, connectWithRetry, testConnection, seedDatabase };
