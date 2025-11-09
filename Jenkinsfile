pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    // Parameter appears only for manual builds
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['none', 'dev', 'prod'], description: 'Choose environment for deployment (none = build only)')
    }

    environment {
        PROJECT = "team1"
        APP_PORT = "8085"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📦 Checking out branch: ${env.BRANCH_NAME}"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: "*/${env.BRANCH_NAME}"]],
                    userRemoteConfigs: [[url: 'https://github.com/vking6007/testproject.git']]
                ])
            }
        }

        stage('Initialize Environment Variables') {
            steps {
                script {
                    env.SAFE_BRANCH = env.BRANCH_NAME.replaceAll('/', '-')
                    env.IMAGE_NAME = "${PROJECT}-${env.SAFE_BRANCH}-springboot-app"

                    // Default build-only mode
                    if (params.ENVIRONMENT == 'prod') {
                        env.CONTAINER_NAME = "${PROJECT}-${env.SAFE_BRANCH}-springboot-prod"
                        env.HOST_PORT = "8086"
                        env.DB_HOST = "team_1_prod_postgres"
                        env.DB_NAME = "team_1_prod_db"
                        CRED_ID = "team1_prod_credentials"
                    } else {
                        env.CONTAINER_NAME = "${PROJECT}-${env.SAFE_BRANCH}-springboot-dev"
                        env.HOST_PORT = "8082"
                        env.DB_HOST = "team_1_dev_1_postgres"
                        env.DB_NAME = "team_1_db"
                        CRED_ID = "team1_dev_credentials"
                    }

                    env.DB_URL = "jdbc:postgresql://${env.DB_HOST}:5432/${env.DB_NAME}"

                    echo """
                    🌿 Branch: ${env.BRANCH_NAME}
                    🌍 Environment: ${params.ENVIRONMENT}
                    📦 Image: ${env.IMAGE_NAME}
                    🧱 Container: ${env.CONTAINER_NAME}
                    🗄 DB_URL: ${env.DB_URL}
                    """
                }
            }
        }

        stage('Build JAR') {
            steps {
                echo "⚙️ Building Spring Boot JAR..."
                sh 'mvn clean package -DskipTests'
                echo "✅ JAR built successfully"
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh "docker build -t ${IMAGE_NAME}:${params.ENVIRONMENT == 'none' ? 'build' : params.ENVIRONMENT} ."
                echo "✅ Docker image built successfully"
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo "🗂 Archiving JAR file..."
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }

        // Deploy stages will only run when ENVIRONMENT != 'none'
        stage('Stop Previous Container') {
            when { expression { return params.ENVIRONMENT != 'none' } }
            steps {
                echo "🛑 Stopping old container if exists..."
                sh """
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true
                """
            }
        }

        stage('Run New Container') {
            when { expression { return params.ENVIRONMENT != 'none' } }
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: CRED_ID,
                                                      usernameVariable: 'DB_USER',
                                                      passwordVariable: 'DB_PASS')]) {

                        echo "🚀 Deploying branch ${env.BRANCH_NAME} to ${params.ENVIRONMENT}..."

                        sh """
                            if docker ps --format '{{.Ports}}' | grep -q ':${HOST_PORT}->'; then
                              echo "⚠️ Port ${HOST_PORT} in use. Stopping container..."
                              docker ps --format '{{.ID}} {{.Ports}}' | grep ':${HOST_PORT}->' | awk '{print \$1}' | xargs -r docker stop
                            fi

                            docker run -d \
                              --name ${CONTAINER_NAME} \
                              --network jenkins-net \
                              -p ${HOST_PORT}:${APP_PORT} \
                              -e SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT} \
                              -e SPRING_DATASOURCE_URL=${DB_URL} \
                              -e SPRING_DATASOURCE_USERNAME=$DB_USER \
                              -e SPRING_DATASOURCE_PASSWORD=$DB_PASS \
                              ${IMAGE_NAME}:${params.ENVIRONMENT}
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            when { expression { return params.ENVIRONMENT != 'none' } }
            steps {
                echo "🕒 Waiting for app startup..."
                sh 'sleep 15'

                echo "🔍 Checking container health..."
                sh """
                    if docker exec ${CONTAINER_NAME} curl -fsS http://localhost:${APP_PORT}/api/test/health; then
                      echo "✅ Health check passed successfully!"
                    else
                      echo "❌ Health check failed!"
                      docker logs ${CONTAINER_NAME}
                      exit 1
                    fi
                """
            }
        }

        stage('Summary') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'none') {
                        echo """
                        ✅ Build-only mode completed for branch '${env.BRANCH_NAME}'
                        🔹 Docker image: ${IMAGE_NAME}:build
                        🔹 No deployment performed automatically.
                        """
                    } else {
                        echo """
                        🎉 Successfully deployed '${env.BRANCH_NAME}' to ${params.ENVIRONMENT}
                        🌍 URL: http://168.220.248.40:${HOST_PORT}
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Jenkins pipeline completed successfully for branch ${env.BRANCH_NAME} (${params.ENVIRONMENT})"
        }
        failure {
            echo "❌ Pipeline failed for branch ${env.BRANCH_NAME} (${params.ENVIRONMENT})"
            sh 'docker logs ${CONTAINER_NAME} || true'
        }
        always {
            echo "📦 Pipeline finished execution."
        }
    }
}
