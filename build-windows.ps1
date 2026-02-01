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
pnpm exec tsc -p tsconfig.json --noEmit false
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
node --import tsx scripts/canvas-a2ui-copy.ts
node --import tsx scripts/copy-hook-metadata.ts
node --import tsx scripts/write-build-info.ts

# 5. Build UI
Write-Host "`n[5/5] Building UI..."
pnpm ui:build

Write-Host "`nBuild Complete!" -ForegroundColor Green
