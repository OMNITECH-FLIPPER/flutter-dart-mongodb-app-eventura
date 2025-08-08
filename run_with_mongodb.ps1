# Eventura App - Run with MongoDB Atlas
Write-Host "Starting Eventura App with MongoDB Atlas connection..." -ForegroundColor Green
Write-Host ""

Write-Host "Note: If connection fails, the app will use mock data for testing." -ForegroundColor Yellow
Write-Host ""

# MongoDB Atlas connection string
$MONGO_URL = "mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority"

Write-Host "MongoDB URL: $MONGO_URL" -ForegroundColor Cyan
Write-Host ""

# Get Flutter dependencies
Write-Host "Getting Flutter dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "Starting Flutter app with MongoDB Atlas connection..." -ForegroundColor Green
Write-Host ""

# Run the app with MongoDB Atlas connection
flutter run --dart-define=MONGO_URL="$MONGO_URL"

Write-Host ""
Write-Host "App finished running." -ForegroundColor Green
Read-Host "Press Enter to exit" 