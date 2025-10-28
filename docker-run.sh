#!/bin/bash

# Type 1: Build outside, run inside Docker
# Jenkins builds JAR with Maven, then container only runs Java

set -e

# Configuration
CONTAINER_NAME="springboot-app"
NETWORK="jenkins-net"
HOST_PORT="8082"
CONTAINER_PORT="8085"
JAR_NAME="testproject-0.0.1-SNAPSHOT.jar"

# Database Configuration
DB_HOST="team_1_dev_1_postgres"
DB_USER="team_1_user"
DB_PASS="team_1_pass"
DB_NAME="team_1_db"
DB_URL="jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"

echo "🐳 Type 1: Build Outside, Run Inside Docker"
echo "=============================================="

# Stop and remove existing container
echo "🛑 Stopping existing container..."
docker stop ${CONTAINER_NAME} || true
docker rm ${CONTAINER_NAME} || true

# Ensure target directory exists
if [ ! -f "target/${JAR_NAME}" ]; then
    echo "❌ JAR file not found: target/${JAR_NAME}"
    echo "Please run 'mvn clean package' first"
    exit 1
fi

echo "✅ JAR file found: target/${JAR_NAME}"

# Run container with volume mount
echo "🚀 Starting Spring Boot container..."
docker run -d \
  --name ${CONTAINER_NAME} \
  --network ${NETWORK} \
  -p ${HOST_PORT}:${CONTAINER_PORT} \
  -v $(pwd)/target:/app \
  -e SPRING_PROFILES_ACTIVE=dev \
  -e SPRING_DATASOURCE_URL=${DB_URL} \
  -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
  -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
  openjdk:21-jdk-slim \
  bash -c "java -jar /app/${JAR_NAME}"

echo "✅ Container started successfully!"
echo "🌍 Application URL: http://localhost:${HOST_PORT}"
echo "📋 Container logs: docker logs -f ${CONTAINER_NAME}"
echo "🔍 Container status: docker ps | grep ${CONTAINER_NAME}"
