---
name: openclaw-backup
description: Multi-user OpenClaw backup tool for team collaboration. Each user creates their own backup script in their oneyemo directory.
---

# OpenClaw Backup Skill - 多用户独立版本

**重要：** 此 skill 采用**每个人创建独立备份脚本**的设计，避免共享配置文件的冲突问题。

## 为什么这样设计？

### 问题场景

1. **路径不同**：每个用户的 oneyemo 路径不同
   - 大师兄：`E:\Workspace\oneyoemo\`
   - 师傅：可能在 `D:\oneyoemo\` 或 `E:\oneyoemo\`
   - 小师妹：`C:\oneyoemo\`

2. **共享skill问题**：skill 在 openclaw 仓库，大家共享同一个文件，直接修改会互相干扰

3. **维护困难**：一个人改错配置会影响所有人

### 解决方案

✅ **每人独立脚本**：复制模板到自己的 oneyemo 目录后修改配置
✅ **完全独立**：互不干扰，各管各的
✅ **灵活配置**：根据自己路径调整
✅ **便于协作**：不需要协调修改共享文件

## 快速开始（三步搞定）

### 第一步：复制模板脚本到你的oneyoemo目录

在你的 oneyemo 目录下创建备份脚本文件夹并复制模板：

```powershell
# 小师妹（假设在 C:\oneyoemo）
mkdir C:\oneyoemo\backup-scripts 2>$null
# 然后复制 backup-template.ps1 到这个目录，改名为 backup-openclaw.ps1

# 师傅（假设在 E:\oneyoemo）
mkdir E:\oneyoemo\backup-scripts 2>$null
# 然后复制 backup-template.ps1 到这个目录，改名为 backup-openclaw.ps1

# 大师兄（E:\Workspace\oneyoemo）
# 已经配置好了，可以直接使用！
```

### 第二步：编辑你的备份脚本

打开刚复制的脚本，修改第 3-6 行：

```powershell
# ==================== 配置区域 ====================
# 1. OpenClaw 源目录（根据你的系统修改）
$sourceDir = "C:\Users\你的用户名\.openclaw"

# 2. 备份目标目录（你的 oneyemo 路径）
$backupDir = "C:\oneyoemo\openclaw-backup"  # 修改为你的路径
# ==================================================
```

**快速查找路径的方法：**

在 PowerShell 中运行：
```powershell
# 查看 .openclaw 位置
echo $env:USERPROFILE\.openclaw

# 或
echo ~\.openclaw
```

### 第三步：测试备份

```powershell
# 进入你的 oneyemo 目录
cd C:\oneyoemo  # 或你的路径

# 运行备份
.\backup-scripts\backup-openclaw.ps1
```

看到"备份完成！"说明配置成功！

## 详细配置指南

完整说明请查看：[MULTIUSER_GUIDE.md](MULTIUSER_GUIDE.md)

包括：
- 各种路径配置示例
- 常见问题解答
- 迁移到新电脑的步骤
- 定时自动备份设置

## 使用示例

### 日常备份

```powershell
# 在你的 oneyemo 目录下
.\backup-scripts\backup-openclaw.ps1
```

### Git 提交

每个人在自己的 oneyemo 目录提交：

```bash
cd C:\oneyoemo
git add openclaw-backup/
git commit -m "backup: OpenClaw data sync"
git push
```

### 自动备份（定时任务）

创建 Windows 计划任务：
- 程序：`powershell.exe`
- 参数：`-ExecutionPolicy Bypass -File "C:\oneyoemo\backup-scripts\backup-openclaw.ps1"`
- 触发：每天定时执行

## 目录结构示例

```
C:\oneyoemo/                    # 小师妹
├── backup-scripts/
│   └── backup-openclaw.ps1   # 她的脚本
└── openclaw-backup/           # 她的备份

E:\oneyoemo/                    # 师傅
├── backup-scripts/
│   └── backup-openclaw.ps1   # 他的脚本
└── openclaw-backup/           # 他的备份

E:\Workspace\oneyoemo/         # 大师兄
├── backup-scripts/
│   └── backup-openclaw.ps1   # 我的脚本
└── openclaw-backup/           # 我的备份
```

## 核心优势

1. **完全独立**：每个人的脚本互不干扰
2. **灵活部署**：根据自己路径配置
3. **无需协调**：各自维护自己的脚本
4. **安全可靠**：配置错误不影响其他人

## 备份内容

完整备份 OpenClaw 配置：
- `workspace/` - 身份信息、用户信息、灵魂、工具
- `agents/main/sessions/` - 对话历史
- `identity/` - 设备认证
- `cron/` - 定时任务
- `devices/` - 配对设备
- `canvas/` - Canvas 数据
- `openclaw.json` - 主配置

自动排除：
- `node_modules/` - npm 依赖
- `*.lock` - 临时文件
- `*.log` - 日志
- `*.db` - 数据库
- `extensions/` - 扩展包

## 常见问题

### Q: 如何找到我的用户名？

A: PowerShell 运行：
```powershell
echo $env:USERNAME
```

### Q: 如何确认路径配置正确？

A: 运行脚本，如果显示"源目录不存在"说明路径错了。

### Q: 可以把脚本放到其他位置吗？

A: 可以！只要正确配置 `$sourceDir` 和 `$backupDir` 即可。

### Q: 多个电脑都需要备份怎么办？

A: 每台电脑复制脚本并配置路径。

### Q: 团队如何协作？

A: 各自备份各自的目录，可以在同一个 git 仓库的不同分支或不同目录。

## 安全提醒

⚠️ **重要提示**：

- `identity/device-auth.json` 可能包含敏感 token
- 提交前检查备份内容
- 建议只备份到私有仓库

## 技巧

### 使用环境变量自动获取用户名

在脚本中使用：

```powershell
# 自动获取当前用户名
$username = $env:USERNAME
$sourceDir = "C:\Users\$username\.openclaw"
```

### 添加备份日志

在脚本最后添加：

```powershell
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"$timestamp - Backup completed" | Out-File "backup.log" -Append
```

## 更新日志

### 2026-01-31 v2.0
- 重新设计为多用户独立版本
- 每个人在自己的 oneyemo 目录创建备份脚本
- 避免共享 skill 文件的配置冲突
- 提供灵活的配置选项
- 添加详细的配置指南文档
