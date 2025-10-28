#!/bin/bash

# Post-build script to start Spring Boot application
# This script runs after Jenkins pipeline completion to ensure the app keeps running

# Define variables
JAR_NAME="testproject-0.0.1-SNAPSHOT.jar"
APP_PORT="8085"
DB_HOST="team_1_dev_1_postgres"
DB_USER="team_1_user"
DB_PASS="team_1_pass"
DB_NAME="team_1_db"
DB_URL="jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"

# Get the workspace directory (Jenkins sets this)
WORKSPACE_DIR=${WORKSPACE:-$(pwd)}

echo "=== Post-Build Spring Boot Application Starter ==="
echo "Workspace: $WORKSPACE_DIR"
echo "JAR: $JAR_NAME"
echo "Port: $APP_PORT"

# Navigate to workspace
cd "$WORKSPACE_DIR" || exit 1

# Check if JAR exists
if [ ! -f "target/${JAR_NAME}" ]; then
    echo "❌ JAR file not found: target/${JAR_NAME}"
    echo "Available files in target/:"
    ls -la target/ || echo "target/ directory not found"
    exit 1
fi

# Stop any existing application
echo "🛑 Stopping any existing application..."
pkill -f "java.*-jar.*target/${JAR_NAME}" || true
pkill -f "java.*testproject.*jar" || true
sleep 3

# Start the application
echo "🚀 Starting Spring Boot application..."
nohup java -jar target/${JAR_NAME} \
  --server.port=${APP_PORT} \
  --spring.profiles.active=dev \
  --spring.datasource.url=${DB_URL} \
  --spring.datasource.username=${DB_USER} \
  --spring.datasource.password=${DB_PASS} \
  > app.log 2>&1 &

# Get the process ID
APP_PID=$!

# Disown the process so it survives Jenkins cleanup
disown

echo "✅ Application started successfully!"
echo "📋 Process ID: $APP_PID"
echo "🌐 Application URL: http://localhost:${APP_PORT}"
echo "📝 Log file: $WORKSPACE_DIR/app.log"
echo "🔍 Check status with: ps aux | grep $APP_PID"

# Wait a moment and verify it's running
sleep 5

if kill -0 $APP_PID 2>/dev/null; then
    echo "✅ Application is running (PID: $APP_PID)"
    
    # Try to do a health check
    echo "🔍 Performing health check..."
    if curl -f http://localhost:${APP_PORT}/api/test/health >/dev/null 2>&1; then
        echo "✅ Health check passed!"
    else
        echo "⚠️ Health check failed, but application is running"
    fi
else
    echo "❌ Application failed to start"
    echo "📋 Last 20 lines of log:"
    tail -20 app.log
    exit 1
fi

echo "🎉 Post-build deployment complete!"
