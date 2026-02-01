# build-full.ps1

$WorkspaceRoot = ".."
$ChinaRepoPath = Join-Path $WorkspaceRoot "openclaw-china"
$MainRepoPath = Get-Location

# 定义 Git 同步函数
function Sync-Repo ($Path) {
    Write-Host "`n=== Syncing repository at $Path ===" -ForegroundColor Cyan
    Push-Location $Path
    
    # 1. 暂存更改
    $status = git status --porcelain
    $stashed = $false
    if ($status) {
        Write-Host "Unstaged changes detected. Stashing..." -ForegroundColor Yellow
        git stash
        $stashed = $true
    }

    # 2. 同步 upstream
    $remotes = git remote
    if ($remotes -contains "upstream") {
        Write-Host "Fetching and Rebasing from upstream..."
        git fetch upstream
        git rebase upstream/main
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Rebase failed. Aborting..."
            git rebase --abort
        } else {
            # 3. 推送 origin
            Write-Host "Pushing to origin..."
            git push origin main --force-with-lease 2>&1 | Out-Host
        }
    } else {
        Write-Host "No 'upstream' remote found. Pulling..."
        git pull
    }

    # 4. 恢复暂存
    if ($stashed) {
        Write-Host "Restoring stashed changes..."
        git stash pop
    }

    Pop-Location
}

# 1. 同步 OpenClaw 主库
Sync-Repo $MainRepoPath

# 2. 处理 OpenClaw China
if (Test-Path $ChinaRepoPath) {
    Sync-Repo $ChinaRepoPath

    Write-Host "`n=== Building OpenClaw China ===" -ForegroundColor Cyan
    Push-Location $ChinaRepoPath
    Write-Host "Installing dependencies..."
    pnpm install
    Write-Host "Building..."
    pnpm build
    if ($LASTEXITCODE -ne 0) { 
        Write-Error "OpenClaw China build failed!"
        Pop-Location
        exit 1 
    }
    Pop-Location

    # 3. 清理旧的聚合插件 (ID: channels)
    # 官方文档说明 channels 聚合包不能与独立插件同时存在
    Write-Host "`n=== Cleaning up aggregator extension (channels) ===" -ForegroundColor Cyan
    $ExtensionTarget = Join-Path $MainRepoPath "extensions\channels"
    if (Test-Path $ExtensionTarget) {
        Remove-Item -Path $ExtensionTarget -Recurse -Force
        Write-Host "Removed $ExtensionTarget"
    }
    if (Test-Path "extensions\openclaw-china-channels") {
        Remove-Item -Path "extensions\openclaw-china-channels" -Recurse -Force
    }

    # 3.5 Copy @openclaw-china/shared to packages/ to satisfy workspace dependencies
    $ChinaSharedSource = Join-Path $ChinaRepoPath "packages\shared"
    $ChinaSharedTarget = Join-Path $MainRepoPath "packages\openclaw-china-shared"
    
    if (Test-Path $ChinaSharedSource) {
        Write-Host "`n=== Copying @openclaw-china/shared to packages/ ===" -ForegroundColor Cyan
        if (Test-Path $ChinaSharedTarget) {
            Remove-Item -Path $ChinaSharedTarget -Recurse -Force
        }
        Copy-Item -Path $ChinaSharedSource -Destination $ChinaSharedTarget -Recurse -Force
        Write-Host "Copied $ChinaSharedSource to $ChinaSharedTarget"
    }

    # 3.6 Copy tsconfig.base.json to root to satisfy extension build requirements
    $ChinaTsConfigSource = Join-Path $ChinaRepoPath "tsconfig.base.json"
    $MainTsConfigTarget = Join-Path $MainRepoPath "tsconfig.base.json"
    if (Test-Path $ChinaTsConfigSource) {
        Write-Host "`n=== Copying tsconfig.base.json to root ===" -ForegroundColor Cyan
        Copy-Item -Path $ChinaTsConfigSource -Destination $MainTsConfigTarget -Force
        Write-Host "Copied $ChinaTsConfigSource to $MainTsConfigTarget"
    }

    # 4. Process OpenClaw China Extensions
    $ChinaExtensionsDir = Join-Path $ChinaRepoPath "extensions"
    $TargetExtensionsDir = Join-Path $MainRepoPath "extensions"

    if (Test-Path $ChinaExtensionsDir) {
        Write-Host "`n=== Copying OpenClaw China Extensions ===" -ForegroundColor Cyan
        
        $extensions = Get-ChildItem -Path $ChinaExtensionsDir -Directory
        $copiedExtensions = @()

        foreach ($ext in $extensions) {
            $extName = $ext.Name
            $sourcePath = $ext.FullName
            $destPath = Join-Path $TargetExtensionsDir $extName
            
            Write-Host "Copying extension: $extName"
            
            # Copy to openclaw/extensions (Overwrite)
            Write-Host "  Copying to $destPath..."
            Copy-Item -Path $sourcePath -Destination $TargetExtensionsDir -Recurse -Force
            $copiedExtensions += $destPath
        }

        # Run pnpm install at the root to sync the workspace after copying extensions and shared package
        Write-Host "`n=== Synchronizing workspace (pnpm install) ===" -ForegroundColor Cyan
        Push-Location $MainRepoPath
        pnpm install
        Pop-Location

        Write-Host "`n=== Building OpenClaw China Extensions ===" -ForegroundColor Cyan
        foreach ($destPath in $copiedExtensions) {
            $extName = Split-Path $destPath -Leaf
            Write-Host "Processing extension: $extName"

            # Install and Build inside the extension directory
            if (Test-Path $destPath) {
                Push-Location $destPath
                
                if (Test-Path "package.json") {
                    Write-Host "  Installing dependencies for $extName..."
                    pnpm install
                    
                    Write-Host "  Building $extName..."
                    pnpm build
                    
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Failed to build extension: $extName"
                        Pop-Location
                        exit 1
                    }
                } else {
                    Write-Host "  No package.json found in $extName, skipping build."
                }
                
                Pop-Location
            }
        }
    }
}

# 3. 执行主构建
Write-Host "`n=== Starting Main Build ===" -ForegroundColor Cyan
if (Test-Path ".\build-windows.ps1") {
    ./build-windows.ps1
} else {
    pnpm build
}
