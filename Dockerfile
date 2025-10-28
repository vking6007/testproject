# Type 2: Build Inside Container Approach
# This Dockerfile packages the app + Java together

# Use base image with Java 21
FROM openjdk:21-jdk-slim

# Set working directory
WORKDIR /app

# Copy the jar file (built by Jenkins or Maven)
COPY target/testproject-0.0.1-SNAPSHOT.jar app.jar

# Expose port
EXPOSE 8085

# Set timezone
ENV TZ=UTC

# Run the jar
ENTRYPOINT ["java", "-jar", "app.jar"]