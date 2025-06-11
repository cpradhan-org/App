pipeline {

    agent any
    tools {
        nodejs 'node'
    }

    environment {
        MONGO_URI = 'mongodb+srv://supercluster.d83jj.mongodb.net/superData'
        MONGO_DB_CREDS = credentials('mongo-db-creds')
        MONGO_USERNAME = credentials('mongo-db-username')
        MONGO_PASSWORD = credentials('mongo-db-password')
        SONAR_SCANNER_HOME = tool 'sonarqube-scanner-610'
        AWS_REGION = 'us-east-2'
        ECR_REPO_URL = '400014682771.dkr.ecr.us-east-2.amazonaws.com'
        IMAGE_NAME = "${ECR_REPO_URL}/orbit-engine"
        AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
        AWS_SECRET_ACCESS_KEY = credentials('jenkins_aws_secret_access_key')
    }

    stages {
        stage('Install Dependencies') {
            steps {
                script {
                    sh 'npm install --no-audit'
                }
            }
        }

        stage('Dependency Scanning') {
            parallel {
                stage('NPM Dependency Audit') {
                    steps {
                        script {
                            sh '''
                               npm audit --audit-level=critical || true
                               echo $?
                            '''
                        }
                    }
                }
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
            }
        }

        stage('Unit Tests') {
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
                                  -Dsonar.projectKey=orbit-engine \
                                  -Dsonar.projectName=orbit-engine \
                                  -Dsonar.sources=app.js \
                                  -Dsonar.javascript.lcov.reportPaths=./coverage/lcov.info
                            '''
                        }
                        waitForQualityGate abortPipeline: true
                    }
                }
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:$GIT_COMMIT ."
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URL}"
                    sh "docker push ${IMAGE_NAME}:$GIT_COMMIT"
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}
