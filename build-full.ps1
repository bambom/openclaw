# build-full.ps1

$WorkspaceRoot = ".."
$ChinaRepoPath = Join-Path $WorkspaceRoot "openclaw-china"
$MainRepoPath = Get-Location

# 定义 Git 同步函数
function Sync-Repo ($Path) {
    Write-Host "`n=== Syncing repository at $Path ===" -ForegroundColor Cyan
    Push-Location $Path
    try {
        # 1. 尝试获取 upstream (源库) 更新
        # 需先配置 upstream: git remote add upstream <url>
        $remotes = git remote
        if ($remotes -contains "upstream") {
            Write-Host "Fetching and Rebasing from upstream..."
            git fetch upstream
            # 使用 rebase 保持线性历史，不产生 merge commit
            # 如果你本地没有新提交，它就相当于快进 (Fast-forward)
            git rebase upstream/main
            
            # 同步更新到自己的 fork 仓库 (origin)
            # 因为 rebase 可能会改变本地提交的 ID，所以需要强制推送
            # --force-with-lease 是比 --force 更安全的做法
            Write-Host "Pushing clean history to origin (fork)..."
            git push origin main --force-with-lease
        } else {
            Write-Host "No 'upstream' remote found. Pulling from 'origin'..." -ForegroundColor Yellow
            git pull
        }
    } catch {
        Write-Host "Git sync failed for $Path. Continuing..." -ForegroundColor Red
    }
    Pop-Location
}

# 1. 同步 OpenClaw 主库
Sync-Repo $MainRepoPath

# 2. 处理 OpenClaw China
if (Test-Path $ChinaRepoPath) {
    # 2.1 同步 OpenClaw China
    Sync-Repo $ChinaRepoPath

    # 2.2 编译 OpenClaw China
    Write-Host "`n=== Building OpenClaw China ===" -ForegroundColor Cyan
    Push-Location $ChinaRepoPath
    # 确保依赖已安装
    pnpm install
    # 编译
    pnpm build
    if ($LASTEXITCODE -ne 0) { 
        Write-Error "OpenClaw China build failed!"
        Pop-Location
        exit 1 
    }
    Pop-Location

    # 2.3 创建链接 (Junction)
    # 将 unified package (packages/channels) 链接到 extensions 目录
    $ExtensionTarget = Join-Path $MainRepoPath "extensions\openclaw-china-channels"
    $ExtensionSource = Join-Path $ChinaRepoPath "packages\channels"

    if (-not (Test-Path $ExtensionTarget)) {
        Write-Host "`n=== Linking OpenClaw China extensions ===" -ForegroundColor Cyan
        New-Item -ItemType Junction -Path $ExtensionTarget -Target $ExtensionSource | Out-Null
        Write-Host "Linked $ExtensionSource to $ExtensionTarget"
    }
} else {
    Write-Warning "OpenClaw China repository not found at $ChinaRepoPath. Skipping integration..."
}

# 3. 执行标准构建
Write-Host "`n=== Starting Main Build ===" -ForegroundColor Cyan
if (Test-Path ".\build-windows.ps1") {
    ./build-windows.ps1
} else {
    # 如果没有 build-windows.ps1，则直接运行 pnpm build
    pnpm build
}
