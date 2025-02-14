pipeline {
    agent any

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
                    withKubeConfig(caCertificate: '', clusterName: 'minikube', contextName: '', credentialsId: 'k8s-creds', namespace: 'solar-system', restrictKubeConfigAccess: false, serverUrl: 'https://192.168.49.2:8443') {
                        sh 'kubectl run nginx --image=nginx:latest --port=80 -n solar-system'
                    }
                }
            }
        }
    }
}