#!/bin/bash
set -e

# TLS Certificate Generation Script for GKE gRPC Server
# This script generates CA and server certificates with proper SAN configuration

DOMAIN="${DOMAIN:-grpc.example.com}"
DAYS_VALID="${DAYS_VALID:-365}"

echo "=== Generating TLS Certificates for gRPC Server ==="
echo "Domain: $DOMAIN"
echo "Valid for: $DAYS_VALID days"
echo ""

# Create output directory
mkdir -p output
cd output

# 1. Generate CA private key
echo "1. Generating CA private key..."
openssl genrsa -out ca.key 4096

# 2. Generate CA certificate
echo "2. Generating CA certificate..."
openssl req -new -x509 -days $DAYS_VALID -key ca.key -out ca.crt \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=Example/OU=IT/CN=Example CA"

# 3. Generate server private key
echo "3. Generating server private key..."
openssl genrsa -out server.key 4096

# 4. Create server certificate signing request (CSR)
echo "4. Generating server CSR..."
openssl req -new -key server.key -out server.csr \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=Example/OU=IT/CN=$DOMAIN"

# 5. Create SAN configuration file
echo "5. Creating SAN configuration..."
cat > san.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = KR
ST = Seoul
L = Seoul
O = Example
OU = IT
CN = $DOMAIN

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = localhost
IP.1 = 127.0.0.1
EOF

# 6. Generate server certificate signed by CA
echo "6. Generating server certificate..."
openssl x509 -req -days $DAYS_VALID -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -extensions v3_req -extfile san.cnf

# 7. Verify certificate
echo "7. Verifying certificate..."
openssl verify -CAfile ca.crt server.crt

echo ""
echo "=== Certificate Generation Complete ==="
echo ""
echo "Generated files in ./output/:"
echo "  - ca.key, ca.crt (CA certificate)"
echo "  - server.key, server.crt (Server certificate)"
echo ""
echo "To create Kubernetes secrets, run:"
echo ""
echo "# For gRPC server pods:"
echo "kubectl create secret tls grpc-tls-secret \\"
echo "  --cert=output/server.crt \\"
echo "  --key=output/server.key"
echo ""
echo "# For Gateway (load balancer):"
echo "kubectl create secret tls grpc-gateway-tls-secret \\"
echo "  --cert=output/server.crt \\"
echo "  --key=output/server.key"
echo ""
echo "To view certificate details:"
echo "openssl x509 -in output/server.crt -text -noout"
