[N150 Server Deployment Guide]

1. 기본 설치
   - Docker Desktop 설치
   - Sandboxie-Plus 설치 (게이밍용)
   - Tailscale 로그인

2. 서버 실행 (PowerShell 관리자 권한)
   cd C:\Server\1_Server_Config
   docker-compose up -d
   docker-compose -f docker-compose-auth.yml up -d

3. Sandboxie-Plus 세팅 (게이밍)
   - 새 박스 생성: "GamingBox"
   - 설정 -> File Access -> Direct Access -> Add -> 게임 세이브 경로 입력
     (예: C:\Users\User\Documents\My Games\*)

4. 네트워크 트래픽 분리 규칙 (Split Tunneling)
   [Cloudflare Tunnel에 등록할 것] -> 도메인으로 접속 (komga.michboy.xyz)
   - Komga (localhost:8080)
   - Grafana (localhost:3001)
   - Portainer (localhost:9000)
   - AdGuard (localhost:3000)

   [Tailscale로 접속할 것] -> IP로 접속 (100.x.y.z:8096)
   - Jellyfin (영상 스트리밍 대역폭 문제)
   - Sunshine/Moonlight (게임 레이턴시 문제)