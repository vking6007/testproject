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
        CONTAINER_NAME = "springboot-app-${params.ENVIRONMENT}"
        APP_PORT = "8085"
        HOST_PORT = "${params.ENVIRONMENT == 'prod' ? '8086' : '8082'}"

        DB_HOST = "${params.ENVIRONMENT == 'prod' ? 'team_1_prod_postgres' : 'team_1_dev_1_postgres'}"
        DB_NAME = "${params.ENVIRONMENT == 'prod' ? 'team_1_prod_db' : 'team_1_db'}"
        DB_USER = "${params.ENVIRONMENT == 'prod' ? 'team_1_prod_user' : 'team_1_user'}"
        DB_PASS = "${params.ENVIRONMENT == 'prod' ? 'team_1_prod_pass' : 'team_1_pass'}"
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
                echo "⚙️ Building Spring Boot JAR for ${params.ENVIRONMENT}..."
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image for ${params.ENVIRONMENT}..."
                sh 'docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT} .'
            }
        }

        stage('Stop Previous Container') {
            steps {
                echo "🛑 Stopping previous ${params.ENVIRONMENT} container..."
                sh '''
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                '''
            }
        }

        stage('Run New Container') {
            steps {
                echo "🚀 Deploying Spring Boot app for ${params.ENVIRONMENT}..."
                sh '''
                    docker run -d \
                      --name ${CONTAINER_NAME} \
                      --network jenkins-net \
                      -p ${HOST_PORT}:${APP_PORT} \
                      -e SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT} \
                      -e SPRING_DATASOURCE_URL=${DB_URL} \
                      -e SPRING_DATASOURCE_USERNAME=${DB_USER} \
                      -e SPRING_DATASOURCE_PASSWORD=${DB_PASS} \
                      ${IMAGE_NAME}:${params.ENVIRONMENT}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "🕒 Waiting for ${params.ENVIRONMENT} app to start..."
                sh 'sleep 20'

                echo "🔍 Checking container and health..."
                sh '''
                    docker ps | grep ${CONTAINER_NAME} || (echo "❌ Container not running!" && exit 1)
                    docker exec ${CONTAINER_NAME} curl -f http://localhost:${APP_PORT}/api/test/health \
                    || (echo "⚠️ Health check failed!" && exit 1)
                '''
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
