# GKE gRPC 서버 배포 가이드

[English](./README.en.md) | 한국어

Google Kubernetes Engine(GKE)에서 gRPC 애플리케이션을 배포하고 운영하기 위한 완전한 레퍼런스 프로젝트입니다.

## � 목차

- [프로젝트 구조](#프로젝트-구조)
- [주요 기능](#주요-기능)
- [사전 요구사항](#사전-요구사항)
- [빠른 시작](#빠른-시작)
- [배포 시나리오](#배포-시나리오)
- [트러블슈팅](#트러블슈팅)

## 📁 프로젝트 구조

```
gke_test_001/
├── apps/                              # 애플리케이션 소스 코드
│   ├── grpc-server-h2c/              # H2C (HTTP/2 Cleartext) 서버
│   │   ├── main.go
│   │   ├── Dockerfile
│   │   ├── go.mod
│   │   └── proto/helloworld.proto
│   └── grpc-server-tls/              # TLS 서버
│       ├── main.go
│       ├── Dockerfile
│       ├── go.mod
│       └── proto/helloworld.proto
├── k8s/                               # Kubernetes 매니페스트
│   ├── h2c/                          # H2C 배포 설정
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── gateway.yaml
│   │   └── httproute.yaml
│   ├── tls/                          # TLS 배포 설정
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── gateway.yaml
│   │   ├── httproute.yaml
│   │   └── secret.yaml
│   └── multi-version/                # 멀티 버전 트래픽 분할
│       ├── deployment-v1.yaml
│       ├── deployment-v2.yaml
│       ├── service-v1.yaml
│       ├── service-v2.yaml
│       ├── httproute-split.yaml
│       └── backendconfig.yaml
├── certs/                             # TLS 인증서 생성
│   ├── generate-certs.sh
│   └── README.md
├── scripts/                           # 배포 자동화 스크립트
│   ├── build-and-push.sh
│   ├── deploy-h2c.sh
│   ├── deploy-tls.sh
│   └── test-grpc.sh
├── GKE_Guide.md                       # GKE 배포 권장사항
└── README.md
```

## ✨ 주요 기능

### 핵심 기능
- **H2C (HTTP/2 Cleartext)**: 인증서 관리가 간단한 내부 통신용 gRPC 서버
- **TLS**: 보안 통신을 위한 TLS 지원 gRPC 서버
- **Gateway API**: 최신 GKE Gateway API를 사용한 L7 로드 밸런싱
- **멀티 버전 배포**: 가중치 기반 트래픽 분할로 카나리 배포 지원
- **Health Checks**: gRPC 네이티브 헬스 체크 구현
- **자동화 스크립트**: 빌드, 배포, 테스트 자동화

### Best Practices 적용
- **Graceful Shutdown**: SIGTERM/SIGINT 시그널 처리로 안전한 종료
- **Security Context**: 비루트 사용자 실행 및 최소 권한 원칙
- **Enhanced Health Probes**: timeout 및 failureThreshold 설정
- **Optimized Resources**: Autopilot 환경에 최적화된 리소스 설정
- **Error Handling**: 강화된 스크립트 에러 핸들링 (set -euo pipefail)
- **Docker Optimization**: .dockerignore를 통한 빌드 최적화

## 🔧 사전 요구사항

### 로컬 개발 환경
- Go 1.21+
- Docker
- kubectl
- gcloud CLI
- grpcurl (테스트용)

### GKE 환경
- GKE 클러스터 (Autopilot 권장)
- Gateway API 활성화
- Artifact Registry 저장소

### 설치 명령어

```bash
# macOS
brew install go docker kubectl google-cloud-sdk grpcurl

# Gateway API 활성화 (GKE 클러스터)
gcloud container clusters update CLUSTER_NAME \
  --gateway-api=standard \
  --region=REGION
```

## 🚀 빠른 시작

### 1. 이미지 빌드 및 푸시

```bash
cd scripts

# Artifact Registry에 이미지 빌드 및 푸시
./build-and-push.sh PROJECT_ID REGION REPOSITORY v1
```

### 2. Kubernetes 매니페스트 업데이트

각 배포 YAML 파일에서 이미지 경로를 업데이트하세요:

```yaml
image: REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/grpc-server-h2c:v1
```

### 3. H2C 서버 배포

```bash
cd scripts
./deploy-h2c.sh default
```

### 4. 테스트

```bash
# Gateway IP 확인
GATEWAY_IP=$(kubectl get gateway grpc-gateway-h2c -o jsonpath='{.status.addresses[0].value}')

# gRPC 서버 테스트
./test-grpc.sh $GATEWAY_IP:80
```

## 📦 배포 시나리오

### 시나리오 1: H2C 서버 (내부 통신)

ALB와 Pod 간 통신에 H2C를 사용하는 가장 간단한 구성입니다.

```bash
# 배포
cd scripts
./deploy-h2c.sh

# 테스트
GATEWAY_IP=$(kubectl get gateway grpc-gateway-h2c -o jsonpath='{.status.addresses[0].value}')
./test-grpc.sh $GATEWAY_IP:80
```

**특징:**
- ✅ 인증서 관리 불필요
- ✅ VPC 내부 보안 네트워킹 활용
- ✅ 설정 간단

### 시나리오 2: TLS 서버 (End-to-End 암호화)

전체 구간 암호화가 필요한 경우 사용합니다.

```bash
# 1. 인증서 생성
cd certs
./generate-certs.sh

# 2. Secret 생성
kubectl create secret tls grpc-tls-secret \
  --cert=output/server.crt \
  --key=output/server.key

kubectl create secret tls grpc-gateway-tls-secret \
  --cert=output/server.crt \
  --key=output/server.key

# 3. 배포
cd ../scripts
./deploy-tls.sh

# 4. 테스트
GATEWAY_IP=$(kubectl get gateway grpc-gateway-tls -o jsonpath='{.status.addresses[0].value}')
./test-grpc.sh $GATEWAY_IP:443 --tls
```

**특징:**
- ✅ End-to-End TLS 암호화
- ✅ ALB에서 TLS Termination
- ⚠️ 인증서 관리 필요

### 시나리오 3: 멀티 버전 (카나리 배포)

새 버전을 점진적으로 배포하여 위험을 최소화합니다.

```bash
# 1. v1, v2 이미지 빌드
cd scripts
./build-and-push.sh PROJECT_ID REGION REPOSITORY v1
./build-and-push.sh PROJECT_ID REGION REPOSITORY v2

# 2. 멀티 버전 배포
kubectl apply -f ../k8s/multi-version/

# 3. 트래픽 분할 조정 (예: v1 90%, v2 10%)
# k8s/multi-version/httproute-split.yaml 수정
# - weight: 90  # v1
# - weight: 10  # v2

kubectl apply -f ../k8s/multi-version/httproute-split.yaml

# 4. 부하 테스트로 버전 분포 확인
for i in {1..20}; do
  grpcurl -plaintext -d '{"name": "Test"}' $GATEWAY_IP:80 \
    helloworld.Greeter/SayHello | grep version
done
```

**특징:**
- ✅ 가중치 기반 트래픽 분할
- ✅ 점진적 롤아웃
- ✅ 즉시 롤백 가능

## 🔍 트러블슈팅

### Gateway IP가 할당되지 않음

```bash
# Gateway 상태 확인
kubectl describe gateway grpc-gateway-h2c

# 일반적인 원인:
# - Gateway API가 클러스터에 활성화되지 않음
# - 백엔드 서비스가 준비되지 않음
```

### gRPC 연결 실패

```bash
# Pod 로그 확인
kubectl logs -l app=grpc-server-h2c

# Service 엔드포인트 확인
kubectl get endpoints grpc-server-h2c

# BackendConfig 상태 확인
kubectl describe backendconfig grpc-backendconfig
```

### TLS 인증서 오류

```bash
# Secret 확인
kubectl get secret grpc-tls-secret -o yaml

# 인증서 유효성 검증
openssl verify -CAfile certs/output/ca.crt certs/output/server.crt

# SAN 확인
openssl x509 -in certs/output/server.crt -text -noout | grep -A1 "Subject Alternative Name"
```

### 로드 밸런싱 불균형

gRPC는 HTTP/2 기반이므로 L7 로드 밸런싱이 필수입니다.

```bash
# HTTPRoute에서 백엔드 프로토콜 확인
kubectl get httproute grpc-route-h2c -o yaml

# Service에 appProtocol: HTTP2 설정 확인
kubectl get service grpc-server-h2c -o yaml | grep appProtocol
```

## 📚 추가 문서

- [GKE_Guide.md](GKE_Guide.md) - GKE 배포 및 운영 권장사항
- [certs/README.md](certs/README.md) - TLS 인증서 생성 가이드
- [specs/](specs/) - 프로젝트 기획 및 구현 문서
  - [implementation_plan.md](specs/implementation_plan.md) - Best practices 개선 계획
  - [task.md](specs/task.md) - 작업 체크리스트
  - [walkthrough.md](specs/walkthrough.md) - 프로젝트 완료 요약

## 🔒 보안 및 Best Practices

이 프로젝트는 다음 보안 및 운영 best practices를 따릅니다:

- ✅ **비루트 실행**: 모든 컨테이너는 비루트 사용자(65532)로 실행
- ✅ **최소 권한**: 불필요한 Linux capabilities 제거
- ✅ **Graceful Shutdown**: 안전한 서버 종료 및 요청 완료 보장
- ✅ **향상된 Health Probes**: timeout 및 failureThreshold 설정
- ✅ **리소스 최적화**: GKE Autopilot에 최적화된 requests/limits
- ✅ **에러 핸들링**: 강화된 스크립트 에러 처리 및 디버깅

## 🤝 기여

이슈나 개선 사항이 있으면 언제든지 제안해주세요!

## 📄 라이선스

MIT License
