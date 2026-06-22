# Claude Skills 一键部署/更新脚本
# 用法: powershell -ExecutionPolicy Bypass -File setup.ps1
# 首次运行: 备份本地 → 克隆仓库 → 拷回独有技能
# 后续运行: 跳过备份克隆，直接 git pull

$ErrorActionPreference = "Stop"
$SkillsDir = "$env:USERPROFILE\.claude\skills"
$BackupDir = "$env:USERPROFILE\.claude\skills.bak"
$RepoUrl  = "https://github.com/Jehomn/claude-skills.git"

# 仓库中的技能名列表（更新仓库后此处需同步）
$RepoSkills = @(
    'bb-analysis',
    'glm-chat',
    'ppt-builder',
    'source-library-builder',
    'vet-lit-review'
)

Write-Host "=== Claude Skills Setup ===" -ForegroundColor Cyan

if (Test-Path "$SkillsDir\.git") {
    Write-Host "[UPDATE] Pulling latest from GitHub..." -ForegroundColor Yellow
    Push-Location $SkillsDir
    git pull origin master
    Pop-Location
    Write-Host "[OK] Skills updated." -ForegroundColor Green
    exit 0
}

if (Test-Path $SkillsDir) {
    Write-Host "[BACKUP] Moving existing skills to skills.bak..." -ForegroundColor Yellow
    if (Test-Path $BackupDir) {
        Remove-Item -Recurse -Force $BackupDir
    }
    Move-Item $SkillsDir $BackupDir

    Write-Host "[CLONE] Cloning repo..." -ForegroundColor Yellow
    git clone $RepoUrl $SkillsDir

    Write-Host "[MERGE] Copying back local-only skills..." -ForegroundColor Yellow
    Get-ChildItem $BackupDir -Directory | Where-Object {
        $_.Name -notin $RepoSkills
    } | ForEach-Object {
        Write-Host "  + $($_.Name)"
        Copy-Item -Recurse $_.FullName "$SkillsDir\"
    }

    Write-Host "[OK] Done. Backup kept at $BackupDir" -ForegroundColor Green
    Write-Host "      Review and remove it when ready: Remove-Item -Recurse -Force '$BackupDir'"
} else {
    Write-Host "[CLONE] Fresh install..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude" | Out-Null
    git clone $RepoUrl $SkillsDir
    Write-Host "[OK] Done." -ForegroundColor Green
}

Write-Host ""
Write-Host "Next: pip install pyyaml openai --break-system-packages   (if using source-library-builder)" -ForegroundColor DarkGray
Write-Host "Next: choco install xpdf   (if using pdftotext)" -ForegroundColor DarkGray
