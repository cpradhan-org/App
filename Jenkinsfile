pipeline {
    agent any

    tools {
        nodejs 'node'
    }

    stages {
        stage('Installing Dependencies') {
            steps {
                script {
                    sh 'npm install --no-audit'
                }
            }
        }

        // stage('NPM Dependency Audit') {
        //     steps {
        //         script {
        //             sh '''
        //                 npm audit --audit-level=critical
        //                 echo $?
        //             '''
        //         }
        //     }
        // }
        stage('OWASP Dependency Check') {
            steps {
                script {
                    dependencyCheck additionalArguments: '''
                        --scan \'./\' 
                        --out \'./\'  
                        --format \'ALL\' 
                        --disableYarnAudit \
                        --prettyPrint''', odcInstallation: 'OWASP-DepCheck-10'
                    dependencyCheckPublisher failedTotalCritical: 1, pattern: 'dependency-check-report.xml', stopBuild: true
                }
            }
        }
    }
}