pipeline {
    agent any

    environment {
        deploymentName = 'solar-system'
        containerName = 'solar-system'
        serviceName = 'solar-system'
        imageName = "chinmayapradhan/orbit-engine:$GIT_COMMIT"
    }

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
                parallel(
                    "OPA Scan": {
                        sh '/usr/local/bin/conftest test --policy k8s-security.rego kubernetes/development/deployment.yaml'
                    },
                    "Kubesec Scan": {
                        sh "bash kubesec-scan.sh"
                    }
                )
            }
        }
        // stage('Deploy') {
        //     steps {
        //         script {
        //             withKubeConfig(caCertificate: '', clusterName: 'myapp-eks', contextName: '', credentialsId: 'k8s-creds', namespace: 'solar-system', restrictKubeConfigAccess: false, serverUrl: 'https://CB0AF6D51C59F24129263DA9514E90B3.gr7.us-east-2.eks.amazonaws.com') {
        //                 sh "sed -i 's#image: chinmayapradhan/.*#image: chinmayapradhan/orbit-engine:$GIT_COMMIT#g' kubernetes/development/deployment.yaml"
        //                 sh 'kubectl apply -f kubernetes/development/secret.yaml'
        //                 sh 'kubectl apply -f kubernetes/development/deployment.yaml'
        //                 sh 'kubectl apply -f kubernetes/development/service.yaml'
        //             }
        //         }
        //     }
        // }
        stage('K8s Deployment - DEV') {
            steps {
                parallel(
                    "Deployment": {
                        withKubeConfig(caCertificate: '', clusterName: 'myapp-eks', contextName: '', credentialsId: 'k8s-creds', namespace: 'solar-system', restrictKubeConfigAccess: false, serverUrl: 'https://CB0AF6D51C59F24129263DA9514E90B3.gr7.us-east-2.eks.amazonaws.com') {
                            sh "bash k8s-deployment.sh" 
                        }
                    },
                    "Rollout Status": {
                        withKubeConfig(caCertificate: '', clusterName: 'myapp-eks', contextName: '', credentialsId: 'k8s-creds', namespace: 'solar-system', restrictKubeConfigAccess: false, serverUrl: 'https://CB0AF6D51C59F24129263DA9514E90B3.gr7.us-east-2.eks.amazonaws.com') {
                            sh "bash k8s-deployment-rollout-statu.sh" 
                        }
                    }
                )
            }
        }
    }
}