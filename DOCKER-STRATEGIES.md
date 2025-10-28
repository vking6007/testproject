# Docker Deployment Strategies

This document explains the two Docker deployment strategies for the Spring Boot application.

## 🟩 Type 1: Build Outside, Run Inside (Recommended)

### **When to Use:**
- Jenkins already has Maven and Java configured
- You want faster builds (no need to rebuild Docker image)
- You prefer volume mounts for flexibility

### **What It Needs:**
- ✅ **Jenkins**: Maven + Java (already configured)
- ✅ **Docker Container**: Java only (`openjdk:21-jdk-slim`)

### **How It Works:**
1. Jenkins builds JAR with Maven
2. Docker container mounts the `target/` directory
3. Container runs Java to execute the JAR

### **Usage:**
```bash
# Build JAR first
mvn clean package -DskipTests

# Run with volume mount
./docker-run.sh
```

### **Docker Command:**
```bash
docker run -d \
  --name springboot-app \
  --network jenkins-net \
  -p 8082:8085 \
  -v $(pwd)/target:/app \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://team_1_dev_1_postgres:5432/team_1_db \
  -e SPRING_DATASOURCE_USERNAME=team_1_user \
  -e SPRING_DATASOURCE_PASSWORD=team_1_pass \
  openjdk:21-jdk-slim \
  bash -c "java -jar /app/testproject-0.0.1-SNAPSHOT.jar"
```

---

## 🟩 Type 2: Build Inside Container (Dockerfile)

### **When to Use:**
- You want a self-contained Docker image
- You need to deploy the same image across different environments
- You prefer immutable deployments

### **What It Needs:**
- ✅ **Jenkins**: Maven + Java (to build JAR)
- ✅ **Docker Container**: Java only (packaged in image)

### **How It Works:**
1. Jenkins builds JAR with Maven
2. Dockerfile copies JAR into image
3. Container runs the pre-packaged JAR

### **Usage:**
```bash
# Build and run with Dockerfile
./docker-build-and-run.sh

# Or use docker-compose
docker-compose -f docker-compose-dockerfile.yml up --build
```

### **Dockerfile:**
```dockerfile
FROM openjdk:21-jdk-slim
WORKDIR /app
COPY target/testproject-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]
```

---

## 🔄 Jenkins Pipeline Integration

### **Parameterized Pipeline:**
The `Jenkinsfile-Docker` supports both strategies with a parameter:

```groovy
parameters {
    choice(
        name: 'DOCKER_STRATEGY',
        choices: ['Type1-VolumeMount', 'Type2-Dockerfile'],
        description: 'Choose Docker deployment strategy'
    )
}
```

### **Usage in Jenkins:**
1. Create a new Pipeline job
2. Use `Jenkinsfile-Docker` as the pipeline script
3. Choose your preferred strategy when running the build

---

## 🚀 Quick Start

### **Type 1 (Volume Mount):**
```bash
# 1. Build JAR
mvn clean package -DskipTests

# 2. Run container
./docker-run.sh
```

### **Type 2 (Dockerfile):**
```bash
# 1. Build and run
./docker-build-and-run.sh

# 2. Or use docker-compose
docker-compose -f docker-compose-dockerfile.yml up --build
```

---

## 📊 Comparison

| Feature | Type 1 (Volume Mount) | Type 2 (Dockerfile) |
|---------|----------------------|---------------------|
| **Build Speed** | ⚡ Faster (no image rebuild) | 🐌 Slower (rebuild image) |
| **Portability** | ⚠️ Requires volume mount | ✅ Self-contained |
| **Flexibility** | ✅ Easy to update JAR | ⚠️ Need to rebuild image |
| **Deployment** | ⚠️ Requires target/ directory | ✅ Single image file |
| **Resource Usage** | 💚 Lower (shared base image) | 💛 Higher (custom image) |

---

## 🎯 Recommendation

**Use Type 1 (Volume Mount)** for:
- Development and testing
- CI/CD pipelines where speed matters
- When you frequently update the application

**Use Type 2 (Dockerfile)** for:
- Production deployments
- When you need to distribute the application
- When you want immutable deployments
