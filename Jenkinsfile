pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    environment {
        IMAGE_NAME = "team1-springboot-app"
        CONTAINER_NAME = "team1-springboot-app"
        NETWORK = "jenkins-net"
        DB_HOST = "team_1_dev_1_postgres"
        DB_USER = "team_1_user"
        DB_PASS = "team_1_pass"
        DB_NAME = "team_1_db"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/vking6007/testproject.git'
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME} .'
            }
        }

        stage('Deploy Container') {
            steps {
                sh '''
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      --network ${NETWORK} \
                      -p 8082:8085 \
                      -e SPRING_PROFILES_ACTIVE=dev \
                      ${IMAGE_NAME}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'docker ps | grep ${CONTAINER_NAME}'
                sh 'sleep 15'
                sh 'curl -f http://localhost:8082/api/test/health || echo "Health check failed"'
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline finished."
        }
        success {
            echo "🎉 Deployment successful! App is running on http://localhost:8082"
            echo "🔗 Internal container communication: http://team1-springboot-app:8085"
        }
        failure {
            echo "❌ Deployment failed. Check logs for details."
        }
    }
}

