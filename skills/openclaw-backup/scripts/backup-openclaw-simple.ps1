# OpenClaw Backup Script - Simplified

# Configuration
$sourceDir = "C:\Users\bambo\.openclaw"
$backupDir = "E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenClaw Backup Tool" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Source: $sourceDir" -ForegroundColor Yellow
Write-Host "Backup: $backupDir" -ForegroundColor Yellow

if (!(Test-Path $sourceDir)) {
    Write-Host "ERROR: Source directory not found!" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $backupDir)) {
    Write-Host "Creating backup directory: $backupDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

Write-Host ""
Write-Host "Starting backup..." -ForegroundColor Cyan
Write-Host "Excluding: node_modules, .lock, .log, database files" -ForegroundColor Yellow

robocopy $sourceDir $backupDir /E /XD node_modules /XF *.lock /XF *.log /XF *.db /XF *.sqlite /XF *.sqlite3 /XF *.tmp /XF *.temp /XF package-lock.json /XF yarn.lock /NJH /NJS /NFL /NDL /NC /NS

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Backup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

$fileCount = (Get-ChildItem $backupDir -Recurse -File | Measure-Object).Count
Write-Host "Files backed up: $fileCount" -ForegroundColor Cyan

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. cd E:\Workspace\oneyoemo"
Write-Host "2. git add dashixiong-workspace/openclaw-backup/"
Write-Host "3. git commit -m 'backup: OpenClaw data sync'"
Write-Host "4. git push"
