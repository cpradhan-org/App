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
    }
}