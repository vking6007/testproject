#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Define variables
JAR_NAME="testproject-0.0.1-SNAPSHOT.jar"
APP_PORT="8085"
HOST_PORT="8082"
DB_HOST="team_1_dev_1_postgres"
DB_USER="team_1_user"
DB_PASS="team_1_pass"
DB_NAME="team_1_db"
DB_URL="jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"

echo "=== Spring Boot JAR Deployment Script ==="

# --- Build JAR ---
echo "--- Building JAR file ---"
mvn clean package -DskipTests

# --- Stop Previous App ---
echo "--- Stopping previous application (if running) ---"
# Find and stop only our specific Spring Boot application
pkill -f "java.*-jar.*target/${JAR_NAME}" || true
# Alternative: stop by specific command pattern
pkill -f "java.*testproject.*jar" || true
sleep 3

# --- Deploy JAR ---
echo "--- Starting Spring Boot application ---"
nohup java -jar target/${JAR_NAME} \
  --server.port=${APP_PORT} \
  --spring.profiles.active=dev \
  --spring.datasource.url=${DB_URL} \
  --spring.datasource.username=${DB_USER} \
  --spring.datasource.password=${DB_PASS} \
  > app.log 2>&1 &

echo "--- Application started in background ---"
echo "--- Process ID: $! ---"

# --- Wait for startup ---
echo "--- Waiting for application to start (20 seconds) ---"
sleep 20

# --- Verify Deployment ---
echo "--- Verifying application status ---"
if pgrep -f "java.*-jar.*target/${JAR_NAME}" > /dev/null; then
    echo "✅ Application is running"
    echo "📊 Process details:"
    ps aux | grep java | grep "target/${JAR_NAME}" | head -1
else
    echo "❌ Application is not running!"
    echo "📋 Last 50 lines of log:"
    tail -50 app.log
    exit 1
fi

# --- Health Check ---
echo "--- Performing health check ---"
if curl -f http://localhost:${APP_PORT}/api/test/health; then
    echo "✅ Health check passed!"
else
    echo "⚠️ Health check failed!"
    echo "📋 Last 50 lines of log:"
    tail -50 app.log
    exit 1
fi

echo "--- Deployment complete! Application is running on http://localhost:${APP_PORT} ---"
echo "📋 Check logs with: tail -f app.log"
echo "🛑 Stop application with: pkill -f 'java.*${JAR_NAME}'"
