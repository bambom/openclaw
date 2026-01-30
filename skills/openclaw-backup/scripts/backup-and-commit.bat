@echo off
chcp 65001 >nul
echo ========================================
echo   OpenClaw 自动备份并提交
echo ========================================
echo.

REM 设置工作目录
set WORK_DIR=E:\Workspace\oneyoemo
set BACKUP_REL=dashixiong-workspace\openclaw-backup

echo.
echo [1/3] 执行备份...
powershell -ExecutionPolicy Bypass -File "%~dp0backup-openclaw.ps1"

echo.
echo [2/3] 添加到 Git...
cd /d %WORK_DIR%
git add %BACKUP_REL%/

echo.
echo [3/3] 提交到 Git...
git commit -m "backup: OpenClaw data sync"

echo.
echo ========================================
echo   已完成本地提交
echo ========================================
echo.
echo 如需推送到远程仓库，请运行：git push
echo.
pause
