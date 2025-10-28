pipeline {
    agent any

    parameters {
        choice(name: 'ENVIRONMENT', choices: ['dev', 'prod'], description: 'Select environment to deploy')
    }

    environment {
        // Define DB names for reference
        DEV_DB_NAME = "team_1_db"
        PROD_DB_NAME = "team_1_prod_db"
        DEV_CONTAINER = "team_1_dev_1_postgres"
        PROD_CONTAINER = "team_1_prod_postgres"
    }

    stages {
        stage('Select Credentials') {
            steps {
                script {
                    if (params.ENVIRONMENT == 'dev') {
                        CRED_ID = 'team1_dev_credentials'
                        DB_NAME = env.DEV_DB_NAME
                        CONTAINER = env.DEV_CONTAINER
                    } else {
                        CRED_ID = 'team1_prod_credentials'
                        DB_NAME = env.PROD_DB_NAME
                        CONTAINER = env.PROD_CONTAINER
                    }

                    echo "🏗 Using ${params.ENVIRONMENT.toUpperCase()} environment"
                    echo "📦 Container: ${CONTAINER}"
                    echo "🗄  Database: ${DB_NAME}"

                    withCredentials([usernamePassword(credentialsId: CRED_ID,
                                                      usernameVariable: 'DB_USER',
                                                      passwordVariable: 'DB_PASS')]) {
                        sh '''
                        echo "Connecting to container: $CONTAINER"
                        echo "Database: $DB_NAME"
                        echo "Username: $DB_USER"
                        
                        # Example command to connect to Postgres container
                        docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -c "SELECT NOW();"
                        '''
                    }
                }
            }
        }
    }
}
