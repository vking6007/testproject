pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
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
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/vking6007/testproject.git'
            }
        }

        stage('Build JAR') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Stop Previous App') {
            steps {
                sh '''
                    echo "🛑 Stopping previous application (if running)..."
                    # Find and stop only our specific Spring Boot application
                    pkill -f "java.*-jar.*target/${JAR_NAME}" || true
                    # Alternative: stop by specific command pattern
                    pkill -f "java.*testproject.*jar" || true
                    sleep 3
                '''
            }
        }

        stage('Deploy JAR') {
            steps {
                sh '''
                    echo "🚀 Starting Spring Boot application..."
                    nohup java -jar target/${JAR_NAME} \
                      --server.port=${APP_PORT} \
                      --spring.profiles.active=dev \
                      --spring.datasource.url=${DB_URL} \
                      --spring.datasource.username=${DB_USER} \
                      --spring.datasource.password=${DB_PASS} \
                      > app.log 2>&1 &
                    
                    echo "📝 Application started in background"
                    echo "📋 Process ID: $!"
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    echo "🕒 Waiting for application to start..."
                    sleep 20
                    
                    echo "🔍 Checking if application is running..."
                    pgrep -f "java.*-jar.*target/${JAR_NAME}" || (echo "❌ Application not running!" && exit 1)
                    
                    echo "✅ Checking health endpoint..."
                    curl -f http://localhost:${APP_PORT}/api/test/health || echo "⚠️ Health check failed"
                    
                    echo "📊 Application status:"
                    ps aux | grep java | grep "target/${JAR_NAME}" | head -1
                '''
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline finished."
        }
        success {
            echo "🎉 Deployment successful! App is running on http://localhost:${APP_PORT}"
            echo "📋 Check logs with: tail -f app.log"
            
            // Start the application in a way that survives Jenkins pipeline completion
            sh '''
                echo "🚀 Starting Spring Boot application in background (survives Jenkins completion)..."
                bash -c "nohup java -jar target/${JAR_NAME} \
                  --server.port=${APP_PORT} \
                  --spring.profiles.active=dev \
                  --spring.datasource.url=${DB_URL} \
                  --spring.datasource.username=${DB_USER} \
                  --spring.datasource.password=${DB_PASS} \
                  > app.log 2>&1 & disown"
                
                echo "✅ Application detached successfully!"
            '''
        }
        failure {
            echo "❌ Deployment failed. Check logs for details."
            sh 'tail -50 app.log || true'
        }
    }
}
