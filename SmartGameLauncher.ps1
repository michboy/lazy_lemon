# --- Config ---
$SandboxiePath = "C:\Program Files\Sandboxie-Plus"
$SandboxName = "GameBox"
$GameRoot = "C:\Server\games"
$SandboxRoot = "C:\Sandbox\$env:USERNAME\$SandboxName"

# Check Sandboxie
if (-not (Test-Path "$SandboxiePath\Start.exe")) {
    Write-Host "Error: Sandboxie not found at '$SandboxiePath'" -ForegroundColor Red
    exit
}

# Init Sandbox
Start-Process "$SandboxiePath\SbieIni.exe" -ArgumentList "set $SandboxName Enabled y" -Wait -WindowStyle Hidden

# 1. Select Game
$GameList = Get-ChildItem -Path $GameRoot -Directory
Write-Host "=== Game List ===" -ForegroundColor Cyan
$i = 0
foreach ($game in $GameList) {
    Write-Host "[$i] $($game.Name)"
    $i++
}

$Selection = Read-Host "Enter game number"
if ($Selection -match "^\d+$" -and [int]$Selection -lt $GameList.Count) {
    $TargetGame = $GameList[[int]$Selection]
} else {
    Write-Host "Invalid selection." -ForegroundColor Red; exit
}

# Find Exe
$ExeFiles = Get-ChildItem -LiteralPath $TargetGame.FullName -Filter *.exe -Recurse
if ($ExeFiles.Count -eq 0) { Write-Host "No .exe found." -ForegroundColor Red; exit }
$GameExe = $ExeFiles | Sort-Object Length -Descending | Select-Object -First 1

# 2. Clean Sandbox
Write-Host "[1] Cleaning Sandbox..." -ForegroundColor Yellow
Start-Process "$SandboxiePath\SbieIni.exe" -ArgumentList "delete $SandboxName" -Wait

# 3. Run Game
$StartTime = Get-Date 
Write-Host "[2] Running '$($TargetGame.Name)'..." -ForegroundColor Green
# /wait 옵션을 추가했지만, 확실하게 하기 위해 아래 Read-Host를 씁니다.
Start-Process "$SandboxiePath\Start.exe" -ArgumentList "/box:$SandboxName /wait `"$($GameExe.FullName)`"" 

# --- [핵심 수정] 여기서 무조건 기다립니다 ---
Write-Host " "
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   Game is running inside Sandbox!" -ForegroundColor Cyan
Write-Host "   1. Play the game." -ForegroundColor Gray
Write-Host "   2. Save your progress." -ForegroundColor Gray
Write-Host "   3. Quit the game." -ForegroundColor Gray
Write-Host "   4. THEN PRESS ENTER HERE TO SYNC SAVES." -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "==========================================" -ForegroundColor Cyan
Read-Host " >> Waiting for user... (Press Enter after closing the game)"
# ---------------------------------------------

# 4. Deep Analysis
Write-Host "[3] Hunting for Save Files (Modified after $($StartTime.ToString("HH:mm:ss")))..." -ForegroundColor Yellow

$DriveLetter = $TargetGame.FullName.Substring(0,1)
$PathWithoutDrive = $TargetGame.FullName.Substring(3)
$SandboxedGamePath = "$SandboxRoot\drive\$DriveLetter\$PathWithoutDrive"
$SandboxedUserProfile = "$SandboxRoot\user\current"

$ExcludeExt = @(".exe", ".dll", ".bat", ".cmd", ".msi", ".tmp", ".log", ".ini", ".db")

function Find-Changes ($Path, $Label) {
    if (Test-Path -LiteralPath $Path) {
        return @(Get-ChildItem -LiteralPath $Path -Recurse -File | Where-Object { 
            $_.LastWriteTime -gt $StartTime -and 
            $ExcludeExt -notcontains $_.Extension
        })
    }
    return @() 
}

# Scan
$ChangesInGameFolder = Find-Changes $SandboxedGamePath "Game Folder"
$ChangesInUserProfile = Find-Changes $SandboxedUserProfile "AppData/Docs"

$AllChanges = $ChangesInGameFolder + $ChangesInUserProfile | Where-Object { $_ -ne $null }

if ($AllChanges.Count -gt 0) {
    Write-Host " >> Found $($AllChanges.Count) new/modified files:" -ForegroundColor Cyan
    $AllChanges | ForEach-Object { 
        Write-Host "    - [$($_.Extension)] $($_.Name)" 
    }

    $UserConfirm = Read-Host " >> Backup these files to game folder? (y/n)"
    if ($UserConfirm -eq 'y') {
        # Sync Game Folder
        if ($ChangesInGameFolder.Count -gt 0) {
            robocopy $SandboxedGamePath $TargetGame.FullName /E /XO /XF $ExcludeExt /IS /IT /NjH /NJS /NDL /NC /NS
        }
        # Sync UserProfile
        if ($ChangesInUserProfile.Count -gt 0) {
            $BackupFolder = "$($TargetGame.FullName)\_Saves_Backup"
            if (-not (Test-Path -LiteralPath $BackupFolder)) { New-Item -Path $BackupFolder -ItemType Directory | Out-Null }
            foreach ($file in $ChangesInUserProfile) {
                Copy-Item -LiteralPath $file.FullName -Destination $BackupFolder -Force
            }
            Write-Host " >> System saves copied to: _Saves_Backup" -ForegroundColor Gray
        }
        Write-Host " >> [SUCCESS] All saves backed up!" -ForegroundColor Green
    }
} else {
    Write-Host " >> No new save files detected." -ForegroundColor Gray
}

# 5. Destroy
Write-Host "[4] Destroying Sandbox..." -ForegroundColor Red
Start-Process "$SandboxiePath\SbieIni.exe" -ArgumentList "delete $SandboxName" -Wait