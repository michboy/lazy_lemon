<div align="center">

<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white">
<img src="https://img.shields.io/badge/Windows_Server-0078D6?style=for-the-badge&logo=windows&logoColor=white">
<img src="https://img.shields.io/badge/PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white">
<img src="https://img.shields.io/badge/Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white">
<img src="https://img.shields.io/badge/Tailscale-18181B?style=for-the-badge&logo=tailscale&logoColor=white">
<img src="https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white">
<img src="https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white">

</div>
<br>

[N150 Server Deployment Guide]

1. 기본 설치
   - Docker Desktop 설치
   - Sandboxie-Plus 설치 (게이밍용)
   - Tailscale 로그인

2. 서버 실행 (PowerShell 관리자 권한)
   cd C:\Server\1_Server_Config
   docker-compose up -d
   docker-compose -f docker-compose-auth.yml up -d

3. 게이밍 & 보안 (Smart Launcher 사용)
   * 주의: 별도의 Sandboxie 'Direct Access' 설정 불필요 (스크립트가 자동 처리)
   - 실행: PowerShell에서 `.\SmartGameLauncher.ps1` 실행
   - 기능: 
     1. 게임을 샌드박스 격리 공간에서 실행
     2. 종료 시 세이브 파일만 감지하여 `_Saves_Backup` 폴더로 자동 백업

4. 네트워크 트래픽 분리 규칙 (Split Tunneling)
   [A] Cloudflare Tunnel에 등록할 것 -> 도메인으로 접속 (komga.michboy.xyz)
   - Komga (localhost:8080)
   - Grafana (localhost:3001)
   - Portainer (localhost:9000)
   - AdGuard (localhost:3000)

   [B] Tailscale로 접속할 것 -> IP로 접속 (100.x.y.z:8096)
   - Jellyfin (영상 스트리밍 대역폭 확보 및 약관 준수)
   - Sunshine/Moonlight (실시간 게이밍 레이턴시 최적화)

---
## 🚧 주의사항 및 개발 현황 (Disclaimer)
이 프로젝트는 현재 **개발 진행 중(Work In Progress)**입니다.

1. **폴더 구조 및 미디어 동기화**: 
   - `media/music`, `games` 등의 세부 폴더 생성은 자동화되어 있지 않습니다.
   - 음악용 디바이스 및 기타 기기와의 동기화 설정은 사용자의 환경에 맞춰 별도로 진행해야 합니다.
   
2. **포맷 및 표준화**:
   - 파일 포맷 통일 작업이 진행 중이며, 일부 설정은 레거시(Legacy) 방식일 수 있습니다.

3. **현재 RAM 가격 인상으로 인하여, 임시로 raspberry pi 5에다가 약 32~64gb짜기 외장하드를 연결하는 간단한 프로젝트로 변경하겠음**
   -   라즈베리파이 5를 기준으로 사용하되, intel에서 제공하는 기본 방화벼 프로그램은 뺴고, 나머지 cloudflare및 sso등은 계속 이용하겠음.
3. **안정성**:
   - 코드가 부분적으로 리팩토링 및 수정된 상태이므로, 기능 검증이 필요할 수 있습니다.
   - 사용 시 본인의 환경에 맞게 `docker-compose.yml` 및 `.env` 파일의 2차 검증을 권장합니다.
