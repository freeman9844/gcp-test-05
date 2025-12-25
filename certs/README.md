# TLS Certificate Generation

This directory contains scripts for generating TLS certificates for gRPC servers.

## Quick Start

```bash
# Generate certificates with default domain (grpc.example.com)
./generate-certs.sh

# Generate certificates with custom domain
DOMAIN=grpc.mycompany.com ./generate-certs.sh

# Generate certificates valid for 2 years
DAYS_VALID=730 ./generate-certs.sh
```

## Generated Files

After running the script, you'll find the following files in `output/`:

- `ca.key` - CA private key
- `ca.crt` - CA certificate
- `server.key` - Server private key
- `server.crt` - Server certificate (signed by CA)
- `server.csr` - Certificate signing request
- `san.cnf` - Subject Alternative Name configuration

## Creating Kubernetes Secrets

### For gRPC Server Pods

```bash
kubectl create secret tls grpc-tls-secret \
  --cert=output/server.crt \
  --key=output/server.key
```

### For Gateway (Load Balancer)

```bash
kubectl create secret tls grpc-gateway-tls-secret \
  --cert=output/server.crt \
  --key=output/server.key
```

## Verifying Certificates

```bash
# View certificate details
openssl x509 -in output/server.crt -text -noout

# Verify certificate chain
openssl verify -CAfile output/ca.crt output/server.crt
```

## Important Notes

- **SAN Configuration**: The script automatically configures Subject Alternative Names (SAN) for the domain, wildcard subdomain, localhost, and 127.0.0.1
- **Production Use**: For production environments, use certificates from a trusted CA (e.g., Let's Encrypt, Google-managed certificates)
- **Security**: Keep private keys (`*.key`) secure and never commit them to version control
