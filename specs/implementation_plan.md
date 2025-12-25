# GKE gRPC 프로젝트 코드 정리 계획

기존 GKE 가이드 문서를 기반으로 실제 동작하는 샘플 코드와 Kubernetes 매니페스트를 정리하여 완전한 레퍼런스 프로젝트를 구성합니다.

## User Review Required

> [!IMPORTANT]
> Google Docs에 있는 구체적인 코드 내용을 확인해야 정확한 구현이 가능합니다. 다음 중 하나의 방법으로 진행해주세요:
> 1. Google Docs의 코드 스니펫을 복사하여 제공
> 2. Google Docs를 공개 문서로 변경
> 3. 기존 가이드를 기반으로 표준 gRPC 샘플 코드 작성

현재는 **옵션 3**으로 진행하여 일반적인 GKE gRPC 프로젝트 구조를 제안합니다.

---

## Proposed Changes

### 프로젝트 구조

```
gke_test_001/
├── README.md                          # 프로젝트 전체 설명
├── GKE_Guide.md                       # 기존 가이드 (유지)
├── apps/                              # 애플리케이션 소스 코드
│   ├── grpc-server-h2c/              # H2C 서버
│   │   ├── main.go
│   │   ├── Dockerfile
│   │   └── proto/
│   │       └── helloworld.proto
│   ├── grpc-server-tls/              # TLS 서버
│   │   ├── main.go
│   │   ├── Dockerfile
│   │   └── proto/
│   │       └── helloworld.proto
│   └── grpc-client/                   # 테스트 클라이언트
│       ├── main.go
│       └── Dockerfile
├── k8s/                               # Kubernetes 매니페스트
│   ├── h2c/                          # H2C 배포
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── gateway.yaml
│   │   └── httproute.yaml
│   ├── tls/                          # TLS 배포
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
│       └── httproute-split.yaml
├── certs/                             # TLS 인증서 생성
│   ├── generate-certs.sh
│   └── README.md
└── scripts/                           # 빌드 및 배포 스크립트
    ├── build-and-push.sh
    ├── deploy-h2c.sh
    ├── deploy-tls.sh
    └── test-grpc.sh
```

---

### Applications

#### [NEW] [main.go](file:///Users/jungwoonlee/gke_test_001/apps/grpc-server-h2c/main.go)
- Go 기반 gRPC 서버 (H2C 프로토콜)
- Health check 엔드포인트 포함
- 버전 정보 응답 기능

#### [NEW] [Dockerfile](file:///Users/jungwoonlee/gke_test_001/apps/grpc-server-h2c/Dockerfile)
- 멀티 스테이지 빌드
- 최소 크기 이미지 (distroless 또는 alpine)

#### [NEW] [main.go](file:///Users/jungwoonlee/gke_test_001/apps/grpc-server-tls/main.go)
- Go 기반 gRPC 서버 (TLS 지원)
- 인증서 로딩 및 검증

#### [NEW] [helloworld.proto](file:///Users/jungwoonlee/gke_test_001/apps/grpc-server-h2c/proto/helloworld.proto)
- 간단한 gRPC 서비스 정의
- SayHello RPC 메서드

---

### Kubernetes Manifests

#### [NEW] [deployment.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/h2c/deployment.yaml)
- H2C gRPC 서버 Deployment
- Resource requests/limits 설정
- Liveness/Readiness probes

#### [NEW] [service.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/h2c/service.yaml)
- ClusterIP Service
- HTTP/2 프로토콜 어노테이션

#### [NEW] [gateway.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/h2c/gateway.yaml)
- Gateway API 리소스
- `gcr.io/google.com/gwapi/external-alb` 클래스 사용
- HTTPS 리스너 설정

#### [NEW] [httproute.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/h2c/httproute.yaml)
- HTTPRoute 리소스
- 백엔드 프로토콜: H2C
- 경로 기반 라우팅

#### [NEW] [deployment.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/tls/deployment.yaml)
- TLS gRPC 서버 Deployment
- Secret 볼륨 마운트

#### [NEW] [secret.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/tls/secret.yaml)
- TLS Secret 생성 예시
- Base64 인코딩된 인증서/키

#### [NEW] [httproute-split.yaml](file:///Users/jungwoonlee/gke_test_001/k8s/multi-version/httproute-split.yaml)
- 트래픽 분할 설정
- v1: 50%, v2: 50% 가중치

---

### Certificates

#### [NEW] [generate-certs.sh](file:///Users/jungwoonlee/gke_test_001/certs/generate-certs.sh)
- OpenSSL을 사용한 CA 인증서 생성
- 서버 인증서 생성 (SAN 포함)
- Kubernetes Secret 생성 명령어

---

### Scripts

#### [NEW] [build-and-push.sh](file:///Users/jungwoonlee/gke_test_001/scripts/build-and-push.sh)
- Docker 이미지 빌드
- Artifact Registry에 푸시
- 버전 태깅 (v1, v2)

#### [NEW] [deploy-h2c.sh](file:///Users/jungwoonlee/gke_test_001/scripts/deploy-h2c.sh)
- H2C 서버 배포 자동화
- kubectl apply 명령어 실행

#### [NEW] [deploy-tls.sh](file:///Users/jungwoonlee/gke_test_001/scripts/deploy-tls.sh)
- TLS 서버 배포 자동화
- Secret 생성 포함

#### [NEW] [test-grpc.sh](file:///Users/jungwoonlee/gke_test_001/scripts/test-grpc.sh)
- grpcurl을 사용한 연결 테스트
- H2C 및 TLS 엔드포인트 테스트

---

### Documentation

#### [MODIFY] [README.md](file:///Users/jungwoonlee/gke_test_001/README.md)
- 프로젝트 구조 설명 추가
- 빌드 및 배포 가이드
- 각 시나리오별 사용법
- 트러블슈팅 섹션

---

## Verification Plan

### Automated Tests
```bash
# 1. 코드 빌드 테스트
cd apps/grpc-server-h2c && go build -o server .
cd apps/grpc-server-tls && go build -o server .

# 2. Docker 이미지 빌드 테스트
docker build -t test-h2c apps/grpc-server-h2c
docker build -t test-tls apps/grpc-server-tls

# 3. Kubernetes 매니페스트 검증
kubectl apply --dry-run=client -f k8s/h2c/
kubectl apply --dry-run=client -f k8s/tls/
```

### Manual Verification
1. Google Docs의 실제 코드와 비교하여 누락된 부분 확인
2. 사용자가 제공하는 추가 요구사항 반영
3. 실제 GKE 클러스터에 배포하여 동작 확인 (사용자 환경)
