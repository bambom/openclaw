# build-full.ps1

$ChinaRepoPath = "C:\Workspace\openclaw-china"
$MainRepoPath = "C:\Workspace\openclaw"

function Sync-Repo ($Path) {
    if (-not (Test-Path $Path)) { return }
    Write-Host "Syncing $Path"
    Push-Location $Path
    try {
        # Auto-commit local changes if any
        if (git status --porcelain) {
            Write-Host "  -> Committing local changes..."
            git add .
            git commit -m "Auto-commit before sync"
        }

        $remotes = git remote
        if ($remotes -contains "upstream") {
            git fetch upstream
            git rebase upstream/main
            git push origin main --force-with-lease
        } else {
            git pull
        }
    } catch {
        Write-Host "Git sync failed for $Path"
    }
    Pop-Location
}

# 1. Sync
Sync-Repo $MainRepoPath
Sync-Repo $ChinaRepoPath

# 2. Copy and Transform
if (Test-Path $ChinaRepoPath) {
    Write-Host "Integrating Extensions..."
    
    $tasks = @(
        @{ S = "packages\shared"; D = "packages\openclaw-china-shared" },
        @{ S = "extensions\dingtalk"; D = "extensions\dingtalk" },
        @{ S = "extensions\feishu"; D = "extensions\feishu" },
        @{ S = "extensions\wecom"; D = "extensions\wecom" }
    )

    foreach ($t in $tasks) {
        $src = Join-Path $ChinaRepoPath $t.S
        $dst = Join-Path $MainRepoPath $t.D

        if (Test-Path $src) {
            Write-Host "Copying $src to $dst"
            if (Test-Path $dst) { Remove-Item -Path $dst -Recurse -Force }
            
            $parent = Split-Path $dst
            if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
            
            Copy-Item -Path $src -Destination $dst -Recurse -Force

            $pkg = Join-Path $dst "package.json"
            if (Test-Path $pkg) {
                Write-Host "Updating $pkg"
                $enc = New-Object System.Text.UTF8Encoding($false)
                $txt = [IO.File]::ReadAllText($pkg, $enc)
                $txt = $txt -replace '"@openclaw-china/shared":\s*".*?"', '"@openclaw-china/shared": "workspace:*"'
                $txt = $txt -replace '"openclaw":\s*".*?"', '"openclaw": "workspace:*"'
                [IO.File]::WriteAllText($pkg, $txt, $enc)
            }
        }
    }
}

# 3. TSConfig
$tsbase = Join-Path $ChinaRepoPath "tsconfig.base.json"
if (Test-Path $tsbase) { Copy-Item -Path $tsbase -Destination (Join-Path $MainRepoPath "tsconfig.base.json") -Force }

# 4. Build
Write-Host "Starting Build..."
Push-Location $MainRepoPath
if (Test-Path ".\build-windows.ps1") {
    .\build-windows.ps1
} else {
    pnpm install
    pnpm build
}
Pop-Location