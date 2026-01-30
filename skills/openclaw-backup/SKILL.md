---
name: openclaw-backup
description: Multi-user OpenClaw backup tool for team collaboration. Each user creates their own backup script in their oneyomo directory.
---

# OpenClaw Backup Skill - 多用户独立版本

**重要：** 此 skill 采用**每个人创建独立备份脚本**的设计，避免共享配置文件的冲突问题。

## 快速开始（三步搞定）

### 第一步：了解团队协作规则

**重要：** oneyemo 是**公共仓库**，每个成员有独立的工作区！

完整协作规则请查看：[README-oneyoemo.md](README-oneyoemo.md)

### 第二步：复制模板脚本到oneyoemo公共目录

```powershell
# 在 oneyemo 根目录下创建备份脚本文件夹
mkdir E:\oneyoemo\backup-scripts 2>$null

# 复制模板脚本到这个目录
# （从 skills/openclaw-backup/ 复制 backup-template.ps1 并改名为 backup-openclaw.ps1）
```

### 第三步：编辑你的备份脚本

打开刚复制的脚本，修改配置：

```powershell
# ==================== 配置区域 ====================
# 1. OpenClaw 源目录（根据你的系统修改）
$sourceDir = "C:\Users\你的用户名\.openclaw"

# 2. 备份目标目录（相对路径，指向你的工作区）
# 大师兄: ..\dashixiong-workspace\openclaw-backup
# 师傅: ..\shifu-workspace\openclaw-backup
# 小师妹: ..\xiaomeimei-workspace\openclaw-backup
$backupDir = "..\dashixiong-workspace\openclaw-backup"
# ==================================================
```

**配置示例：**

**大师兄（E:\Workspace\oneyoemo）：**
```powershell
$sourceDir = "C:\Users\bambo\.openclaw"
$backupDir = "..\dashixiong-workspace\openclaw-backup"
```

**师傅（假设在 E:\oneyoemo）：**
```powershell
$sourceDir = "C:\Users\shifu\.openclaw"
$backupDir = "..\shifu-workspace\openclaw-backup"
```

**小师妹（假设在 C:\oneyoemo）：**
```powershell
$sourceDir = "C:\Users\xiaomeimei\.openclaw"
$backupDir = "..\xiaomeimei-workspace\openclaw-backup"
```

## 仓库结构

```
oneyoemo/                          # 公共仓库
├── README-oneyoemo.md            # 团队协作指南（必读！）
├── skills/openclaw-backup/
│   ├── SKILL.md                  # 本文件
│   ├── backup-template.ps1       # 备份脚本模板
│   └── README.md               # 详细使用指南
├── dashixiong-workspace/         # 大师兄的工作区
│   ├── (大师兄的项目文件)
│   ├── (其他工作内容)
│   └── openclaw-backup/       # 大师兄的备份
├── shifu-workspace/             # 师傅的工作区
│   ├── (师傅的项目文件)
│   ├── (其他工作内容)
│   └── openclaw-backup/       # 师傅的备份
└── xiaomeimei-workspace/         # 小师妹的工作区
    ├── (小师妹的项目文件)
    ├── (其他工作内容)
    └── openclaw-backup/       # 小师妹的备份
```

## 使用流程

### 日常备份

```powershell
# 在你的本地 oneyomo 目录下
cd E:\oneyoemo  # 或 C:\oneyoemo 等

# 运行备份
.\backup-scripts\backup-openclaw.ps1
```

### Git 提交

每个人在自己的工作区提交：

```bash
cd E:\oneyoemo  # 或你的本地路径

# 大师兄提交
git add dashixiong-workspace/openclaw-backup/
git commit -m "backup: OpenClaw data sync"

# 师傅提交
git add shifu-workspace/openclaw-backup/
git commit -m "backup: OpenClaw data sync"

# 小师妹提交
git add xiaomeimei-workspace/openclaw-backup/
git commit -m "backup: OpenClaw data sync"

# 推送到远程
git push
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

## 快速查找路径

### 查找 .openclaw

```powershell
echo $env:USERPROFILE\.openclaw
# 或
echo ~\.openclaw
```

### 查找用户名

```powershell
echo $env:USERNAME
```

## 常见问题

### Q: 如何找到我的 oneyomo 路径？

A: 
1. 克隆 oneyomo 仓库后，查看本地位置
2. 可以是 `E:\oneyoemo`、`C:\oneyoemo` 等
3. 不确定时问团队成员

### Q: 不确定自己的工作区怎么办？

A: 在 oneyomo 根目录下查看 `*-workspace` 文件夹：
- `dashixiong-workspace/` - 大师兄
- `shifu-workspace/` - 师傅
- `xiaomeimei-workspace/` - 小师妹

### Q: 可以把脚本放到其他位置吗？

A: 可以！只要正确配置相对路径即可。脚本可以放在任何位置。

### Q: 多个电脑都需要备份怎么办？

A: 在每台电脑上：
1. 克隆 oneyemo 仓库
2. 复制备份脚本到本地 oneyemo/backup-scripts/
3. 配置为自己的路径

### Q: 团队如何协作？

A: 
1. 每个人只修改自己的工作区
2. 重要更新在团队群沟通
3. 定期同步代码到远程仓库

## 自动备份（可选）

创建 Windows 计划任务：
- 程序：`powershell.exe`
- 参数：`-ExecutionPolicy Bypass -File "E:\oneyoemo\backup-scripts\backup-openclaw.ps1"`
- 触发：每天定时执行

## 迁移到新电脑

1. **克隆 oneyemo 仓库**到新电脑
2. **复制备份脚本**到 `oneyoemo/backup-scripts/`
3. **配置路径**为新的用户名和系统路径
4. **恢复备份**：
   ```powershell
   Copy-Item -Recurse "你的工作区\openclaw-backup\*" "~\.openclaw"
   ```

## 安全提醒

⚠️ **重要提示**：

- `identity/device-auth.json` 可能包含敏感 token
- 提交前检查备份内容
- 建议只备份到私有仓库

## 更新日志

### 2026-01-31 v3.0
- 重新设计为公共仓库模式
- 每个成员有独立工作区
- 备份脚本在公共位置 oneyemo/backup-scripts/
- 添加团队协作指南 README-oneyoemo.md
