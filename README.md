# CI Pipeline for Node.js, Docker, ECR, and GitOps Kustomize Update

This repository contains a Jenkins pipeline (`Jenkinsfile`) for the **Continuous Integration (CI)** process of a Node.js application.  
The pipeline covers dependency and security scanning, unit testing, coverage, image building and vulnerability scanning, deployment to EC2, GitOps manifest updating, DAST scanning, and uploading reports to S3.

---

## Pipeline Overview

### Main Steps

1. **Install Dependencies**: Installs Node.js dependencies.
2. **Dependency Scanning**: Scans for vulnerable dependencies with NPM Audit and OWASP Dependency Check.
3. **Unit Tests & Coverage**: Runs tests and code coverage, publishing results.
4. **SAST (SonarQube)**: Runs static analysis and enforces code quality gates.
5. **Build Docker Image**: Builds a Docker image for the app.
6. **Trivy Vulnerability Scan**: Scans the built Docker image for vulnerabilities, generates reports.
7. **Push Docker Image to ECR**: Pushes the image to Amazon Elastic Container Registry.
8. **Deploy to EC2**: Pulls and runs the new image on a remote EC2 instance.
9. **Integration Testing**: Runs integration tests on the EC2 deployment.
10. **Update Kustomize Image Tag**: Updates the image tag in a [GitOps Kubernetes manifest repository](https://github.com/chinmaya10000/kubernetes-manifest).
11. **DAST (OWASP ZAP)**: Runs dynamic security tests against the deployed app.
12. **Upload Reports to S3**: Uploads all relevant reports to AWS S3 for archiving and review.

---

## Prerequisites

- **Jenkins** with:
  - Pipeline, NodeJS, Credentials Binding, AWS, SonarQube, HTML Publisher plugins
- **Jenkins Tools** configured:
  - Node.js (label: `node`)
  - SonarQube Scanner (label: `sonarqube-scanner-610`)
  - OWASP Dependency Check (label: `OWASP-DepCheck-11`)
- **Jenkins Credentials**:
  - `mongo-db-creds`, `mongo-db-username`, `mongo-db-password`: MongoDB access
  - `git-pat-token`: GitHub token with push access to the GitOps repo
  - `aws-creds`: AWS credentials for ECR/S3 access
  - `ec2-ssh-key`: SSH private key for EC2 access
- **AWS ECR**: Repository created and accessible for Docker pushes
- **AWS EC2**: Instance set up and accessible for deployment
- **SonarQube** server configured in Jenkins as `sonar-qube-server`
- **Trivy** and **yq** available on Jenkins agent(s)
- **OWASP ZAP** (Docker image) available
- **S3 bucket** (`orbit-engine-jenkins-reports`) exists for report uploads
- **GitOps Repo**: [kubernetes-manifest](https://github.com/chinmaya10000/kubernetes-manifest) or your own, using Kustomize overlays

---

## Key Environment Variables

| Name            | Description                              | Example Value                                               |
|-----------------|------------------------------------------|-------------------------------------------------------------|
| MONGO_URI       | MongoDB connection string                | `mongodb+srv://supercluster.d83jj.mongodb.net/superData`    |
| MONGO_DB_CREDS  | Jenkins credentials for MongoDB          | `username:password`                                         |
| SONAR_SCANNER_HOME | SonarQube scanner installation path   | From Jenkins tool configuration                             |
| GITHUB_TOKEN    | GitHub PAT for manifest repo push        | From Jenkins credentials                                    |
| ECR_REPO_URL    | AWS ECR repository URL                   | `400014682771.dkr.ecr.us-east-2.amazonaws.com`              |
| IMAGE_NAME      | Full image name with repo                 | `${ECR_REPO_URL}/solar-system`                             |
| IMAGE_TAG       | Tag for Docker image (commit SHA)        | `${GIT_COMMIT}`                                             |

---

## Pipeline Stages Breakdown

### 1. Install Dependencies
- Runs `npm install --no-audit`

### 2. Dependency Scanning
- **NPM Audit**: Checks for critical vulnerabilities.
- **OWASP Dependency Check**: Scans for known component vulnerabilities.

### 3. Unit Tests & Coverage
- Prints MongoDB credentials (for debugging).
- Runs `npm test` and collects JUnit results.
- Runs code coverage, collects and publishes HTML report.

### 4. SAST (SonarQube)
- Runs SonarQube scanner for static code analysis.
- Waits for quality gate result and fails if gate is not met.

### 5. Build Docker Image
- Builds Docker image tagged with commit SHA.

### 6. Trivy Vulnerability Scan
- Scans image for vulnerabilities (LOW-MEDIUM-HIGH and CRITICAL).
- Generates JSON, HTML, and JUnit XML reports.

### 7. Push Docker Image to ECR
- Logs in to ECR and pushes the Docker image.

### 8. Deploy to EC2
- SSH to EC2, pulls the new image, stops/removes old container, and runs the new version with required environment variables.

### 9. Integration Testing
- Runs a provided `integration-testing-ec2.sh` script against the EC2 deployment.

### 10. Update Kustomize Image Tag
- Clones the GitOps manifest repo.
- Uses `yq` to update the `overlays/dev/kustomization.yaml` image tag.
- Commits and pushes the change using the GitHub token.

### 11. DAST (OWASP ZAP)
- Runs ZAP DAST scan against the deployed app API.
- Publishes multiple report formats (HTML, Markdown, JSON, XML).

### 12. Upload Reports to S3
- Gathers all major output files and uploads them to S3 for archival.

---

## Artifacts & Publishing

- **JUnit XML**: For dependency, unit, coverage, trivy, and zap tests
- **HTML Reports**: For dependency check, coverage, trivy, and zap
- **S3 Upload**: Backs up the entire report directory per build

---

## Manifest Update & GitOps

After a successful build and deployment, the pipeline updates the [kubernetes-manifest](https://github.com/chinmaya10000/kubernetes-manifest.git) repository's `overlays/dev/kustomization.yaml` with the new Docker image tag.  
This triggers your CD pipeline to rollout the new version via ArgoCD or similar.

If your CD pipeline is in another repo, link to its documentation:
- [CD Pipeline README](https://github.com/chinmaya10000/infra-automation-eks/blob/main/README.md)

---

## Troubleshooting

- **AWS/EC2/ECR Issues**: Check credentials and permissions in Jenkins.
- **MongoDB Connection**: Ensure secrets are correct and network is open.
- **SonarQube/Trivy/OWASP Tools**: Ensure tools are installed and paths are correct.
- **Manifest Update**: Confirm GitHub token has push rights to the GitOps repo.
- **S3 Upload**: Check bucket policies and IAM permissions.

---

## License

[MIT](LICENSE)
