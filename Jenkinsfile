pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Select deployment environment')
    }

    environment {
        IMAGE_NAME = "springboot-app"
        APP_PORT = "8085"
    }

    stages {
        stage('Initialize Environment Variables') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'prod') {
                        env.CONTAINER_NAME = "springboot-app-prod"
                        env.HOST_PORT = "8086"
                        env.DB_HOST = "team_1_prod_postgres"
                        env.DB_NAME = "team_1_prod_db"
                        env.DB_USER = "team_1_prod_user"
                        env.DB_PASS = "team_1_prod_pass"
                    } else {
                        env.CONTAINER_NAME = "springboot-app-dev"
                        env.HOST_PORT = "8082"
                        env.DB_HOST = "team_1_dev_1_postgres"
                        env.DB_NAME = "team_1_db"
                        env.DB_USER = "team_1_user"
                        env.DB_PASS = "team_1_pass"
                    }
                    env.DB_URL = "jdbc:postgresql://${env.DB_HOST}:5432/${env.DB_NAME}"
                }
                echo "🌍 Initialized environment for: ${params.ENVIRONMENT}"
                echo "   Container: ${env.CONTAINER_NAME}"
                echo "   Database:  ${env.DB_URL}"
                echo "   Port:      ${env.HOST_PORT}"
            }
        }

        stage('Checkout Code') {
            steps {
                echo "📦 Checking out code..."
                git branch: 'main', url: 'https://github.com/vking6007/testproject.git'
            }
        }

        stage('Build JAR') {
            steps {
                echo "⚙️ Building Spring Boot JAR for ${params.ENVIRONMENT}..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image for ${params.ENVIRONMENT}..."
                sh "docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT} ."
            }
        }

        stage('Stop Previous Container') {
            steps {
                echo "🛑 Stopping previous ${params.ENVIRONMENT} container..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Run New Container') {
            steps {
                echo "🚀 Deploying Spring Boot app for ${params.ENVIRONMENT}..."
                sh """
                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      --network jenkins-net \
                      -p ${HOST_PORT}:${APP_PORT} \
                      -e SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT} \
                      -e SPRING_DATASOURCE_URL=${DB_URL} \
                      -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
                      -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
                      ${IMAGE_NAME}:${params.ENVIRONMENT}
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "🕒 Waiting for ${params.ENVIRONMENT} app to start..."
                sh 'sleep 20'

                echo "🔍 Checking container and health..."
                sh """
                    docker ps | grep ${CONTAINER_NAME} || (echo "❌ Container not running!" && exit 1)
                    docker exec ${CONTAINER_NAME} curl -f http://localhost:${APP_PORT}/api/test/health \
                    || (echo "⚠️ Health check failed!" && exit 1)
                """
            }
        }
    }

    post {
        success {
            echo "🎉 ${params.ENVIRONMENT.toUpperCase()} Deployment Successful!"
            echo "🌍 App running at: http://localhost:${HOST_PORT}"
        }
        failure {
            echo "❌ ${params.ENVIRONMENT.toUpperCase()} Deployment Failed!"
            sh 'docker logs ${CONTAINER_NAME} || true'
        }
        always {
            echo "✅ Jenkins Pipeline finished for ${params.ENVIRONMENT.toUpperCase()}."
        }
    }
}
