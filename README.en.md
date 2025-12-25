# GKE gRPC Server Deployment Guide

English | [한국어](./README.md)

A complete reference project for deploying and operating gRPC applications on Google Kubernetes Engine (GKE).

## 📋 Table of Contents

- [Project Structure](#project-structure)
- [Key Features](#key-features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Scenarios](#deployment-scenarios)
- [Troubleshooting](#troubleshooting)

## 📁 Project Structure

```
gke_test_001/
├── apps/                              # Application source code
│   ├── grpc-server-h2c/              # H2C (HTTP/2 Cleartext) server
│   │   ├── main.go
│   │   ├── Dockerfile
│   │   ├── go.mod
│   │   └── proto/helloworld.proto
│   └── grpc-server-tls/              # TLS server
│       ├── main.go
│       ├── Dockerfile
│       ├── go.mod
│       └── proto/helloworld.proto
├── k8s/                               # Kubernetes manifests
│   ├── h2c/                          # H2C deployment
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── gateway.yaml
│   │   └── httproute.yaml
│   ├── tls/                          # TLS deployment
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── gateway.yaml
│   │   ├── httproute.yaml
│   │   └── secret.yaml
│   └── multi-version/                # Multi-version traffic splitting
│       ├── deployment-v1.yaml
│       ├── deployment-v2.yaml
│       ├── service-v1.yaml
│       ├── service-v2.yaml
│       ├── httproute-split.yaml
│       └── backendconfig.yaml
├── certs/                             # TLS certificate generation
│   ├── generate-certs.sh
│   └── README.md
├── scripts/                           # Deployment automation scripts
│   ├── build-and-push.sh
│   ├── deploy-h2c.sh
│   ├── deploy-tls.sh
│   └── test-grpc.sh
├── GKE_Guide.md                       # GKE deployment best practices
└── README.md
```

## ✨ Key Features

- **H2C (HTTP/2 Cleartext)**: Simple gRPC server for internal communication without certificate management
- **TLS**: TLS-enabled gRPC server for secure communication
- **Gateway API**: Modern L7 load balancing using GKE Gateway API
- **Multi-version Deployment**: Canary deployment support with weighted traffic splitting
- **Health Checks**: Native gRPC health check implementation
- **Automation Scripts**: Build, deploy, and test automation

## 🔧 Prerequisites

### Local Development Environment
- Go 1.21+
- Docker
- kubectl
- gcloud CLI
- grpcurl (for testing)

### GKE Environment
- GKE cluster (Autopilot recommended)
- Gateway API enabled
- Artifact Registry repository

### Installation Commands

```bash
# macOS
brew install go docker kubectl google-cloud-sdk grpcurl

# Enable Gateway API (GKE cluster)
gcloud container clusters update CLUSTER_NAME \
  --gateway-api=standard \
  --region=REGION
```

## 🚀 Quick Start

### 1. Build and Push Images

```bash
cd scripts

# Build and push images to Artifact Registry
./build-and-push.sh PROJECT_ID REGION REPOSITORY v1
```

### 2. Update Kubernetes Manifests

Update image paths in deployment YAML files:

```yaml
image: REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/grpc-server-h2c:v1
```

### 3. Deploy H2C Server

```bash
cd scripts
./deploy-h2c.sh default
```

### 4. Test

```bash
# Get Gateway IP
GATEWAY_IP=$(kubectl get gateway grpc-gateway-h2c -o jsonpath='{.status.addresses[0].value}')

# Test gRPC server
./test-grpc.sh $GATEWAY_IP:80
```

## 📦 Deployment Scenarios

### Scenario 1: H2C Server (Internal Communication)

Simplest configuration using H2C between ALB and Pods.

```bash
# Deploy
cd scripts
./deploy-h2c.sh

# Test
GATEWAY_IP=$(kubectl get gateway grpc-gateway-h2c -o jsonpath='{.status.addresses[0].value}')
./test-grpc.sh $GATEWAY_IP:80
```

**Features:**
- ✅ No certificate management required
- ✅ Leverages VPC internal security
- ✅ Simple configuration

### Scenario 2: TLS Server (End-to-End Encryption)

Use when end-to-end encryption is required.

```bash
# 1. Generate certificates
cd certs
./generate-certs.sh

# 2. Create secrets
kubectl create secret tls grpc-tls-secret \
  --cert=output/server.crt \
  --key=output/server.key

kubectl create secret tls grpc-gateway-tls-secret \
  --cert=output/server.crt \
  --key=output/server.key

# 3. Deploy
cd ../scripts
./deploy-tls.sh

# 4. Test
GATEWAY_IP=$(kubectl get gateway grpc-gateway-tls -o jsonpath='{.status.addresses[0].value}')
./test-grpc.sh $GATEWAY_IP:443 --tls
```

**Features:**
- ✅ End-to-end TLS encryption
- ✅ TLS termination at ALB
- ⚠️ Certificate management required

### Scenario 3: Multi-version (Canary Deployment)

Gradually deploy new versions to minimize risk.

```bash
# 1. Build v1, v2 images
cd scripts
./build-and-push.sh PROJECT_ID REGION REPOSITORY v1
./build-and-push.sh PROJECT_ID REGION REPOSITORY v2

# 2. Deploy multi-version
kubectl apply -f ../k8s/multi-version/

# 3. Adjust traffic split (e.g., v1 90%, v2 10%)
# Edit k8s/multi-version/httproute-split.yaml
# - weight: 90  # v1
# - weight: 10  # v2

kubectl apply -f ../k8s/multi-version/httproute-split.yaml

# 4. Verify version distribution with load test
for i in {1..20}; do
  grpcurl -plaintext -d '{"name": "Test"}' $GATEWAY_IP:80 \
    helloworld.Greeter/SayHello | grep version
done
```

**Features:**
- ✅ Weight-based traffic splitting
- ✅ Gradual rollout
- ✅ Instant rollback capability

## 🔍 Troubleshooting

### Gateway IP Not Assigned

```bash
# Check Gateway status
kubectl describe gateway grpc-gateway-h2c

# Common causes:
# - Gateway API not enabled on cluster
# - Backend services not ready
```

### gRPC Connection Failure

```bash
# Check Pod logs
kubectl logs -l app=grpc-server-h2c

# Check Service endpoints
kubectl get endpoints grpc-server-h2c

# Check BackendConfig status
kubectl describe backendconfig grpc-backendconfig
```

### TLS Certificate Errors

```bash
# Check Secret
kubectl get secret grpc-tls-secret -o yaml

# Verify certificate
openssl verify -CAfile certs/output/ca.crt certs/output/server.crt

# Check SAN
openssl x509 -in certs/output/server.crt -text -noout | grep -A1 "Subject Alternative Name"
```

### Load Balancing Imbalance

gRPC is HTTP/2-based, so L7 load balancing is essential.

```bash
# Check backend protocol in HTTPRoute
kubectl get httproute grpc-route-h2c -o yaml

# Verify appProtocol: HTTP2 in Service
kubectl get service grpc-server-h2c -o yaml | grep appProtocol
```

## 📚 Additional Documentation

- [GKE_Guide.md](GKE_Guide.md) - GKE deployment and operation best practices
- [certs/README.md](certs/README.md) - TLS certificate generation guide

## 🤝 Contributing

Feel free to suggest issues or improvements!

## 📄 License

MIT License
