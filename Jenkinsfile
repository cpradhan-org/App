pipeline {
    agent any

    stages {
        stage('OPA - Conftest') {
            steps {
                script {
                    sh '/usr/local/bin/conftest test --policy /solar-system/dockerfile-security.rego /solar-system/Dockerfile'
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