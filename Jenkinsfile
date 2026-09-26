pipeline {
    agent any

    environment {
        // Jenkins "Username with password" credential holding your Docker Hub creds
        DOCKERHUB      = credentials('dockerhub-creds')       // -> DOCKERHUB_USR / DOCKERHUB_PSW
        DOCKERHUB_USER = "${DOCKERHUB_USR}"
        DOCKERHUB_PASS = "${DOCKERHUB_PSW}"

        // EC2 deployment target
        SERVER_IP      = 'YOUR_EC2_PUBLIC_IP'
        SERVER_USER    = 'ubuntu'
        SSH_KEY_PATH   = credentials('ec2-ssh-key-path') // "Secret file" credential (the .pem)
    }

    triggers {
        // Works alongside a GitHub webhook trigger configured on the job
        githubPush()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.BRANCH = env.GIT_BRANCH?.replaceFirst(/^origin\//, '') ?: env.BRANCH_NAME
                    echo "Building branch: ${env.BRANCH}"
                }
            }
        }

        stage('Build Image') {
            steps {
                sh 'chmod +x build.sh deploy.sh'
                sh "./build.sh ${env.BRANCH}"
            }
        }

        stage('Push Image') {
            // push happens inside build.sh; this stage is just a visual gate/approval point
            when {
                anyOf { branch 'dev'; branch 'master'; branch 'main' }
            }
            steps {
                echo "Image pushed to Docker Hub for branch ${env.BRANCH}"
            }
        }

        stage('Deploy to EC2') {
            steps {
                sh "./deploy.sh ${env.BRANCH}"
            }
        }
    }

    post {
        always {
            sh 'docker logout || true'
        }
        success {
            echo "Pipeline succeeded for branch ${env.BRANCH}"
        }
        failure {
            echo "Pipeline failed for branch ${env.BRANCH}"
        }
    }
}
