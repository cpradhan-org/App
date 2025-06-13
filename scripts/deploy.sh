#!/bin/bash

set -e

INSTANCE_ID=$1
AWS_REGION=$2
ECR_REPO_URL=$3
IMAGE_NAME=$4
GIT_COMMIT=$5
MONGO_URI=$6
MONGO_USERNAME=$7
MONGO_PASSWORD=$8

LOGIN_CMD="aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO_URL"

DOCKER_CMDS=(
  "$LOGIN_CMD"
  "docker pull ${IMAGE_NAME}:${GIT_COMMIT}"
  "docker stop solar-system || true"
  "docker rm solar-system || true"
  "docker run --name solar-system \
    -e MONGO_URI=${MONGO_URI} \
    -e MONGO_USERNAME=${MONGO_USERNAME} \
    -e MONGO_PASSWORD=${MONGO_PASSWORD} \
    -d -p 3000:3000 ${IMAGE_NAME}:${GIT_COMMIT}"
)

# Build JSON array for commands
COMMANDS_JSON=$(printf '"%s",' "${DOCKER_CMDS[@]}")
COMMANDS_JSON="[${COMMANDS_JSON%,}]"

echo "Sending SSM command..."

COMMAND_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name "AWS-RunShellScript" \
  --comment "Deploy solar-system app" \
  --parameters "{\"commands\": $COMMANDS_JSON}" \
  --region "$AWS_REGION" \
  --query "Command.CommandId" \
  --output text)

echo "SSM Command ID: $COMMAND_ID"

# Optional: wait and check status
sleep 15
aws ssm get-command-invocation \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --region "$AWS_REGION"
