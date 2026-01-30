---
name: openclaw-backup
description: OpenClaw data backup and migration tool for easy team collaboration. Supports backing up .openclaw directory to a shared git repository with multiple team members.
---

# OpenClaw Backup Skill

This skill provides a complete backup solution for OpenClaw data, enabling team members (大师兄、师傅、小师妹) to backup their OpenClaw instances to a shared repository.

## Quick Start

### 1. Configure Your Backup Path

**推荐使用简化版脚本** (`backup-openclaw-simple.ps1`)，更稳定可靠。

编辑备份脚本：

```powershell
# Edit scripts/backup-openclaw-simple.ps1
# Line 4: Change to your personal backup folder
$backupDir = "E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup"
```

**可选配置项：**

| 用户 | 备份目录 |
|------|---------|
| 大师兄（李剑辛） | `E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup` |
| 师傅 | `E:\Workspace\oneyoemo\shifu-workspace\openclaw-backup` |
| 小师妹 | `E:\Workspace\oneyoemo\shimei-workspace\openclaw-backup` |

### 2. Run Backup

```powershell
powershell -ExecutionPolicy Bypass -File "scripts/backup-openclaw-simple.ps1"
```

### 3. Commit to Git

```bash
cd E:\Workspace\oneyoemo
git add (你的备份目录)/
git commit -m "backup: OpenClaw data sync"
git push
```

## Multi-User Setup

Each team member uses the **same git repository** but **different backup folders**:

```
oneyoemo/
├── dashixiong-workspace/     # 大师兄的备份
│   └── openclaw-backup/
├── shifu-workspace/           # 师傅的备份
│   └── openclaw-backup/
└── shimei-workspace/           # 小师妹的备份
    └── openclaw-backup/
```

## Migration to New Computer

When switching computers:

1. Install OpenClaw on new computer
2. Clone the shared repository
3. Copy your backup folder to `.openclaw`:
   ```powershell
   Copy-Item -Recurse "dashixiong-workspace\openclaw-backup\*" "~\.openclaw"
   ```
4. Restore dependencies if needed:
   ```powershell
   cd ~/.openclaw/extensions
   npm install
   ```

## What Gets Backed Up

The backup includes your entire OpenClaw configuration:
- `workspace/` - Identity, user info, soul, tools, heartbeat
- `agents/main/sessions/` - Conversation history
- `identity/` - Device authentication
- `cron/` - Scheduled tasks
- `devices/` - Paired devices
- `canvas/` - Canvas data
- `openclaw.json` - Main configuration

## Excluded Files

The following are excluded to reduce backup size:
- `node_modules/` - npm dependencies (can be restored via `npm install`)
- `*.lock` - Temporary lock files
- `*.log` - Log files
- `*.db`, `*.sqlite` - Database files
- `*.tmp`, `*.temp` - Temporary files
- `extensions/` - Extension packages (can be reinstalled)

## Security Notes

- `identity/device-auth.json` and `credentials/` may contain sensitive tokens
- Backup only to private repositories
- Consider encrypting sensitive files before committing

## Advanced Configuration

### Custom Exclusions

Edit the `.gitignore` in your backup folder to add custom exclusions:
```
# Add your custom exclusions here
my-sensitive-file.json
```

### Scheduled Backups

Set up Windows Task Scheduler to run backup automatically:
1. Open Task Scheduler
2. Create Basic Task
3. Trigger: Daily at preferred time
4. Action: Start program
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "E:\Workspace\openclaw\skills\openclaw-backup\scripts\backup-openclaw.ps1"`
