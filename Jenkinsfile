pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven_3.9.6'
    }

    environment {
        JAR_NAME = "testproject-0.0.1-SNAPSHOT.jar"
        APP_PORT = "8085"
        DB_HOST = "team_1_dev_1_postgres"
        DB_USER = "team_1_user"
        DB_PASS = "team_1_pass"
        DB_NAME = "team_1_db"
        DB_URL  = "jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}"
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
                echo "🚀 Deploying Spring Boot application..."
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
            }
        }

        stage('Verify Deployment') {
            steps {
                echo "🕒 Waiting for app to initialize..."
                sh 'sleep 20'

                echo "🔍 Verifying application process..."
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
            }
        }
    }

    post {
        success {
            echo "🎉 Deployment successful!"
            echo "🌍 App running on: http://localhost:${APP_PORT}"
            echo "📋 View logs with: tail -f /var/jenkins_home/workspace/test/app.log"

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
