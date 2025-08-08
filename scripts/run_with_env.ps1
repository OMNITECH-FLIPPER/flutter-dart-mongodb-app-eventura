# PowerShell script to run Flutter app with environment variables
# Usage: .\scripts\run_with_env.ps1

param(
    [string]$MongoUrl = "mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority",
    [string]$CollectionName = "users",
    [string]$AppName = "Eventura",
    [string]$AppVersion = "1.0.0",
    [string]$EnableAnalytics = "true",
    [string]$EnableNotifications = "true",
    [string]$ConnectionTimeout = "30000",
    [string]$RequestTimeout = "10000"
)

Write-Host "Running Eventura Flutter app with environment variables..." -ForegroundColor Green
Write-Host "MongoDB URL: $($MongoUrl.Substring(0, $MongoUrl.IndexOf('@') + 1))***" -ForegroundColor Yellow
Write-Host "Collection Name: $CollectionName" -ForegroundColor Yellow
Write-Host "App Name: $AppName" -ForegroundColor Yellow

$dartDefines = @(
    "--dart-define=MONGO_URL=`"$MongoUrl`"",
    "--dart-define=COLLECTION_NAME=`"$CollectionName`"",
    "--dart-define=APP_NAME=`"$AppName`"",
    "--dart-define=APP_VERSION=`"$AppVersion`"",
    "--dart-define=ENABLE_ANALYTICS=$EnableAnalytics",
    "--dart-define=ENABLE_NOTIFICATIONS=$EnableNotifications",
    "--dart-define=CONNECTION_TIMEOUT=$ConnectionTimeout",
    "--dart-define=REQUEST_TIMEOUT=$RequestTimeout"
)

$command = "flutter run " + ($dartDefines -join " ")
Write-Host "Executing: $command" -ForegroundColor Cyan

Invoke-Expression $command 