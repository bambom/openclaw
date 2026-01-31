# OpenClaw Backup Script Template
# 复制此文件到 oneyemo\backup-scripts\ 目录后修改配置

# ==================== 配置区域 ====================
# 根据你的身份修改以下配置

# 1. OpenClaw 源目录（每个人的可能不同）
# 大师兄: C:\Users\bambo\.openclaw
# 师傅: C:\Users\shifu\.openclaw
# 小师妹: C:\Users\xiaomeimei\.openclaw
$sourceDir = "C:\Users\bambo\.openclaw"

# 2. 备份目标目录（相对路径，从 oneyemo 根目录开始）
# 大师兄: dashixiong-workspace\openclaw-backup
# 师傅: shifu-workspace\openclaw-backup
# 小师妹: xiaomeimei-workspace\openclaw-backup
$backupDir = "..\dashixiong-workspace\openclaw-backup"

# ==================================================

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
    Write-Host ""
    Write-Host "💡 提示：请检查脚本中的 `$sourceDir` 配置" -ForegroundColor Yellow
    Write-Host "常见路径：" -ForegroundColor Cyan
    Write-Host "  - C:\Users\bambo\.openclaw" -ForegroundColor White
    Write-Host "  - C:\Users\shifu\.openclaw" -ForegroundColor White
    Write-Host "  - C:\Users\xiaomeimei\.openclaw" -ForegroundColor White
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
    /XD .git `
    /XF *.lock `
    /XF *.log `
    /XF *.db `
    /XF *.sqlite `
    /XF *.sqlite3 `
    /XF *.tmp `
    /XF *.temp `
    /NJH /NJS /NFL /NDL /NC /NS

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  备份完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# 统计信息
$fileCount = (Get-ChildItem $backupDir -Recurse -File | Measure-Object).Count
Write-Host "备份文件数: $fileCount" -ForegroundColor Cyan

if ($fileCount -gt 0) {
    $backupSize = (Get-ChildItem $backupDir -Recurse -File | Measure-Object -Property Length).Sum
    $sizeMB = [math]::Round($backupSize / 1MB, 2)
    Write-Host "备份大小: $sizeMB MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Yellow
Write-Host "1. 进入你的工作区目录：" -ForegroundColor White
Write-Host "   cd ..\dashixiong-workspace       # 或 shifu-workspace、xiaomeimei-workspace" -ForegroundColor Gray
Write-Host "2. 添加到 Git：" -ForegroundColor White
Write-Host "   git add openclaw-backup/" -ForegroundColor Gray
Write-Host "3. 提交到 Git：" -ForegroundColor White
Write-Host "   git commit -m 'backup: OpenClaw data sync'" -ForegroundColor Gray
Write-Host "4. 推送到远程：" -ForegroundColor White
Write-Host "   git push" -ForegroundColor Gray
