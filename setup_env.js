const fs = require('fs');
const path = require('path');

console.log('🔧 Setting up Eventura App Environment Configuration...\n');

// Check if .env already exists
const envPath = path.join(__dirname, '.env');
if (fs.existsSync(envPath)) {
  console.log('⚠️  .env file already exists. Backing up to .env.backup');
  fs.copyFileSync(envPath, path.join(__dirname, '.env.backup'));
}

// Create .env content
const envContent = `# Eventura Flutter App Environment Configuration
# MongoDB Connection String (Updated with actual password)
MONGO_URL=mongodb://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority&connectTimeoutMS=0&socketTimeoutMS=0

# Database Configuration
DB_NAME=MongoDataBase
COLLECTION_NAME=users

# Server Configuration
SERVER_PORT=42952
SERVER_IP=0.0.0.0

# Application Configuration
APP_NAME=Eventura
APP_VERSION=1.0.0
DEBUG_MODE=true
LOG_LEVEL=debug

# API Configuration
API_BASE_URL=http://eventura.local:42952
CONNECTION_TIMEOUT=30000
REQUEST_TIMEOUT=10000

# Security Settings
JWT_SECRET=eventura_jwt_secret_key_2024_secure
API_KEY=eventura_api_key_2024_external_services

# Feature Flags
ENABLE_ANALYTICS=true
ENABLE_NOTIFICATIONS=true
ENABLE_CACHE=true

# Cache Configuration
CACHE_DURATION=3600

# Rate Limiting
RATE_LIMIT_REQUESTS=100
RATE_LIMIT_WINDOW=1

# Environment
ENVIRONMENT=development
`;

try {
  fs.writeFileSync(envPath, envContent);
  console.log('✅ .env file created successfully with the correct password!');
  console.log('\n🚀 You can now start the server with: npm start');
  console.log('🔍 Or test the connection with: npm run test-connection');
} catch (error) {
  console.error('❌ Error creating .env file:', error.message);
  process.exit(1);
} 