# GKE 배포 및 권장사항 가이드 (Google Cloud 관점)

이 가이드는 Google Kubernetes Engine(GKE) 환경에서 애플리케이션(특히 gRPC)을 효율적이고 안정적으로 배포하고 운영하기 위한 실무 지침을 제공합니다.

---

## 1. GKE 배포 (Deployment)

### 1.1. 클러스터 환경 구성
*   **GKE Autopilot 권장**: 인프라 관리 부담을 최소화하고 Google의 권장사항이 기본 적용된 Autopilot 모드 사용을 권장합니다.
*   **비공개 클러스터 (Private Cluster)**: 보안을 위해 노드에 공개 IP를 부여하지 않는 비공개 클러스터 구성을 기본으로 합니다. 외부 통신이 필요한 경우 Cloud NAT를 활용합니다.

### 1.2. 이미지 관리 및 빌드
*   **Artifact Registry 활용**: Docker 이미지는 버전별로 Artifact Registry에 저장하여 관리합니다. (예: `v1`, `v2` 태그를 통한 멀티 버전 관리)
*   **빌드 환경**: Cloud Build 또는 GCE VM(Ubuntu) 환경에서 `docker build`를 통해 이미지를 생성하고 레지스트리에 푸시합니다.

### 1.3. 보안 및 TLS 설정
*   **인증서 생성**: `openssl`을 사용하여 CA 및 서버 인증서를 생성합니다. 이때 `SAN(Subject Alternative Name)` 설정이 올바른지 확인해야 합니다.
*   **Kubernetes Secret**: 생성된 인증서와 키를 Kubernetes Secret으로 등록하여 워크로드에서 참조할 수 있도록 합니다.
    ```bash
    kubectl create secret tls grpc-tls-secret --key server.key --cert server.crt
    ```

### 1.4. GKE Gateway API 설정 (Modern Load Balancing)
기존 Ingress 대신 더 세밀한 트래픽 제어가 가능한 **Gateway API** 사용을 권장합니다.

*   **Gateway 설정**: `gcr.io/google.com/gwapi/external-alb` 클래스를 사용하여 Global External Application Load Balancer(ALB)를 자동으로 프로비저닝합니다.
*   **HTTPRoute 설정**:
    *   **프로토콜 지정**: gRPC 통신을 위해 백엔드 프로토콜을 HTTP/2로 명시합니다.
    *   **트래픽 분할**: 가중치(Weight)를 기반으로 여러 버전의 서비스로 트래픽을 분산할 수 있습니다. (예: v1 50%, v2 50%)

---

## 2. GKE 권장사항 (Best Practices)

### 2.1. 보안 권장사항 (Security)
*   **TLS Termination**: 부하 분산기(ALB) 레벨에서 TLS를 종료(Termination)하여 어플리케이션 Pod의 암호화 부하를 줄입니다.
*   **Last-mile 보안 (H2C)**: ALB와 GKE Pod 사이의 내부 통신은 인증서 관리가 간단한 **H2C (HTTP/2 Cleartext)** 방식을 사용하되, VPC 내부의 보안 네트워킹을 활용합니다.
*   **최소 권한 원칙**: IAM 및 RBAC을 통해 필요한 최소한의 권한만 부여합니다.

### 2.2. 성능 및 부하 분산 (Performance & Load Balancing)
*   **gRPC를 위한 L7 로드 밸런싱**: gRPC는 단일 TCP 연결에서 많은 요청을 다중화(Multiplexing)하므로, L4 로드 밸런싱은 불균형을 초래합니다. **GKE Gateway(L7 ALB)**를 사용하여 요청 단위로 부하를 균등하게 분산해야 합니다.
*   **오토스케일링 최적화**: Autopilot 환경에서는 Resource Request/Limit을 명확히 설정하여 수평적 포드 자동 확장(HPA)이 원활하게 작동하도록 합니다.

### 2.3. 운영 전략 (Operational Excellence)
*   **카나리 배포 (Canary Deployment)**: 새로운 버전을 배포할 때 `HTTPRoute`의 가중치 조절 기능을 활용하여 점격적으로 트래픽을 넘기며 모니터링합니다.
*   **비용 최적화**: Autopilot의 리소스 기반 과금 체계를 활용하고, 불필요한 공인 IP 사용을 자제합니다.

---

> [!TIP]
> **Gateway API vs Ingress**: gRPC 서비스나 복잡한 트래픽 라우팅이 필요한 경우 Ingress보다 Gateway API가 훨씬 유연하고 강력한 성능을 제공합니다.
