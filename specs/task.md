# GKE gRPC 프로젝트 코드 정리 작업

## 프로젝트 구조 설계
- [x] 디렉토리 구조 계획 수립
- [x] 샘플 애플리케이션 종류 파악 (H2C, TLS 등)

## 소스 코드 구성
- [x] gRPC 서버 애플리케이션 코드 작성
  - [x] H2C (HTTP/2 Cleartext) 버전
  - [x] TLS 버전
  - [x] 멀티 버전 지원 (v1, v2)
- [x] Dockerfile 작성
  - [x] H2C 서버용
  - [x] TLS 서버용

## Kubernetes 매니페스트 작성
- [x] Deployment 매니페스트
  - [x] H2C 서버 배포
  - [x] TLS 서버 배포
  - [x] 멀티 버전 배포 (v1, v2)
- [x] Service 매니페스트
- [x] Gateway API 리소스
  - [x] Gateway 설정
  - [x] HTTPRoute 설정 (트래픽 분할 포함)
- [x] Secret 생성 스크립트 (TLS 인증서)

## 인증서 및 보안
- [x] TLS 인증서 생성 스크립트
  - [x] CA 인증서 생성
  - [x] 서버 인증서 생성 (SAN 포함)
- [x] Secret 생성 명령어 문서화

## 배포 스크립트 및 가이드
- [x] 빌드 및 배포 스크립트 작성
- [x] README 업데이트
  - [x] 프로젝트 구조 설명
  - [x] 빌드 방법
  - [x] 배포 방법
  - [x] 테스트 방법

## 테스트 및 검증
- [x] gRPC 클라이언트 테스트 코드
- [x] 연결 테스트 스크립트
