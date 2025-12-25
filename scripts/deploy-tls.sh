#!/bin/bash
set -euo pipefail

# Deploy TLS gRPC Server to GKE
# Usage: ./deploy-tls.sh [namespace]

# Error handler
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

NAMESPACE="${1:-default}"

echo "=== Deploying TLS gRPC Server to GKE ==="
echo "Namespace: $NAMESPACE"
echo ""

# Check if TLS secrets exist
echo "Checking for TLS secrets..."
if ! kubectl get secret grpc-tls-secret -n $NAMESPACE &> /dev/null; then
  echo "ERROR: Secret 'grpc-tls-secret' not found!"
  echo "Please create TLS secrets first:"
  echo "  cd ../certs && ./generate-certs.sh"
  echo "  kubectl create secret tls grpc-tls-secret --cert=output/server.crt --key=output/server.key -n $NAMESPACE"
  exit 1
fi

if ! kubectl get secret grpc-gateway-tls-secret -n $NAMESPACE &> /dev/null; then
  echo "ERROR: Secret 'grpc-gateway-tls-secret' not found!"
  echo "Please create Gateway TLS secret:"
  echo "  kubectl create secret tls grpc-gateway-tls-secret --cert=certs/output/server.crt --key=certs/output/server.key -n $NAMESPACE"
  exit 1
fi

echo "✓ TLS secrets found"
echo ""

# Apply BackendConfig first (needed by Service)
echo "1. Creating BackendConfig..."
kubectl apply -f ../k8s/tls/service.yaml -n $NAMESPACE

# Apply Deployment
echo "2. Creating Deployment..."
kubectl apply -f ../k8s/tls/deployment.yaml -n $NAMESPACE

# Apply Service
echo "3. Creating Service..."
kubectl apply -f ../k8s/tls/service.yaml -n $NAMESPACE

# Apply Gateway
echo "4. Creating Gateway..."
kubectl apply -f ../k8s/tls/gateway.yaml -n $NAMESPACE

# Apply HTTPRoute
echo "5. Creating HTTPRoute..."
kubectl apply -f ../k8s/tls/httproute.yaml -n $NAMESPACE

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Checking deployment status..."
kubectl get deployments -n $NAMESPACE -l app=grpc-server-tls
kubectl get services -n $NAMESPACE -l app=grpc-server-tls
kubectl get gateway -n $NAMESPACE grpc-gateway-tls
kubectl get httproute -n $NAMESPACE grpc-route-tls

echo ""
echo "To check Gateway IP address:"
echo "kubectl get gateway grpc-gateway-tls -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}'"
echo ""
echo "To test the gRPC server:"
echo "./test-grpc.sh [GATEWAY_IP] --tls"
