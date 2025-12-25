# GKE 배포 및 권장사항 가이드 프로젝트

이 프로젝트는 Google Cloud 관점에서의 GKE(Google Kubernetes Engine) 배포 전략과 운영 권장사항을 정리한 가이드를 포함하고 있습니다.

## 프로젝트 개요
Google Cloud의 최신 기술 스택(Gateway API, gRPC, Autopilot 등)을 활용하여 안정적이고 효율적인 컨테이너 인프라를 구축하는 방법을 제시합니다.

## 포함된 가이드 내용
- **GKE 배포 (Deployment)**:
    - GKE Autopilot 및 비공개 클러스터 구성
    - Gateway API를 활용한 L7 로드 밸런싱 (gRPC 최적화)
    - TLS 인증서 관리 및 Secret 설정
- **권장사항 (Best Practices)**:
    - 보안 최적화 (TLS Termination, H2C)
    - L7 기반 gRPC 부하 분산 전략
    - 카나리 배포 등 운영 전략

## 상세 가이드 링크
- [GKE_Guide.md](./GKE_Guide.md): 상세한 배포 단계 및 권장사항 기술

---
*본 가이드는 제공된 실무 가이드를 바탕으로 작성되었습니다.*
