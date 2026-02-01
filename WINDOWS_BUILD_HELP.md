# OpenClaw Windows 构建指南与故障排除

## 问题描述

在 Windows 环境下直接运行 `pnpm build` 可能会失败。主要原因是构建脚本中包含了 `scripts/bundle-a2ui.sh`，这是一个 Bash 脚本。在 Windows 上，系统可能会尝试使用 WSL (Windows Subsystem for Linux) 来执行此脚本。如果 WSL 环境中未正确安装或配置 Node.js，会导致 `node: command not found` 错误。

此外，部分子项目（如 `@a2ui/lit`）的构建脚本使用了 Unix 风格的命令（如 `mkdir -p`, `cp`），在 Windows PowerShell 中无法直接运行。

## 解决方案：手动分步构建

为了绕过上述问题，请按照以下步骤在 PowerShell 中手动执行构建流程。

### 1. 安装依赖

首先确保根目录依赖已更新：

```powershell
pnpm install
```

### 2. 构建 A2UI Renderer

这一步通常由 `wireit` 管理，但我们需要手动处理文件复制和编译。

```powershell
# 进入 renderer 目录
cd vendor/a2ui/renderers/lit

# 安装依赖
pnpm install

# 手动执行 copy-spec 任务 (PowerShell)
New-Item -ItemType Directory -Force -Path src/0.8/schemas
Copy-Item ../../specification/0.8/json/*.json src/0.8/schemas/ -Force

# 编译 TypeScript
pnpm exec tsc -b --pretty

# 返回根目录
cd ../../../../
```

### 3. 打包 CanvasA2UI

手动触发 `rolldown` 打包，指定配置文件路径。

```powershell
pnpm exec rolldown -c apps/shared/OpenClawKit/Tools/CanvasA2UI/rolldown.config.mjs
```

### 4. 编译核心代码与后续处理

执行 TypeScript 编译及必要的元数据处理脚本。

```powershell
# 编译核心代码
pnpm exec tsc -p tsconfig.json

# 运行后续构建脚本
node --import tsx scripts/canvas-a2ui-copy.ts
node --import tsx scripts/copy-hook-metadata.ts
node --import tsx scripts/write-build-info.ts
```

### 5. 构建 UI

最后构建 Web 控制台 UI。

```powershell
pnpm ui:build
```

---

## 自动化 PowerShell 脚本 (推荐)

你可以将以下内容保存为 `build-windows.ps1`，下次直接运行此脚本即可完成构建：

```powershell
Write-Host "Starting OpenClaw Build for Windows..." -ForegroundColor Green

# 1. Install Dependencies
Write-Host "`n[1/5] Installing dependencies..."
pnpm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 2. Build A2UI Renderer
Write-Host "`n[2/5] Building A2UI Renderer..."
Push-Location vendor/a2ui/renderers/lit
pnpm install
if (-not (Test-Path "src/0.8/schemas")) {
    New-Item -ItemType Directory -Force -Path "src/0.8/schemas" | Out-Null
}
Copy-Item "../../specification/0.8/json/*.json" "src/0.8/schemas/" -Force
pnpm exec tsc -b --pretty
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
Pop-Location

# 3. Bundle CanvasA2UI
Write-Host "`n[3/5] Bundling CanvasA2UI..."
pnpm exec rolldown -c apps/shared/OpenClawKit/Tools/CanvasA2UI/rolldown.config.mjs
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# 4. Build Core & Scripts
Write-Host "`n[4/5] Building Core & Running Scripts..."
pnpm exec tsc -p tsconfig.json
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node --import tsx scripts/canvas-a2ui-copy.ts
node --import tsx scripts/copy-hook-metadata.ts
node --import tsx scripts/write-build-info.ts

# 5. Build UI
Write-Host "`n[5/5] Building UI..."
pnpm ui:build

Write-Host "`nBuild Complete!" -ForegroundColor Green
```

## 集成 OpenClaw China (高级配置)

如果你需要同时开发或使用 `openclaw-china` 扩展，并希望每次构建时自动同步上游代码，可以使用以下的高级构建流程。

### 目录结构假设

本指南假设你的目录结构如下（平级目录）：
- `C:\Workspace\openclaw` (当前项目)
- `C:\Workspace\openclaw-china` (中国区插件项目)

### 自动化同步与构建脚本 (build-full.ps1)

你可以创建一个名为 `build-full.ps1` 的新脚本，它会自动执行：**Git 同步 -> 编译插件库 -> 链接插件 -> 编译主程序**。

```powershell
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
        $remotes = git remote
        if ($remotes -contains "upstream") {
            Write-Host "Fetching and Rebasing from upstream..."
            git fetch upstream
            # 使用 rebase 保持线性历史，不产生 merge commit
            git rebase upstream/main
            
            # 同步更新到自己的 fork 仓库 (origin)
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
```

### 4. 启用中国区插件

构建完成后，你需要手动启用这些插件。在 `openclaw` 根目录下运行：

```bash
# 1. 启用统一渠道插件入口
openclaw config set plugins.entries.channels '{ "enabled": true }' --json

# 2. 配置并启用具体的渠道（以钉钉为例）
openclaw config set channels.dingtalk '{
  "enabled": true,
  "clientId": "your-client-id",
  "clientSecret": "your-client-secret",
  "enableAICard": true
}' --json
```

### 提示
- **线性历史**: 脚本使用 `git rebase` 而不是 `git merge`，这会确保你的 Fork 仓库保持与官方源库完全一致的线性提交记录，不会产生额外的 "Merge branch" 提交。
- **首次设置 upstream**: 请确保在两个仓库目录下分别运行过以下命令：
  - `openclaw`: `git remote add upstream https://github.com/openclaw/openclaw.git`
  - `openclaw-china`: `git remote add upstream https://github.com/BytePioneer-AI/moltbot-china.git`