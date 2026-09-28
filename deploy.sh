
#!/bin/bash

set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:?IMAGE_NAME is not set}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG is not set}"

CONTAINER_NAME="devops-build-app"

echo ">> Deploying ${IMAGE_NAME}:${IMAGE_TAG}"

echo ">> Pulling image from Docker Hub"
docker pull "${IMAGE_NAME}:${IMAGE_TAG}"

echo ">> Stopping old container"
docker stop "${CONTAINER_NAME}" 2>/dev/null || true

echo ">> Removing old container"
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

echo ">> Starting new container"
docker run -d \
    --name "${CONTAINER_NAME}" \
    -p 80:80 \
    --restart unless-stopped \
    "${IMAGE_NAME}:${IMAGE_TAG}"

echo ">> Checking container status"
docker ps --filter "name=${CONTAINER_NAME}"

echo ">> Cleaning unused Docker images"
docker image prune -f

echo ">> Deployment completed successfully"