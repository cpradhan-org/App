pipeline {
    agent any

    stages {
        stage('OPA - Conftest') {
            steps {
                script {
                    sh '/usr/local/bin/conftest test --policy dockerfile-security.rego Dockerfile'
                }
            }
        }
        stage('Build and push') {
            steps {
                script {
                    sh "docker build -t chinmayapradhan/orbit-engine:$GIT_COMMIT ."
                }
            }
        }
        stage('Push Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: 'docker-creds', url: "") {
                        sh "docker push chinmayapradhan/orbit-engine:$GIT_COMMIT"
                    }
                }
            }
        }
        stage('Vulnerability Scan - Kubernetes') {
            steps {
                script {
                    sh '/usr/local/bin/conftest test --policy k8s-security.rego kubernetes/development/deployment.yaml'
                }
            }
        }
    }
}