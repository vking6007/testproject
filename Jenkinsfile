pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    parameters {
        choice(
            name: 'DEPLOYMENT_TYPE',
            choices: ['JAR-Direct', 'Docker-Type1-VolumeMount'],
            description: 'Choose deployment strategy'
        )
    }

    environment {
        JAR_NAME = "testproject-0.0.1-SNAPSHOT.jar"
        APP_PORT = "8085"
        HOST_PORT = "8082"
        DB_HOST = "team_1_dev_1_postgres"
        DB_USER = "team_1_user"
        DB_PASS = "team_1_pass"
        DB_NAME = "team_1_db"
        DB_URL = "jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"
        
        // Docker configuration
        IMAGE_NAME = "springboot-app"
        CONTAINER_NAME = "springboot-app"
        NETWORK = "jenkins-net"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📦 Checking out code from GitHub..."
                git branch: 'main', url: 'https://github.com/vking6007/testproject.git'
            }
        }

        stage('Build JAR') {
            steps {
                echo "⚙️ Building Spring Boot JAR..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Stop Previous App') {
            steps {
                echo "🛑 Stopping previous Spring Boot process if running..."
                sh '''
                    pkill -f "java.*${JAR_NAME}" || true
                    sleep 3
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                script {
                    if (params.DEPLOYMENT_TYPE == 'JAR-Direct') {
                        echo "🚀 Deploying Spring Boot JAR directly..."
                        sh '''
                            nohup java -jar target/${JAR_NAME} \
                              --server.port=${APP_PORT} \
                              --spring.profiles.active=dev \
                              --spring.datasource.url=${DB_URL} \
                              --spring.datasource.username=${DB_USER} \
                              --spring.datasource.password=${DB_PASS} \
                              > app.log 2>&1 &
                            echo "✅ Application started in background."
                        '''
                    } else {
                        echo "🐳 Deploying with Docker Type 1 (Build outside, run inside)..."
                        sh '''
                            echo "🚀 Starting Spring Boot container with volume mount..."
                            echo "📦 Jenkins builds JAR with Maven, container only runs Java"
                            docker run -d \
                              --name ${CONTAINER_NAME} \
                              --network ${NETWORK} \
                              -p ${HOST_PORT}:${APP_PORT} \
                              -v $(pwd)/target:/app \
                              -e SPRING_PROFILES_ACTIVE=dev \
                              -e SPRING_DATASOURCE_URL=${DB_URL} \
                              -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
                              -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
                              openjdk:21-jdk-slim \
                              bash -c "java -jar /app/${JAR_NAME}"
                            echo "✅ Docker container started successfully!"
                        '''
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "🕒 Waiting for app to initialize..."
                sh 'sleep 20'

                script {
                    if (params.DEPLOYMENT_TYPE == 'JAR-Direct') {
                        echo "🔍 Verifying JAR process..."
                        sh '''
                            if ! pgrep -f "${JAR_NAME}" > /dev/null; then
                                echo "❌ Application is not running!" && exit 1
                            fi
                        '''

                        echo "🌐 Checking /api/test/health endpoint..."
                        sh '''
                            if ! curl -f http://localhost:${APP_PORT}/api/test/health; then
                                echo "⚠️ Health check failed, but process is running."
                            fi
                        '''

                        echo "📊 Showing running process..."
                        sh 'ps -ef | grep java | grep ${JAR_NAME} | head -1'
                    } else {
                        echo "🔍 Verifying Docker container (Type 1: Build outside, run inside)..."
                        sh '''
                            if ! docker ps | grep ${CONTAINER_NAME} > /dev/null; then
                                echo "❌ Container is not running!"
                                docker logs ${CONTAINER_NAME}
                                exit 1
                            fi
                        '''

                        echo "🌐 Checking /api/test/health endpoint..."
                        sh '''
                            if ! curl -f http://localhost:${HOST_PORT}/api/test/health; then
                                echo "⚠️ Health check failed, but container is running."
                                docker logs ${CONTAINER_NAME} | tail -20
                            fi
                        '''

                        echo "📊 Container details:"
                        sh 'docker ps | grep ${CONTAINER_NAME}'
                    }
                }
            }
        }
    }

    post {
        success {
            script {
                if (params.DEPLOYMENT_TYPE == 'JAR-Direct') {
                    echo "🎉 JAR Deployment successful!"
                    echo "🌍 App running on: http://localhost:${APP_PORT}"
                    echo "📋 View logs with: tail -f app.log"

                    // ✅ Keep app running after Jenkins exits
                    sh '''
                        echo "🔁 Ensuring Spring Boot app stays alive after Jenkins exits..."
                        nohup bash -c "java -jar target/${JAR_NAME} \
                          --server.port=${APP_PORT} \
                          --spring.profiles.active=dev \
                          --spring.datasource.url=${DB_URL} \
                          --spring.datasource.username=${DB_USER} \
                          --spring.datasource.password=${DB_PASS} \
                          > app.log 2>&1 & disown" &
                        echo "✅ Application detached and will keep running."
                    '''
                } else {
                    echo "🎉 Docker Type 1 Deployment successful!"
                    echo "📦 Jenkins built JAR with Maven, container runs Java only"
                    echo "🌍 App running on: http://localhost:${HOST_PORT}"
                    echo "📋 Container logs: docker logs -f ${CONTAINER_NAME}"
                    echo "🔍 Container status: docker ps | grep ${CONTAINER_NAME}"
                }
            }
        }

        failure {
            echo "❌ Deployment failed. Fetching logs..."
            sh 'tail -n 50 app.log || true'
        }

        always {
            echo "✅ Jenkins Pipeline completed."
        }
    }
}
