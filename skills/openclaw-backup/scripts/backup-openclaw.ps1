# OpenClaw Backup Script
# 多用户备份支持：每个用户配置自己的备份路径

# ==================== 用户配置区域 ====================
# 根据你的情况修改以下配置

# 1. OpenClaw 数据源目录（通常不需要修改）
$sourceDir = "C:\Users\bambo\.openclaw"

# 2. 备份目标目录（每个用户不同）
# 大师兄：E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup
# 师傅：E:\Workspace\oneyoemo\shifu-workspace\openclaw-backup
# 小师妹：E:\Workspace\oneyoemo\shimei-workspace\openclaw-backup
$backupDir = "E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup"

# ====================================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  OpenClaw 备份工具" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "源目录: $sourceDir" -ForegroundColor Yellow
Write-Host "备份目录: $backupDir" -ForegroundColor Yellow
Write-Host ""

# 检查源目录是否存在
if (!(Test-Path $sourceDir)) {
    Write-Host "错误：源目录不存在！" -ForegroundColor Red
    Write-Host "请检查脚本中的 `$sourceDir` 配置" -ForegroundColor Yellow
    exit 1
}

# 创建备份目录（如果不存在）
if (!(Test-Path $backupDir)) {
    Write-Host "创建备份目录: $backupDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# 执行备份
Write-Host "开始备份..." -ForegroundColor Cyan
Write-Host "已排除：node_modules、.lock、.log、数据库等文件" -ForegroundColor Yellow

# 使用 robocopy 快速复制并排除不需要的文件
robocopy $sourceDir $backupDir /E `
    /XD node_modules `
    /XF *.lock `
    /XF *.log `
    /XF *.db `
    /XF *.sqlite `
    /XF *.sqlite3 `
    /XF *.tmp `
    /XF *.temp `
    /XF package-lock.json `
    /XF yarn.lock `
    /NJH /NJS /NFL /NDL /NC /NS

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  备份完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "备份文件数: " -NoNewline -ForegroundColor Cyan
(Get-ChildItem $backupDir -Recurse -File | Measure-Object).Count
Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Yellow
Write-Host "1. 提交到 Git：" -ForegroundColor White
Write-Host "   cd E:\Workspace\oneyoemo" -ForegroundColor Gray
Write-Host "   git add (你的备份目录)/" -ForegroundColor Gray
Write-Host "   git commit -m 'backup: OpenClaw data sync'" -ForegroundColor Gray
Write-Host "   git push" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 或者使用自动化脚本（需要先创建）：" -ForegroundColor White
Write-Host "   scripts\backup-and-commit.bat" -ForegroundColor Gray
Write-Host ""

# 统计信息
$sourceSize = (Get-ChildItem $sourceDir -Recurse -File | Measure-Object -Property Length).Sum
$backupSize = (Get-ChildItem $backupDir -Recurse -File | Measure-Object -Property Length).Sum

Write-Host "原始大小: " -NoNewline -ForegroundColor Cyan
Write-Host "{0:N2} MB" -f ($sourceSize / 1MB) -ForegroundColor White
Write-Host "备份大小: " -NoNewline -ForegroundColor Cyan
Write-Host "{0:N2} MB" -f ($backupSize / 1MB) -ForegroundColor White
Write-Host "节省空间: " -NoNewline -ForegroundColor Green
Write-Host "{0:N2} MB ({1:N1}%)" -f (($sourceSize - $backupSize) / 1MB, (($sourceSize - $backupSize) / $sourceSize * 100)) -ForegroundColor Green
