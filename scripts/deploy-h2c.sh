#!/bin/bash
set -euo pipefail

# Deploy H2C gRPC Server to GKE
# Usage: ./deploy-h2c.sh [namespace]

# Error handler
trap 'echo "Error on line $LINENO. Exit code: $?"' ERR

NAMESPACE="${1:-default}"

echo "=== Deploying H2C gRPC Server to GKE ==="
echo "Namespace: $NAMESPACE"
echo ""

# Apply BackendConfig first (needed by Service)
echo "1. Creating BackendConfig..."
kubectl apply -f ../k8s/h2c/service.yaml -n $NAMESPACE

# Apply Deployment
echo "2. Creating Deployment..."
kubectl apply -f ../k8s/h2c/deployment.yaml -n $NAMESPACE

# Apply Service
echo "3. Creating Service..."
kubectl apply -f ../k8s/h2c/service.yaml -n $NAMESPACE

# Apply Gateway
echo "4. Creating Gateway..."
kubectl apply -f ../k8s/h2c/gateway.yaml -n $NAMESPACE

# Apply HTTPRoute
echo "5. Creating HTTPRoute..."
kubectl apply -f ../k8s/h2c/httproute.yaml -n $NAMESPACE

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Checking deployment status..."
kubectl get deployments -n $NAMESPACE -l app=grpc-server-h2c
kubectl get services -n $NAMESPACE -l app=grpc-server-h2c
kubectl get gateway -n $NAMESPACE grpc-gateway-h2c
kubectl get httproute -n $NAMESPACE grpc-route-h2c

echo ""
echo "To check Gateway IP address:"
echo "kubectl get gateway grpc-gateway-h2c -n $NAMESPACE -o jsonpath='{.status.addresses[0].value}'"
echo ""
echo "To test the gRPC server:"
echo "./test-grpc.sh [GATEWAY_IP]"
