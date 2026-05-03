pipeline {
    agent any

    tools {
        jdk 'jdk25'
        nodejs 'node22'
    }

    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

        stage("Clean Workspace") {
            steps {
                cleanWs()
            }
        }

        stage("Checkout from Git") {
            steps {
                git branch: 'main', url: 'https://github.com/sujalkamanna/netflix_devsecops.git'
            }
        }

        stage("SonarQube Analysis") {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh """
                    ${SCANNER_HOME}/bin/sonar-scanner \
                    -Dsonar.projectKey=netflixProject-${env.BUILD_NUMBER} \
                    -Dsonar.projectName=netflixProject
                    """
                }
            }
        }

        stage("Quality Gate") {
            steps {
                script {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage("Install Dependencies") {
            steps {
                sh "npm install"
            }
        }

        stage("Trivy FS Scan") {
            steps {
                sh "trivy fs --exit-code 1 --severity HIGH,CRITICAL . > trivyfs.txt"
            }
        }

        stage("Docker Build & Push") {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker', toolName: 'docker') {

                        withCredentials([string(credentialsId: 'tmdb-api', variable: 'API_KEY')]) {

                            sh """
                            docker build \
                            --build-arg TMDB_V3_API_KEY=$API_KEY \
                            -t netflix:${BUILD_NUMBER} .
                            """

                            sh "docker tag netflix:${BUILD_NUMBER} xyz/netflix:${BUILD_NUMBER}"
                            sh "docker push xyz/netflix:${BUILD_NUMBER}"
                        }
                    }
                }
            }
        }

        stage("Trivy Image Scan") {
            steps {
                sh "trivy image --exit-code 1 --severity HIGH,CRITICAL xyz/netflix:${BUILD_NUMBER} > trivyimage.txt"
            }
        }

        stage("Deploy to Kubernetes") {
            steps {
                script {
                    dir("Kubernetes") {

                        withKubeConfig([credentialsId: 'k8s']) {

                            sh "kubectl version --client"
                            sh "kubectl get nodes"
                            sh "kubectl apply -f deployment.yml"
                            sh "kubectl apply -f service.yml"

                        }
                    }
                }
            }
        }
    }

    post {
        always {
            emailext(
                attachLog: true,
                subject: "${currentBuild.result}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
<h3>Build Notification</h3>
<p><b>Project:</b> ${env.JOB_NAME}</p>
<p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
<p><b>Status:</b> ${currentBuild.result}</p>
<p><b>URL:</b> <a href="${env.BUILD_URL}">Open Build</a></p>
""",
                to: 'xyz@gmail.com',
                attachmentsPattern: '**/trivyfs.txt,**/trivyimage.txt'
            )
        }
    }
}