#!/bin/bash
set -euo pipefail

# Build and Push gRPC Server Images to Artifact Registry
# Usage: ./build-and-push.sh [PROJECT_ID] [REGION] [REPOSITORY] [VERSION]

# Error handler
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

# Input validation and defaults
PROJECT_ID="${1:-}"
REGION="${2:-us-central1}"
REPOSITORY="${3:-grpc-servers}"
VERSION="${4:-v1}"

# Validate required parameters
if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID is required"
  echo "Usage: $0 PROJECT_ID [REGION] [REPOSITORY] [VERSION]"
  echo ""
  echo "Example: $0 my-project us-central1 grpc-servers v1"
  exit 1
fi

echo "=== Building and Pushing gRPC Server Images ==="
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Repository: $REPOSITORY"
echo "Version: $VERSION"
echo ""

# Configure Docker authentication for Artifact Registry
echo "Configuring Docker authentication..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Base image path
IMAGE_BASE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}"

# Build and push H2C server
echo ""
echo "=== Building H2C gRPC Server ==="
cd ../apps/grpc-server-h2c
docker build -t ${IMAGE_BASE}/grpc-server-h2c:${VERSION} .
docker push ${IMAGE_BASE}/grpc-server-h2c:${VERSION}

# Tag as latest
docker tag ${IMAGE_BASE}/grpc-server-h2c:${VERSION} ${IMAGE_BASE}/grpc-server-h2c:latest
docker push ${IMAGE_BASE}/grpc-server-h2c:latest

echo "✓ H2C server image pushed: ${IMAGE_BASE}/grpc-server-h2c:${VERSION}"

# Build and push TLS server
echo ""
echo "=== Building TLS gRPC Server ==="
cd ../grpc-server-tls
docker build -t ${IMAGE_BASE}/grpc-server-tls:${VERSION} .
docker push ${IMAGE_BASE}/grpc-server-tls:${VERSION}

# Tag as latest
docker tag ${IMAGE_BASE}/grpc-server-tls:${VERSION} ${IMAGE_BASE}/grpc-server-tls:latest
docker push ${IMAGE_BASE}/grpc-server-tls:latest

echo "✓ TLS server image pushed: ${IMAGE_BASE}/grpc-server-tls:${VERSION}"

echo ""
echo "=== Build and Push Complete ==="
echo ""
echo "Images pushed:"
echo "  - ${IMAGE_BASE}/grpc-server-h2c:${VERSION}"
echo "  - ${IMAGE_BASE}/grpc-server-h2c:latest"
echo "  - ${IMAGE_BASE}/grpc-server-tls:${VERSION}"
echo "  - ${IMAGE_BASE}/grpc-server-tls:latest"
echo ""
echo "Next steps:"
echo "1. Update Kubernetes manifests with the correct image paths"
echo "2. Deploy to GKE using ./deploy-h2c.sh or ./deploy-tls.sh"
