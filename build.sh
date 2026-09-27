```bash
#!/bin/bash

# build.sh
# Builds the Docker image locally.
#
# Usage:
#   ./build.sh <image_tag>

set -euo pipefail

BUILD_TAG="${1:-latest}"

IMAGE_NAME="devops-build"

echo ">> Building Docker image: ${IMAGE_NAME}:${BUILD_TAG}"

docker build \
    -t "${IMAGE_NAME}:${BUILD_TAG}" \
    -t "${IMAGE_NAME}:latest" \
    .

echo ">> Docker build completed successfully"
echo ">> Image: ${IMAGE_NAME}:${BUILD_TAG}"
```
