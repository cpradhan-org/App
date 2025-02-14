pipeline {
    agent any

    environment {
        KUBECONFIG = credentials('KUBECONFIG')  // Reference the stored kubeconfig
    }

    stages {
        // stage('OPA - Conftest') {
        //     steps {
        //         script {
        //             sh '/usr/local/bin/conftest test --policy dockerfile-security.rego Dockerfile'
        //         }
        //     }
        // }
        // stage('Build and push') {
        //     steps {
        //         script {
        //             sh "docker build -t chinmayapradhan/orbit-engine:$GIT_COMMIT ."
        //         }
        //     }
        // }
        // stage('Push Image') {
        //     steps {
        //         script {
        //             withDockerRegistry(credentialsId: 'docker-creds', url: "") {
        //                 sh "docker push chinmayapradhan/orbit-engine:$GIT_COMMIT"
        //             }
        //         }
        //     }
        // }
        stage('deploy') {
            steps {
                script {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG
                    kubectl get nodes
                    '''
                }
            }
        }
    }
}