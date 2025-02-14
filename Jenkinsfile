pipeline {
    agent any

    environment {
        KUBECONFIG = credentials('KUBECONFIG')  // Reference the stored kubeconfig
        NAMESPACE = 'solar-system'
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
                    k get nodes
                    '''
                }
            }
        }
        stage('Deploy Nginx') {
            steps {
                script {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG
                    k run nginx --image=nginx --port=80 -n $NAMESPACE
                    '''
                }
            }
        }
    }
}