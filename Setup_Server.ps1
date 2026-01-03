# Setup_Server.ps1
# 관리자 권한 확인
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "관리자 권한이 필요합니다. 관리자 권한으로 다시 실행해 주세요."
    Start-Process powershell -Verb runAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

Write-Host "=== Zero Trust Server Auto-Setup ===" -ForegroundColor Cyan

# --- 1. 필수 프로그램 자동 설치 (Winget) ---
Write-Host "[1] Checking Dependencies..." -ForegroundColor Yellow
$Apps = @{
    "Docker Desktop" = "Docker.DockerDesktop"
    "Sandboxie-Plus" = "Sandboxie.Plus"
    "Git"            = "Git.Git"
    "VS Code"        = "Microsoft.VisualStudioCode"
}

foreach ($AppName in $Apps.Keys) {
    $Id = $Apps[$AppName]
    if (winget list -e $Id) {
        Write-Host " - $AppName is already installed." -ForegroundColor Gray
    } else {
        Write-Host " - Installing $AppName..." -ForegroundColor Green
        winget install -e --id $Id --accept-source-agreements --accept-package-agreements
    }
}

# --- 2. 폴더 구조 생성 ---
Write-Host "`n[2] Creating Directory Structure..." -ForegroundColor Yellow
$BaseDir = "C:\Server"
$Dirs = @(
    "$BaseDir\games",
    "$BaseDir\media\movies",
    "$BaseDir\media\comics",
    "$BaseDir\1_Server_Config\data\homepage",
    "$BaseDir\_Saves_Backup"
)

foreach ($Dir in $Dirs) {
    if (-not (Test-Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
        Write-Host " - Created: $Dir" -ForegroundColor Green
    }
}

# --- 3. IP 자동 감지 및 설정 파일 생성 (핵심!) ---
Write-Host "`n[3] Configuring Network & Environment..." -ForegroundColor Yellow

# 가장 유력한 로컬 IP 찾기 (Wi-Fi or Ethernet, 192.168.x.x or 10.x.x.x)
$MyIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { 
    $_.InterfaceAlias -notmatch "vEthernet|Loopback|Tailscale" -and 
    ($_.IPAddress -match "^192\.168\." -or $_.IPAddress -match "^10\.") 
} | Select-Object -First 1).IPAddress

if (-not $MyIP) {
    $MyIP = Read-Host "IP 자동 감지 실패. 서버 IP를 직접 입력하세요"
}
Write-Host " >> Detected Server IP: $MyIP" -ForegroundColor Cyan

# .env 파일 생성
$EnvTemplate = "$PSScriptRoot\templates\.env.template"
$EnvTarget = "$BaseDir\1_Server_Config\.env"

if (Test-Path $EnvTemplate) {
    $Content = Get-Content $EnvTemplate -Raw
    # 템플릿 변환 로직
    $Content = $Content -replace "{{SERVER_IP}}", $MyIP
    
    # 비밀번호가 비어있으면 랜덤 생성 혹은 사용자 입력 요청
    if ($Content -match "{{CHANGE_ME}}") {
        Write-Host " - 보안 설정을 위해 비밀번호를 입력해야 합니다."
        $UserPass = Read-Host " - Enter a secure password for services"
        $Content = $Content -replace "{{CHANGE_ME}}", $UserPass
    }
    
    $Content | Set-Content $EnvTarget
    Write-Host " - Generated: .env" -ForegroundColor Green
}

# services.yaml 파일 생성 (Homepage)
$SvcTemplate = "$PSScriptRoot\templates\services.yaml.template"
$SvcTarget = "$BaseDir\1_Server_Config\data\homepage\services.yaml"

if (Test-Path $SvcTemplate) {
    $Content = Get-Content $SvcTemplate -Raw
    $Content = $Content -replace "{{SERVER_IP}}", $MyIP
    $Content | Set-Content $SvcTarget
    Write-Host " - Generated: services.yaml (Pointing to $MyIP)" -ForegroundColor Green
}

# --- 4. 파일 배치 ---
Write-Host "`n[4] Deploying Scripts..." -ForegroundColor Yellow
# 현재 폴더의 파일들을 C:\Server로 복사 (이미 거기 있으면 패스)
Copy-Item "$PSScriptRoot\SmartGameLauncher.ps1" "$BaseDir\SmartGameLauncher.ps1" -Force
Copy-Item "$PSScriptRoot\docker-compose.yml" "$BaseDir\1_Server_Config\docker-compose.yml" -Force

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Cyan
Write-Host "1. Please restart your computer if Docker was just installed."
Write-Host "2. Run 'cd C:\Server\1_Server_Config; docker-compose up -d' to start server."
Write-Host "3. Access Dashboard at http://$($MyIP):8082"
Pause