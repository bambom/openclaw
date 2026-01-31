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
