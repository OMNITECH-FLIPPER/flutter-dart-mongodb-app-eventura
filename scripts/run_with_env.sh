#!/bin/bash

# Bash script to run Flutter app with environment variables
# Usage: ./scripts/run_with_env.sh

# Default values
MONGO_URL=${MONGO_URL:-"mongodb+srv://KyleAngelo:KYLO.omni0@cluster0.evanqft.mongodb.net/MongoDataBase?retryWrites=true&w=majority"}
COLLECTION_NAME=${COLLECTION_NAME:-"users"}
APP_NAME=${APP_NAME:-"Eventura"}
APP_VERSION=${APP_VERSION:-"1.0.0"}
ENABLE_ANALYTICS=${ENABLE_ANALYTICS:-"true"}
ENABLE_NOTIFICATIONS=${ENABLE_NOTIFICATIONS:-"true"}
CONNECTION_TIMEOUT=${CONNECTION_TIMEOUT:-"30000"}
REQUEST_TIMEOUT=${REQUEST_TIMEOUT:-"10000"}

echo "Running Eventura Flutter app with environment variables..."
echo "MongoDB URL: ${MONGO_URL%@*}@***"
echo "Collection Name: $COLLECTION_NAME"
echo "App Name: $APP_NAME"

flutter run \
  --dart-define=MONGO_URL="$MONGO_URL" \
  --dart-define=COLLECTION_NAME="$COLLECTION_NAME" \
  --dart-define=APP_NAME="$APP_NAME" \
  --dart-define=APP_VERSION="$APP_VERSION" \
  --dart-define=ENABLE_ANALYTICS=$ENABLE_ANALYTICS \
  --dart-define=ENABLE_NOTIFICATIONS=$ENABLE_NOTIFICATIONS \
  --dart-define=CONNECTION_TIMEOUT=$CONNECTION_TIMEOUT \
  --dart-define=REQUEST_TIMEOUT=$REQUEST_TIMEOUT 