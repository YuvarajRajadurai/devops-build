#!/bin/bash
# deploy.sh — pulls the latest image on the EC2 server and (re)starts the container
# Usage: ./deploy.sh <branch_name>
#
# Requires these env vars (set in Jenkins as global/pipeline env or credentials):
#   DOCKERHUB_USER, SERVER_IP, SERVER_USER, SSH_KEY_PATH

set -euo pipefail

BRANCH_NAME="${1:-dev}"
IMAGE_NAME="devops-build"

: "${DOCKERHUB_USER:?DOCKERHUB_USER is not set}"
: "${SERVER_IP:?SERVER_IP is not set}"
: "${SERVER_USER:?SERVER_USER is not set}"
: "${SSH_KEY_PATH:?SSH_KEY_PATH is not set}"

if [[ "$BRANCH_NAME" == "master" || "$BRANCH_NAME" == "main" ]]; then
    REPO="${DOCKERHUB_USER}/${IMAGE_NAME}-prod"
else
    REPO="${DOCKERHUB_USER}/${IMAGE_NAME}-dev"
fi

echo ">> Deploying ${REPO}:latest to ${SERVER_USER}@${SERVER_IP}"

ssh -o StrictHostKeyChecking=no -i "${SSH_KEY_PATH}" "${SERVER_USER}@${SERVER_IP}" bash -s <<REMOTE_SCRIPT
  set -e
  echo ">> Pulling ${REPO}:latest"
  docker pull ${REPO}:latest

  echo ">> Stopping old container (if any)"
  docker stop devops-build-app 2>/dev/null || true
  docker rm devops-build-app 2>/dev/null || true

  echo ">> Starting new container on port 80"
  docker run -d \
    --name devops-build-app \
    -p 80:80 \
    --restart unless-stopped \
    ${REPO}:latest

  echo ">> Cleaning up dangling images"
  docker image prune -f
REMOTE_SCRIPT

echo ">> Deployment finished."
