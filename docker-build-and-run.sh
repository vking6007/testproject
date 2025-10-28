#!/bin/bash

# Type 2: Build Inside Container (Dockerfile Approach)
# Creates a custom image with app + Java pre-packaged

set -e

# Configuration
IMAGE_NAME="springboot-app"
CONTAINER_NAME="springboot-app"
NETWORK="jenkins-net"
HOST_PORT="8082"
CONTAINER_PORT="8085"

# Database Configuration
DB_HOST="team_1_dev_1_postgres"
DB_USER="team_1_user"
DB_PASS="team_1_pass"
DB_NAME="team_1_db"
DB_URL="jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"

echo "🐳 Type 2: Build Inside Container (Dockerfile)"
echo "=============================================="

# Build JAR first
echo "⚙️ Building JAR file..."
mvn clean package -DskipTests

# Check if JAR exists
if [ ! -f "target/testproject-0.0.1-SNAPSHOT.jar" ]; then
    echo "❌ JAR file not found after build"
    exit 1
fi

echo "✅ JAR file built successfully"

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t ${IMAGE_NAME} .

# Stop and remove existing container
echo "🛑 Stopping existing container..."
docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true

# Run container
echo "🚀 Starting Spring Boot container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  --network ${NETWORK} \
  -p ${HOST_PORT}:${CONTAINER_PORT} \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e SPRING_DATASOURCE_URL=${DB_URL} \
  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
  -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
  ${IMAGE_NAME}

echo "✅ Container started successfully!"
echo "🌍 Application URL: http://localhost:${HOST_PORT}"
echo "📋 Container logs: docker logs -f ${CONTAINER_NAME}"
echo "🔍 Container status: docker ps | grep ${CONTAINER_NAME}"
