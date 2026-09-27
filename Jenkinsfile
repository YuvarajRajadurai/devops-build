```groovy
pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'yuvarajjr'
        DEV_IMAGE = "${DOCKERHUB_USER}/devops-build-dev"
        PROD_IMAGE = "${DOCKERHUB_USER}/devops-build-prod"
        CONTAINER_NAME = 'devops-build'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_PASS'
                    )
                ]) {
                    sh '''
                        chmod +x build.sh
                        ./build.sh ${BUILD_NUMBER}
                    '''
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login \
                            -u "$DOCKER_USER" \
                            --password-stdin
                    '''
                }
            }
        }

        stage('Push DEV Image') {
            when {
                branch 'dev'
            }

            steps {
                sh '''
                    docker tag devops-build:${BUILD_NUMBER} \
                        ${DEV_IMAGE}:${BUILD_NUMBER}

                    docker tag devops-build:${BUILD_NUMBER} \
                        ${DEV_IMAGE}:latest

                    docker push ${DEV_IMAGE}:${BUILD_NUMBER}
                    docker push ${DEV_IMAGE}:latest
                '''
            }
        }

        stage('Push PROD Image') {
            when {
                branch 'main'
            }

            steps {
                sh '''
                    docker tag devops-build:${BUILD_NUMBER} \
                        ${PROD_IMAGE}:${BUILD_NUMBER}

                    docker tag devops-build:${BUILD_NUMBER} \
                        ${PROD_IMAGE}:latest

                    docker push ${PROD_IMAGE}:${BUILD_NUMBER}
                    docker push ${PROD_IMAGE}:latest
                '''
            }
        }

        stage('Deploy DEV') {
            when {
                branch 'dev'
            }

            steps {
                sh '''
                    export IMAGE_NAME="${DEV_IMAGE}"
                    export IMAGE_TAG="${BUILD_NUMBER}"

                    chmod +x deploy.sh
                    ./deploy.sh
                '''
            }
        }

        stage('Deploy PROD') {
            when {
                branch 'main'
            }

            steps {
                sh '''
                    export IMAGE_NAME="${PROD_IMAGE}"
                    export IMAGE_TAG="${BUILD_NUMBER}"

                    chmod +x deploy.sh
                    ./deploy.sh
                '''
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
    }
}
```
