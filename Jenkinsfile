pipeline {
    agent any

    stages {
        stage('OPA - Conftest') {
            steps {
                script {
                    sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy policies/docker-file-security.rego Dockerfile'
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