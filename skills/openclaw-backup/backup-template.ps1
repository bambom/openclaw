# OpenClaw Backup Script Template
# 复制此文件到你的 oneyemo 目录后修改配置

# ==================== 配置区域 ====================
# 请根据你的实际情况修改以下两项配置

# 1. OpenClaw 源目录（通常在每个用户的用户目录下）
# 大师兄: C:\Users\bambo\.openclaw
# 师傅: C:\Users\shifu\.openclaw
# 小师妹: C:\Users\xiaomeimei\.openclaw
$sourceDir = "C:\Users\你的用户名\.openclaw"

# 2. 备份目标目录（你的 oneyemo 工作区路径）
# 小师妹（C盘）: C:\oneyoemo\openclaw-backup
# 师傅: E:\Workspace\oneyoemo\openclaw-backup
# 大师兄: E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup
$backupDir = "C:\oneyoemo\openclaw-backup"

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

# 统计信息
$fileCount = (Get-ChildItem $backupDir -Recurse -File | Measure-Object).Count
$backupSize = (Get-ChildItem $backupDir -Recurse -File | Measure-Object -Property Length).Sum

Write-Host "备份文件数: $fileCount" -ForegroundColor Cyan

if ($backupSize -gt 0) {
    $sizeMB = [math]::Round($backupSize / 1MB, 2)
    Write-Host "备份大小: $sizeMB MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "下一步操作：" -ForegroundColor Yellow
Write-Host "1. 提交到 Git：" -ForegroundColor White
Write-Host "   cd C:\oneyoemo          # 或 E:\oneyoemo、E:\Workspace\oneyoemo" -ForegroundColor Gray
Write-Host "   git add openclaw-backup/" -ForegroundColor Gray
Write-Host "   git commit -m 'backup: OpenClaw data sync'" -ForegroundColor Gray
Write-Host "   git push" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 或使用定时任务自动备份" -ForegroundColor White
