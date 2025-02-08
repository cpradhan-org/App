pipeline {
    agent any

    tools {
        nodejs 'node'
    }

    environment {
        MONGO_URI = "mongodb+srv://supercluster.d83jj.mongodb.net/superData"
        MONGO_DB_CREDS = credentials('mongo-db-credentials')
        MONGO_USERNAME = credentials('mongo-db-username')
        MONGO_PASSWORD = credentials('mongo-db-password')
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-610'
        GITHUB_TOKEN = credentials('git-pat-token')
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
                        --prettyPrint''', odcInstallation: 'OWASP-DepCheck-11'
                    dependencyCheckPublisher failedTotalCritical: 3, pattern: 'dependency-check-report.xml', stopBuild: true
                }
            }
        }

        stage('Unit Testing') {
            steps {
                script {
                    sh 'echo Colon-Separated - $MONGO_DB_CREDS'
                    sh 'echo Username - $MONGO_DB_CREDS_USR'
                    sh 'echo Password - $MONGO_DB_CREDS_PSW'
                    sh 'npm test'
                }
            }
        }

        stage('Code Coverage') {
            steps {
                script {
                    catchError(buildResult: 'SUCCESS', message: 'Oops! it will be fixed in future releases', stageResult: 'UNSTABLE') {
                        sh 'npm run coverage'
                    }
                }
            }
        }

        stage('SAST - SonarQube') {
            steps {
                script {
                    timeout(time: 60, unit: 'SECONDS') {
                        withSonarQubeEnv('sonar-qube-server') {
                            sh '''
                                $SONAR_SCANNER_HOME/bin/sonar-scanner \
                                   -Dsonar.projectKey=Solar-System-Project \
                                   -Dsonar.sources=app.js \
                                   -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                            '''
                        }
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t chinmayapradhan/orbit-engine:$GIT_COMMIT ."
                }
            }
        }

        stage('Trivy Vulnerability Scanner') {
            steps {
                script {
                    sh '''
                        trivy image chinmayapradhan/orbit-engine:$GIT_COMMIT \
                            --severity LOW,MEDIUM \
                            --exit-code 0 \
                            --quiet \
                            --format json -o trivy-image-MEDIUM-results.json

                        trivy image chinmayapradhan/orbit-engine:$GIT_COMMIT \
                            --severity HIGH,CRITICAL \
                            --exit-code 1 \
                            --quiet \
                            --format json -o trivy-image-CRITICAL-results.json
                    '''
                }
                post {
                    always {
                        sh '''
                            trivy convert \
                               --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                               --output trivy-image-MEDIUM-results.html trivy-image-MEDIUM-results.json
                            
                            trivy convert \
                               --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                               --output trivy-image-CRITICAL-results.html trivy-image-CRITICAL-results.json

                            trivy convert \
                               --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                               --output trivy-image-MEDIUM-results.xml  trivy-image-MEDIUM-results.json

                            trivy convert \
                               --format template --template "@/usr/local/share/trivy/templates/junit.tpl" \
                               --output trivy-image-CRITICAL-results.xml trivy-image-CRITICAL-results.json
                        '''
                    }
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image Critical Vul Report', reportTitles: '', useWrapperFileDirectly: true])
            
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}