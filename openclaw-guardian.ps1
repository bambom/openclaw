<#
OpenClaw Guardian (Windows / PowerShell)

Goal:
- Run `pnpm openclaw gateway run` under supervision.
- If the gateway becomes unhealthy or exits, restart it.
- If a config change appears to have broken the gateway, automatically roll back to the last-known-good config.

Typical usage (in E:\Workspace\openclaw):
  powershell -ExecutionPolicy Bypass -File .\openclaw-guardian.ps1

Notes:
- This assumes your config lives at %USERPROFILE%\.openclaw\openclaw.json.
- Guardian keeps state + backups under %USERPROFILE%\.openclaw\guardian\
#>

[CmdletBinding()]
param(
  [string]$RepoDir = "E:\Workspace\openclaw",
  [string]$ConfigPath = "$env:USERPROFILE\.openclaw\openclaw.json",
  [string]$StateDir = "$env:USERPROFILE\.openclaw\guardian",
  [string]$EnvPath = "E:\Workspace\openclaw\.env",
  [int]$CheckEverySeconds = 10,
  [int]$HealthTimeoutSeconds = 30,
  [int]$MaxConsecutiveHealthFailures = 5,
  [int]$ConfigSettleSeconds = 60,
  [int]$PendingGraceSeconds = 90,
  [switch]$VerboseLogs
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log([string]$msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts] $msg"
}

function Ensure-Dir([string]$p) {
  if (-not (Test-Path $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null }
}

function Get-FileHashHex([string]$p) {
  if (-not (Test-Path $p)) { return $null }
  return (Get-FileHash -Algorithm SHA256 -Path $p).Hash.ToLowerInvariant()
}

function Copy-Safe([string]$src, [string]$dst) {
  Ensure-Dir (Split-Path -Parent $dst)
  Copy-Item -Force -Path $src -Destination $dst
}

function Read-State([string]$path) {
  if (-not (Test-Path $path)) { return $null }
  try {
    return Get-Content -Raw -Path $path | ConvertFrom-Json
  } catch {
    return $null
  }
}

function Write-State([string]$path, $obj) {
  Ensure-Dir (Split-Path -Parent $path)
  ($obj | ConvertTo-Json -Depth 10) | Set-Content -Encoding UTF8 -Path $path
}

function Validate-Json([string]$path) {
  try {
    Get-Content -Raw -Path $path | ConvertFrom-Json | Out-Null
    return $true
  } catch {
    return $false
  }
}

function Run-HealthCheck() {
  # Use `pnpm openclaw gateway health` as the liveness probe.
  # Return $true if command succeeds.
  try {
    $tmpOut = Join-Path "$StateDir\logs" "health.out.tmp"
    $tmpErr = Join-Path "$StateDir\logs" "health.err.tmp"

    $p = Start-Process -FilePath "pnpm" -WorkingDirectory $RepoDir -ArgumentList @("openclaw","gateway","health") -PassThru -WindowStyle Hidden -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr

    if (-not $p.WaitForExit($HealthTimeoutSeconds * 1000)) {
      try { Stop-Process -Id $p.Id -Force } catch {}
      return $false
    }

    return ($p.ExitCode -eq 0)
  } catch {
    return $false
  }
}

function Set-EnvFromDotEnv([string]$path) {
  if (-not (Test-Path $path)) {
    if ($VerboseLogs) { Write-Log "No .env found at $path (skip env load)." }
    return
  }

  $lines = Get-Content -Path $path -ErrorAction SilentlyContinue
  foreach ($line in $lines) {
    $t = ($line ?? "").Trim()
    if ($t.Length -eq 0) { continue }
    if ($t.StartsWith('#')) { continue }

    # KEY=VALUE (no export)
    $idx = $t.IndexOf('=')
    if ($idx -le 0) { continue }

    $key = $t.Substring(0, $idx).Trim()
    $val = $t.Substring($idx + 1)

    # Strip surrounding quotes
    if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
      $val = $val.Substring(1, $val.Length - 2)
    }

    if ($key.Length -gt 0) {
      $env:$key = $val
    }
  }

  if ($VerboseLogs) {
    Write-Log "Loaded env from .env: $path"
  }
}

function Start-Gateway() {
  Ensure-Dir "$StateDir\logs"
  $outLog = "$StateDir\logs\gateway.out.log"
  $errLog = "$StateDir\logs\gateway.err.log"

  # Ensure the child gateway inherits latest .env values (NO_PROXY, proxies, etc.)
  Set-EnvFromDotEnv $EnvPath

  if ($VerboseLogs) {
    Write-Log "Starting gateway: pnpm openclaw gateway run --force (workdir=$RepoDir)"
  }

  $p = Start-Process -FilePath "pnpm" -WorkingDirectory $RepoDir -ArgumentList @("openclaw","gateway","run","--force") -PassThru -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
  return $p
}

function Stop-Gateway([System.Diagnostics.Process]$p) {
  if ($null -eq $p) { return }
  try {
    if (-not $p.HasExited) {
      if ($VerboseLogs) { Write-Log "Stopping gateway PID=$($p.Id)" }
      Stop-Process -Id $p.Id -Force
    }
  } catch {}
}

# --- init ---
Ensure-Dir $StateDir
Ensure-Dir "$StateDir\backups"

$statePath = "$StateDir\state.json"
$state = Read-State $statePath
if ($null -eq $state) {
  $state = [pscustomobject]@{
    lastGoodHash = $null
    lastGoodPath = "$StateDir\\backups\\openclaw.last-good.json"
    pendingHash  = $null
    pendingSince = $null
    consecutiveHealthFailures = 0
  }
}

if (-not (Test-Path $ConfigPath)) {
  throw "Config not found at: $ConfigPath"
}

if (-not (Validate-Json $ConfigPath)) {
  Write-Log "WARN: Current config is not valid JSON. Attempting rollback if last-good exists."
  if (Test-Path $state.lastGoodPath) {
    Copy-Safe $state.lastGoodPath $ConfigPath
    Write-Log "Rolled back config to last-good (JSON-valid)."
  } else {
    throw "No last-good backup exists; cannot rollback."
  }
}

# Ensure we have an initial last-good snapshot.
$currentHash = Get-FileHashHex $ConfigPath
if (-not (Test-Path $state.lastGoodPath)) {
  Copy-Safe $ConfigPath $state.lastGoodPath
  $state.lastGoodHash = $currentHash
  Write-Log "Initialized last-good snapshot: $($state.lastGoodPath)"
}

Write-State $statePath $state

# Start gateway under supervision
$gateway = Start-Gateway
Start-Sleep -Seconds 2

Write-Log "Guardian running. Config=$ConfigPath  State=$StateDir"

# --- main loop ---
while ($true) {
  try {
    # Detect config change
    $newHash = Get-FileHashHex $ConfigPath
    if ($newHash -and ($newHash -ne $currentHash)) {
      $currentHash = $newHash
      $state.pendingHash = $newHash
      $state.pendingSince = (Get-Date).ToString("o")
      $state.consecutiveHealthFailures = 0

      if (-not (Validate-Json $ConfigPath)) {
        Write-Log "Config changed but JSON invalid → immediate rollback to last-good."
        Copy-Safe $state.lastGoodPath $ConfigPath
        $currentHash = Get-FileHashHex $ConfigPath
        $state.pendingHash = $null
        $state.pendingSince = $null
        Stop-Gateway $gateway
        $gateway = Start-Gateway
      } else {
        Write-Log "Config changed (hash=$newHash). Marking as pending until healthy for ${ConfigSettleSeconds}s."
      }
      Write-State $statePath $state
    }

    # If gateway exited, restart (and consider rollback if it happened right after a config change)
    if ($gateway.HasExited) {
      Write-Log "Gateway process exited (code=$($gateway.ExitCode)). Restarting."
      $state.consecutiveHealthFailures++

      if ($state.pendingHash -and ($state.pendingHash -eq $currentHash) -and ($state.consecutiveHealthFailures -ge $MaxConsecutiveHealthFailures)) {
        Write-Log "Exit happened after a pending config change and failures reached threshold → rollback."
        Copy-Safe $state.lastGoodPath $ConfigPath
        $currentHash = Get-FileHashHex $ConfigPath
        $state.pendingHash = $null
        $state.pendingSince = $null
      }

      $gateway = Start-Gateway
      Write-State $statePath $state
      Start-Sleep -Seconds $CheckEverySeconds
      continue
    }

    # Health check
    $ok = Run-HealthCheck

    # If we just changed config, allow a grace window for restarts/reconnects
    $pendingAge = $null
    if ($state.pendingHash -and $state.pendingSince) {
      try {
        $since = [DateTime]::Parse($state.pendingSince)
        $pendingAge = (New-TimeSpan -Start $since -End (Get-Date)).TotalSeconds
      } catch {}
    }

    if ($ok) {
      if ($state.consecutiveHealthFailures -gt 0 -and $VerboseLogs) {
        Write-Log "Health OK again; resetting failure counter."
      }
      $state.consecutiveHealthFailures = 0

      # If config is pending and it has stayed healthy long enough, promote to last-good
      if ($state.pendingHash -and ($state.pendingHash -eq $currentHash) -and $state.pendingSince) {
        $since = [DateTime]::Parse($state.pendingSince)
        $age = (New-TimeSpan -Start $since -End (Get-Date)).TotalSeconds
        if ($age -ge $ConfigSettleSeconds) {
          Copy-Safe $ConfigPath $state.lastGoodPath
          $state.lastGoodHash = $currentHash
          $state.pendingHash = $null
          $state.pendingSince = $null
          Write-Log "Promoted current config to last-good (healthy for ${ConfigSettleSeconds}s)."
        }
      }

    } else {
      if ($pendingAge -ne $null -and $pendingAge -lt $PendingGraceSeconds) {
        if ($VerboseLogs) {
          Write-Log "Health FAIL during pending grace window (${pendingAge}s < ${PendingGraceSeconds}s) → ignore." 
        }
      } else {
        $state.consecutiveHealthFailures++
        Write-Log "Health FAIL ($($state.consecutiveHealthFailures)/$MaxConsecutiveHealthFailures)."

        if ($state.consecutiveHealthFailures -ge $MaxConsecutiveHealthFailures) {
          Write-Log "Health failures reached threshold. Restarting gateway."

          # If failures likely due to the most recent config, rollback.
          if ($state.pendingHash -and ($state.pendingHash -eq $currentHash)) {
            Write-Log "Pending config seems bad → rollback to last-good."
            Copy-Safe $state.lastGoodPath $ConfigPath
            $currentHash = Get-FileHashHex $ConfigPath
            $state.pendingHash = $null
            $state.pendingSince = $null
          }

          Stop-Gateway $gateway
          Start-Sleep -Seconds 1
          $gateway = Start-Gateway
          $state.consecutiveHealthFailures = 0
        }
      }
    }

    Write-State $statePath $state
    Start-Sleep -Seconds $CheckEverySeconds

  } catch {
    Write-Log "Guardian error: $($_.Exception.Message)"
    Start-Sleep -Seconds $CheckEverySeconds
  }
}
