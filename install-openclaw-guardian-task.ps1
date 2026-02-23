<#
Install a Windows Scheduled Task to run OpenClaw Guardian on user logon.

Run in PowerShell (preferably as the same user who runs OpenClaw):
  cd E:\Workspace\openclaw
  powershell -ExecutionPolicy Bypass -File .\install-openclaw-guardian-task.ps1

Uninstall:
  powershell -ExecutionPolicy Bypass -File .\install-openclaw-guardian-task.ps1 -Uninstall
#>

[CmdletBinding()]
param(
  [string]$TaskName = "OpenClaw Guardian",
  [string]$RepoDir  = "E:\Workspace\openclaw",
  [string]$GuardianScript = "E:\Workspace\openclaw\openclaw-guardian.ps1",
  [switch]$Uninstall
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Log([string]$msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Write-Host "[$ts] $msg"
}

if ($Uninstall) {
  if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Log "Uninstalled scheduled task: $TaskName"
  } else {
    Write-Log "Task not found: $TaskName"
  }
  exit 0
}

if (-not (Test-Path $GuardianScript)) {
  throw "Guardian script not found at: $GuardianScript"
}

# Action: run guardian in the correct repo dir
$psArgs = @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", "`"$GuardianScript`"",
  "-RepoDir", "`"$RepoDir`"",
  "-VerboseLogs"
)

$action  = New-ScheduledTaskAction -Execute "powershell.exe" -Argument ($psArgs -join ' ')
$trigger = New-ScheduledTaskTrigger -AtLogOn

# Run as current user, elevated (highest). This uses the current logon token (no password prompt).
$principal = New-ScheduledTaskPrincipal -UserId "$env:UserDomain\\$env:UserName" -LogonType Interactive -RunLevel Limited

# Settings: keep it running, restart on failure.
$settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -MultipleInstances IgnoreNew `
  -RestartCount 999 `
  -RestartInterval (New-TimeSpan -Minutes 1) `
  -ExecutionTimeLimit (New-TimeSpan -Days 3650)

$task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings

Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null
Write-Log "Installed scheduled task: $TaskName"
Write-Log "It will start on next logon. You can also run it now from Task Scheduler."