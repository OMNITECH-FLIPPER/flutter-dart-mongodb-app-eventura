@echo off
echo Starting Eventura App with MongoDB Atlas connection...
echo.

echo Note: If connection fails, the app will use mock data for testing.
echo.

REM Set MongoDB Atlas connection string
set MONGO_URL=mongodb://KyleAngelo:KYLO.omni0@cluster0-shard-00-00.evanqft.mongodb.net:27017,cluster0-shard-00-01.evanqft.mongodb.net:27017,cluster0-shard-00-02.evanqft.mongodb.net:27017/MongoDataBase?ssl=true&replicaSet=atlas-14b8sh-shard-0&authSource=admin&retryWrites=true&w=majority

echo MongoDB URL: %MONGO_URL%
echo.

REM Get Flutter dependencies
echo Getting Flutter dependencies...
flutter pub get

echo.
echo Starting Flutter app with MongoDB Atlas connection...
echo.

REM Run the app with MongoDB Atlas connection
flutter run --dart-define=MONGO_URL="%MONGO_URL%"

pause 