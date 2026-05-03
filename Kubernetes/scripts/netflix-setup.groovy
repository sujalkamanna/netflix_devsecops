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
                sh "npm ci --cache .npm --prefer-offline"
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
                script {
                    timeout(time: 2, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage("Trivy Filesystem Scan") {
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
                        --build-arg TMDB_V3_API_KEY=$API_KEY \
                        -t ${APP_NAME}:${BUILD_NUMBER} .
                        """
                    }
                }
            }
        }

        stage("Tag & Push Image") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {
                        sh """
                        docker tag ${APP_NAME}:${BUILD_NUMBER} xyz/${APP_NAME}:${BUILD_NUMBER}
                        docker push xyz/${APP_NAME}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }

        stage("Trivy Image Scan") {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL xyz/${APP_NAME}:${BUILD_NUMBER} | tee trivyimage.txt"
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                script {
                    dir("Kubernetes") {
                        withKubeConfig([credentialsId: 'k8s']) {

                            sh "kubectl get nodes"

                            sh "kubectl apply -f deployment.yml"
                            sh "kubectl apply -f service.yml"

                            sh "kubectl rollout status deployment/${APP_NAME}-deployment"
                        }
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
            echo "✅ Pipeline Successful"

            emailext(
                subject: "✅ SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                <h2>✅ Build Successful</h2>
                <p><b>Project:</b> ${env.JOB_NAME}</p>
                <p><b>Build:</b> ${env.BUILD_NUMBER}</p>
                <p><b>Status:</b> SUCCESS</p>
                <p><b>URL:</b> <a href="${env.BUILD_URL}">Open Build</a></p>
                """,
                to: 'sujalkamanna2003@gmail.com'
            )
        }

        failure {
            echo "❌ Pipeline Failed"

            sh "kubectl rollout undo deployment/${APP_NAME}-deployment || true"

            emailext(
                subject: "❌ FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                <h2>❌ Build Failed</h2>
                <p><b>Project:</b> ${env.JOB_NAME}</p>
                <p><b>Build:</b> ${env.BUILD_NUMBER}</p>
                <p><b>Status:</b> FAILED</p>
                <p><b>URL:</b> <a href="${env.BUILD_URL}">Open Build</a></p>
                """,
                to: 'sujalkamanna2003@gmail.com'
            )
        }

        always {
            archiveArtifacts artifacts: '**/trivyfs.txt,**/trivyimage.txt', fingerprint: true
        }
    }
}