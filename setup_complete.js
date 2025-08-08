const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class CompleteSetup {
  constructor() {
    this.setupResults = [];
  }

  log(message, type = 'INFO') {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] [${type}] ${message}`);
  }

  async runCommand(command, description) {
    try {
      this.log(`Running: ${description}`, 'INFO');
      execSync(command, { stdio: 'inherit' });
      this.log(`✅ ${description} completed successfully`, 'SUCCESS');
      return true;
    } catch (error) {
      this.log(`❌ ${description} failed: ${error.message}`, 'ERROR');
      return false;
    }
  }

  async createDirectories() {
    const directories = [
      'uploads',
      'uploads/images',
      'uploads/certificates',
      'uploads/qr-codes'
    ];

    for (const dir of directories) {
      if (!fs.existsSync(dir)) {
        try {
          fs.mkdirSync(dir, { recursive: true });
          this.log(`✅ Created directory: ${dir}`, 'SUCCESS');
        } catch (error) {
          this.log(`❌ Failed to create directory ${dir}: ${error.message}`, 'ERROR');
        }
      } else {
        this.log(`⚠️ Directory already exists: ${dir}`, 'WARNING');
      }
    }
  }

  async installBackendDependencies() {
    return await this.runCommand('npm install', 'Installing backend dependencies');
  }

  async installFlutterDependencies() {
    return await this.runCommand('flutter pub get', 'Installing Flutter dependencies');
  }

  async createFirebaseConfigTemplate() {
    const firebaseConfigPath = 'firebase-service-account.json';
    if (!fs.existsSync(firebaseConfigPath)) {
      const template = {
        "type": "service_account",
        "project_id": "your-project-id",
        "private_key_id": "your-private-key-id",
        "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-xxxxx@your-project-id.iam.gserviceaccount.com",
        "client_id": "your-client-id",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxxxx%40your-project-id.iam.gserviceaccount.com"
      };

      try {
        fs.writeFileSync(firebaseConfigPath, JSON.stringify(template, null, 2));
        this.log('✅ Created Firebase config template', 'SUCCESS');
        this.log('⚠️ Please update firebase-service-account.json with your actual Firebase credentials', 'WARNING');
      } catch (error) {
        this.log(`❌ Failed to create Firebase config: ${error.message}`, 'ERROR');
      }
    } else {
      this.log('⚠️ Firebase config already exists', 'WARNING');
    }
  }

  async createEnvironmentTemplate() {
    const envPath = '.env';
    if (!fs.existsSync(envPath)) {
      const template = `# MongoDB Configuration
MONGO_URL=mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority
DB_NAME=MongoDataBase

# Server Configuration
SERVER_PORT=3000
NODE_ENV=development

# Security
JWT_SECRET=your-jwt-secret-key-here
BCRYPT_ROUNDS=10

# Email Configuration (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password

# Firebase Configuration (optional)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
`;

      try {
        fs.writeFileSync(envPath, template);
        this.log('✅ Created environment template', 'SUCCESS');
        this.log('⚠️ Please update .env with your actual configuration values', 'WARNING');
      } catch (error) {
        this.log(`❌ Failed to create environment file: ${error.message}`, 'ERROR');
      }
    } else {
      this.log('⚠️ Environment file already exists', 'WARNING');
    }
  }

  async validateMongoDBConnection() {
    try {
      this.log('Testing MongoDB connection...', 'INFO');
      const { MongoClient } = require('mongodb');
      require('dotenv').config();
      
      const uri = process.env.MONGO_URL || "mongodb://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority&connectTimeoutMS=0&socketTimeoutMS=0";
      const client = new MongoClient(uri);
      
      await client.connect();
      await client.db().admin().ping();
      await client.close();
      
      this.log('✅ MongoDB connection test passed', 'SUCCESS');
      return true;
    } catch (error) {
      this.log(`❌ MongoDB connection test failed: ${error.message}`, 'ERROR');
      this.log('⚠️ Please check your MongoDB Atlas connection string', 'WARNING');
      return false;
    }
  }

  async runFlutterDoctor() {
    return await this.runCommand('flutter doctor', 'Running Flutter doctor');
  }

  async generateFlutterAssets() {
    return await this.runCommand('flutter pub get', 'Generating Flutter assets');
  }

  async runCompleteSetup() {
    this.log('🚀 Starting Complete Setup for Eventura App', 'INFO');
    this.log('============================================', 'INFO');

    const setupSteps = [
      { name: 'Create Directories', step: () => this.createDirectories() },
      { name: 'Install Backend Dependencies', step: () => this.installBackendDependencies() },
      { name: 'Install Flutter Dependencies', step: () => this.installFlutterDependencies() },
      { name: 'Create Firebase Config Template', step: () => this.createFirebaseConfigTemplate() },
      { name: 'Create Environment Template', step: () => this.createEnvironmentTemplate() },
      { name: 'Validate MongoDB Connection', step: () => this.validateMongoDBConnection() },
      { name: 'Run Flutter Doctor', step: () => this.runFlutterDoctor() },
      { name: 'Generate Flutter Assets', step: () => this.generateFlutterAssets() },
    ];

    let completedSteps = 0;
    let totalSteps = setupSteps.length;

    for (const step of setupSteps) {
      this.log(`Running setup step: ${step.name}`, 'INFO');
      const result = await step.step();
      if (result) {
        completedSteps++;
      }
      this.log('', 'INFO');
    }

    this.log('============================================', 'INFO');
    this.log(`🎯 Setup Results: ${completedSteps}/${totalSteps} steps completed`, 'INFO');
    
    if (completedSteps === totalSteps) {
      this.log('🎉 SETUP COMPLETE! Eventura app is ready to run.', 'SUCCESS');
      this.log('', 'INFO');
      this.log('📋 Next Steps:', 'INFO');
      this.log('1. Update .env with your actual configuration', 'INFO');
      this.log('2. Update firebase-service-account.json with your Firebase credentials (optional)', 'INFO');
      this.log('3. Start the backend: npm start', 'INFO');
      this.log('4. Start the Flutter app: flutter run', 'INFO');
      this.log('5. Run tests: npm run test-full-stack', 'INFO');
    } else {
      this.log(`⚠️ ${totalSteps - completedSteps} step(s) failed. Please check the logs above.`, 'WARNING');
    }

    return completedSteps === totalSteps;
  }
}

// Run the setup if this file is executed directly
if (require.main === module) {
  const setup = new CompleteSetup();
  setup.runCompleteSetup().then(success => {
    process.exit(success ? 0 : 1);
  }).catch(error => {
    console.error('Setup failed:', error);
    process.exit(1);
  });
}

module.exports = CompleteSetup;
