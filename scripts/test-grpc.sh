#!/bin/bash
set -euo pipefail

# Test gRPC Server using grpcurl
# Usage: ./test-grpc.sh [HOST:PORT] [--tls]

# Error handler
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

HOST="${1:-localhost:50051}"
USE_TLS="${2}"

echo "=== Testing gRPC Server ==="
echo "Host: $HOST"
echo "TLS: ${USE_TLS:-no}"
echo ""

# Check if grpcurl is installed
if ! command -v grpcurl &> /dev/null; then
  echo "ERROR: grpcurl is not installed"
  echo "Install it with:"
  echo "  brew install grpcurl  # macOS"
  echo "  go install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest  # Go"
  exit 1
fi

# Build grpcurl command
GRPCURL_CMD="grpcurl"

if [ "$USE_TLS" == "--tls" ]; then
  GRPCURL_CMD="$GRPCURL_CMD -insecure"
else
  GRPCURL_CMD="$GRPCURL_CMD -plaintext"
fi

# List available services
echo "1. Listing available services..."
$GRPCURL_CMD $HOST list

echo ""
echo "2. Describing Greeter service..."
$GRPCURL_CMD $HOST describe helloworld.Greeter

echo ""
echo "3. Testing SayHello RPC..."
$GRPCURL_CMD -d '{"name": "World"}' $HOST helloworld.Greeter/SayHello

echo ""
echo "4. Testing with different name..."
$GRPCURL_CMD -d '{"name": "GKE"}' $HOST helloworld.Greeter/SayHello

echo ""
echo "5. Checking health..."
$GRPCURL_CMD $HOST grpc.health.v1.Health/Check

echo ""
echo "=== Test Complete ==="
echo ""
echo "Multiple requests test (check load balancing):"
echo "for i in {1..10}; do"
echo "  $GRPCURL_CMD -d '{\"name\": \"Request-\$i\"}' $HOST helloworld.Greeter/SayHello | grep -E '(version|hostname)'"
echo "done"
