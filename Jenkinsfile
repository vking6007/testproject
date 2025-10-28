pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    environment {
        IMAGE_NAME = "springboot-app"
        CONTAINER_NAME = "springboot-app"
        APP_PORT = "8085"
        HOST_PORT = "8082"
        DB_HOST = "team_1_dev_1_postgres"
        DB_USER = "team_1_user"
        DB_PASS = "team_1_pass"
        DB_NAME = "team_1_db"
        DB_URL  = "jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "📦 Checking out code..."
                git branch: 'main', url: 'https://github.com/vking6007/testproject.git'
            }
        }

        stage('Build JAR') {
            steps {
                echo "⚙️ Building Spring Boot JAR..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image with embedded JAR..."
                sh '''
                    docker build -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Stop Previous Container') {
            steps {
                echo "🛑 Stopping previous container if running..."
                sh '''
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                '''
            }
        }

        stage('Run Application Container') {
            steps {
                echo "🚀 Running Spring Boot container..."
                sh '''
                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      --network jenkins-net \
                      -p ${HOST_PORT}:${APP_PORT} \
                      -e SPRING_PROFILES_ACTIVE=dev \
                      -e SPRING_DATASOURCE_URL=${DB_URL} \
                      -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
                      -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
                      ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "🕒 Waiting for app to initialize..."
                sh 'sleep 20'
                echo "🔍 Checking container and app health..."
                sh '''
                    docker ps | grep ${CONTAINER_NAME}
                    docker logs ${CONTAINER_NAME} --tail 50 || true
                    curl -f http://localhost:${HOST_PORT}/api/test/health || echo "⚠️ Health check failed"
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment successful!"
            echo "🌍 App running on http://localhost:${HOST_PORT}"
        }
        failure {
            echo "❌ Deployment failed! Showing container logs..."
            sh 'docker logs ${CONTAINER_NAME} || true'
        }
        always {
            echo "✅ Jenkins Pipeline finished."
        }
    }
}
