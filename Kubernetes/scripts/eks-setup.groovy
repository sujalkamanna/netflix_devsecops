pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['apply', 'destroy'],
            description: 'Terraform action'
        )
    }

    stages {

        stage('Checkout from Git') {
            steps {
                git branch: "main", url: "https://github.com/sujalkamanna/netflix_devsecops.git"
            }
        }

        stage('Terraform Init & Validate') {
            steps {
                dir('EKS_TERRAFORM') {
                    sh '''
                        terraform init
                        terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan (Only for Apply)') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                dir('EKS_TERRAFORM') {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Approval (Only for Destroy)') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                input message: 'Are you sure you want to DESTROY infrastructure?'
            }
        }

        stage('Terraform Apply/Destroy') {
            steps {
                dir('EKS_TERRAFORM') {
                    script {
                        if (params.ACTION == 'apply') {
                            sh 'terraform apply -auto-approve tfplan'
                        } else {
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
}