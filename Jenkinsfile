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
        GITHUB_TOKEN = credentials('git-pat-token')
        ECR_REPO_URL = '400014682771.dkr.ecr.us-east-2.amazonaws.com'
        IMAGE_NAME = "${ECR_REPO_URL}/solar-system"
        IMAGE_TAG = "${GIT_COMMIT}"
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
                    sh 'sleep 5s'
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

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }

        stage('Trivy Vulnerability Scan') {
            steps {
                script {
                    sh """
                        trivy image ${IMAGE_NAME}:${IMAGE_TAG} \
                          --severity LOW,MEDIUM,HIGH \
                          --exit-code 0 \
                          --quiet \
                          --format json -o trivy-image-MEDIUM-results.json

                        trivy image ${IMAGE_NAME}:${IMAGE_TAG} \
                          --severity CRITICAL \
                          --exit-code 0 \
                          --quiet \
                          --format json -o trivy-image-CRITICAL-results.json
                    """
                }
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

        stage('Push Docker Image to ECR') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: 'us-east-2') {
                        sh '''
                            aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REPO_URL}
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        '''
                    }
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    sshagent(['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@3.141.190.157 '
                                aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${ECR_REPO_URL}
                                docker pull ${IMAGE_NAME}:${IMAGE_TAG}
                                if sudo docker ps -a | grep -q "solar-system"; then
                                    echo "Container found. Stopping..."
                                    sudo docker stop "solar-system" && sudo docker rm "solar-system"
                                    echo "Container stopped and removed."
                                fi
                                    docker run -d --name solar-system \
                                       -e MONGO_URI="${MONGO_URI}" \
                                       -e MONGO_USERNAME="${MONGO_USERNAME}" \
                                       -e MONGO_PASSWORD="${MONGO_PASSWORD}" \
                                       -p 3000:3000 ${IMAGE_NAME}:${IMAGE_TAG}
                            '
                        """
                    }
                }
            }
        }

        stage('Integration Testing - AWS EC2') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: 'us-east-2') {
                        sh 'bash integration-testing-ec2.sh'
                    }
                }
            }
        }

        stage('Update Kustomize Image Tag') {
            steps {
                script {
                    sh 'git clone -b main https://github.com/chinmaya10000/kubernetes-manifest.git'
                    dir('kubernetes-manifest') {
                        sh '''
                            git checkout main

                            yq -i "(.images[] | select(.name == \\"solar-system\\") | .newTag) = \\"${IMAGE_TAG}\\"" overlays/dev/kustomization.yaml
                            git config --global user.name "jenkins"
                            git config --global user.email "jenkins@dasher.com"
                            git remote set-url origin https://${GITHUB_TOKEN}@github.com/chinmaya10000/kubernetes-manifest.git
                            git add overlays/dev/kustomization.yaml
                            git commit -m "update solar-system image to ${IMAGE_TAG}"
                            git push -u origin main
                        '''
                    }
                }
            }
        }

        stage('DAST - OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                        chmod -R 777 $(pwd)
                        docker run --rm -v $(pwd):/zap/wrk/:rw ghcr.io/zaproxy/zaproxy zap-api-scan.py \
                            -t http://134.209.155.222:30000/api-docs/ \
                            -f openapi \
                            -r zap_report.html \
                            -w zap_report.md \
                            -J zap_json_report.json \
                            -x zap_xml_report.xml || true
                    '''
                }
            }
        }

        stage('Upload - AWS S3') {
            steps {
                script {
                    withAWS(credentials: 'aws-creds', region: 'us-east-2') {
                        sh '''
                           ls -ltr
                           mkdir reports-$BUILD_ID
                           cp -rf coverage/ reports-$BUILD_ID
                           cp dependency*.* test-results.xml trivy*.* zap*.* reports-$BUILD_ID
                           ls -ltr reports-$BUILD_ID
                        '''
                        s3Upload(
                            file:"reports-$BUILD_ID",
                            bucket:'orbit-engine-jenkins-reports',
                            path:"jenkins-$BUILD_ID/"
                        )
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                if (fileExists('kubernetes-manifest')) {
                    sh 'rm -rf kubernetes-manifest'
                }
            }

            junit allowEmptyResults: true, stdioRetention: '', testResults: 'dependency-check-junit.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'test-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-CRITICAL-results.xml'
            junit allowEmptyResults: true, stdioRetention: '', testResults: 'trivy-image-MEDIUM-results.xml'
            junit allowEmptyResults: true, testResults: 'zap_xml_report.xml'

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'dependency-check-jenkins.html', reportName: 'Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'coverage/lcov-report', reportFiles: 'index.html', reportName: 'Code Coverage HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-results.html', reportName: 'Trivy Image Critical Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'trivy-image-MEDIUM-results.html', reportName: 'Trivy Image Medium Vul Report', reportTitles: '', useWrapperFileDirectly: true])

            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: './', reportFiles: 'zap_report.html', reportName: 'DAST - OWASP ZAP Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}