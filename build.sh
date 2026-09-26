#!/bin/bash
# build.sh — builds the Docker image and pushes it to the correct Docker Hub repo
# Usage: ./build.sh <branch_name>
#   dev branch          -> pushed to <DOCKERHUB_USER>/devops-build-dev   (public)
#   master/main branch  -> pushed to <DOCKERHUB_USER>/devops-build-prod (private)
#
# Requires these env vars to be set (Jenkins injects them via credentials binding):
#   DOCKERHUB_USER, DOCKERHUB_PASS

set -euo pipefail

BRANCH_NAME="${1:-dev}"
IMAGE_NAME="devops-build"
BUILD_TAG="${BUILD_NUMBER:-latest}"

: "${DOCKERHUB_USER:?DOCKERHUB_USER is not set}"
: "${DOCKERHUB_PASS:?DOCKERHUB_PASS is not set}"

if [[ "$BRANCH_NAME" == "master" || "$BRANCH_NAME" == "main" ]]; then
    REPO="${DOCKERHUB_USER}/${IMAGE_NAME}-prod"
else
    REPO="${DOCKERHUB_USER}/${IMAGE_NAME}-dev"
fi

echo ">> Building image ${REPO}:${BUILD_TAG}"
docker build -t "${REPO}:${BUILD_TAG}" -t "${REPO}:latest" .

echo ">> Logging in to Docker Hub as ${DOCKERHUB_USER}"
echo "${DOCKERHUB_PASS}" | docker login -u "${DOCKERHUB_USER}" --password-stdin

echo ">> Pushing ${REPO}:${BUILD_TAG} and ${REPO}:latest"
docker push "${REPO}:${BUILD_TAG}"
docker push "${REPO}:latest"

echo ">> Build & push complete: ${REPO}"
