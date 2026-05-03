pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
        timeout(time: 30, unit: 'MINUTES')
    }

    tools {
        jdk 'jdk17'
        nodejs 'node20'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        APP_NAME = "netflix"
    }

    stages {

        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Checkout Code") {
            steps {
                git branch: 'main', url: 'https://github.com/sujalkamanna/netflix_devsecops.git'
            }
        }

        stage("Install Dependencies") {
            steps {
                sh """
                node -v
                npm -v
                npm install
                """
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                        sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=${APP_NAME}-${BUILD_NUMBER} \
                        -Dsonar.projectName=${APP_NAME} \
                        -Dsonar.sources=. \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.login=$SONAR_TOKEN
                        """
                    }
                }
            }
        }

        stage("Quality Gate") {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Trivy FS Scan") {
            steps {
                sh "trivy fs --exit-code 1 --severity HIGH,CRITICAL . | tee trivyfs.txt"
            }
        }

        stage("Docker Build") {
            steps {
                script {
                    withCredentials([string(credentialsId: 'tmdb-api', variable: 'API_KEY')]) {
                        sh """
                        docker build \
                        --build-arg VITE_APP_TMDB_V3_API_KEY=$API_KEY \
                        -t ${APP_NAME}:${BUILD_NUMBER} .
                        """
                    }
                }
            }
        }

        stage("Docker Push") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', url: 'https://index.docker.io/v1/') {
                        sh """
                        docker tag ${APP_NAME}:${BUILD_NUMBER} sujalkamanna/${APP_NAME}:${BUILD_NUMBER}
                        docker push sujalkamanna/${APP_NAME}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }

        stage("Trivy Image Scan") {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL sujalkamanna/${APP_NAME}:${BUILD_NUMBER} | tee trivyimage.txt"
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                withCredentials([file(credentialsId: 'k8s-config', variable: 'KUBECONFIG')]) {
                    dir("Kubernetes") {
                        sh """
                        export KUBECONFIG=$KUBECONFIG
                        kubectl get nodes
                        kubectl apply -f deployment.yml
                        kubectl apply -f service.yml
                        kubectl rollout status deployment/${APP_NAME}-deployment
                        """
                    }
                }
            }
        }

        stage("Docker Cleanup") {
            steps {
                sh "docker image prune -f"
            }
        }
    }

    post {

        success {
            emailext(
                to: 'xyz@gmail.com',
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                Build Success
                Project: ${env.JOB_NAME}
                Build: ${env.BUILD_NUMBER}
                Status: SUCCESS
                URL: ${env.BUILD_URL}
                """
            )
        }

        failure {
            emailext(
                to: 'xyz@gmail.com',
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                Build Failed
                Project: ${env.JOB_NAME}
                Build: ${env.BUILD_NUMBER}
                Status: FAILED
                URL: ${env.BUILD_URL}
                """
            )
        }

        always {
            archiveArtifacts artifacts: '**/trivyfs.txt,**/trivyimage.txt', fingerprint: true
        }
    }
}