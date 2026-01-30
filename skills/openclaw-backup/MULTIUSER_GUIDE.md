# OpenClaw Backup - 详细配置指南

## 团队协作说明

oneyoemo 是团队公共仓库，每个成员有独立的工作区！

完整协作规则请查看：[README.md](../../../README.md)

### 仓库结构

```
oneyoemo/                          # 公共仓库
├── README.md                         # 团队协作指南
├── docs/                            # 共享文档
│   ├── MEETINGS.md                 # 会议记录
│   ├── OPERATIONS.md               # 运营计划
│   ├── PROJECT_PLAN.md             # 项目规划
│   └── TASK_SCHEDULE.md            # 任务计划
├── skills/openclaw-backup/          # OpenClaw 备份工具
└── dashixiong-workspace/             # 大师兄的工作区
    ├── (项目文件)
    ├── (运营素材)
    ├── (工具脚本)
    └── openclaw-backup/          # 大师兄的备份
```

### 工作区说明

每个成员的工作区可以包含：
- 项目相关文件
- 开发代码
- 素材资源
- 文档和笔记
- 工具和脚本
- **openclaw-backup/** - OpenClaw 完整备份目录**

## 配置流程

### 第一步：复制备份脚本模板到oneyoemo公共目录

在本地克隆的 oneyomo 目录下创建备份脚本文件夹：

```powershell
# 在 oneyomo 根目录下
mkdir backup-scripts 2>$null

# 复制技能中的模板脚本到这个目录
# (需要从 skills/openclaw-backup/ 复制 backup-template.ps1 并改名为 backup-openclaw.ps1)
```

### 第二步：编辑你的备份脚本

打开刚复制的脚本，修改第 3-6 行的配置：

```powershell
# ==================== 配置区域 ====================
# 1. OpenClaw 源目录（根据你的系统修改）
$sourceDir = "C:\Users\你的用户名\.openclaw"

# 2. 备份目标目录（相对路径，从 oneyemo 根目录开始）
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
$backupDir = "C:\oneyoemo\shifu-workspace\openclaw-backup"
```

### 第三步：将脚本移动到你的工作区

```powershell
# 将脚本移动到你的工作区
Move-Item "backup-scripts\backup-openclaw.ps1" "..\dashixiong-workspace\"
```

这样备份脚本就在你的工作区内，方便管理！

### 第四步：运行备份

```powershell
# 进入你的工作区
cd ..\dashixiong-workspace

# 运行备份
.\backup-openclaw.ps1
```

## 使用说明

### 日常备份

在工作区内运行备份脚本：
```powershell
# 在 dashixiong-workspace/ 目录下
.\backup-openclaw.ps1
```

### Git 提交

每个人在自己的工作区提交：

```bash
cd E:\oneyoemo  # 或你的本地路径

# 大师兄提交
git add dashixiong-workspace/openclaw-backup/
git commit -m "backup: OpenClaw data sync"

# 推送
git push
```

### 自动备份（定时任务）

创建 Windows 任务计划程序：
- 程序：`powershell.exe`
- 参数：`-ExecutionPolicy Bypass -File "E:\oneyoemo\dashixiong-workspace\backup-openclaw.ps1"`
- 触发器：每天定时执行

## 常见问题

### Q: 如何找到我的 .openclaw 目录？

A: PowerShell 运行：
```powershell
echo $env:USERPROFILE\.openclaw

# 或
echo ~\.openclaw

# 或
dir $env:USERPROFILE\.openclaw
```

### Q: 如何找到我的 oneyemo 目录？

A: 克隆仓库后查看本地路径：
```bash
pwd
```

可能在：
- `E:\oneyoemo\`
- `C:\oneyoemo\`
- `D:\oneyoemo\`
- 或其他盘

### Q: 不确定自己的 oneyemo 路径怎么办？

A: 
1. 在 oneyomo 目录中运行 `git remote -v` 查看远程仓库
2. 查看路径确认是否正确
3. 在团队群里询问其他成员

### Q: 如何确认备份成功？

A: 运行备份脚本后会显示：
- "备份完成！"
- 备份文件数
- 下一步操作指引

### Q: 可以修改其他人的工作区吗？

A: 不建议！除非对方明确要求，否则只修改自己的内容。

### Q: 如何恢复特定版本的备份？

A: 使用 Git 回退：
```bash
# 查看历史
git log --oneline

# 恢复到某个版本
git checkout <commit-hash> -- (工作区)/
```

### Q: 如何创建自己的工作区？

A: 在 oneyemo 根目录下：
```bash
# 大师兄工作区已存在
# 师傅创建
mkdir shifu-workspace

# 小师妹创建
mkdir xiaomeimei-workspace
```

## 高级技巧

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
# 记录备份时间
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"$timestamp - Backup completed" | Out-File "backup.log" -Append
```

### 监控备份文件变化

定期检查备份目录大小：
```powershell
# 查看备份目录大小
$backupSize = (Get-ChildItem "..\dashixiong-workspace\openclaw-backup" -Recurse -File | Measure-Object -Property Length).Sum
Write-Host "Backup size: $([math]::Round($backupSize / 1MB, 2)) MB"
```

## 工作区管理最佳实践

1. **保持目录整洁**
   - 定期清理临时文件
   - 使用有意义的文件夹命名
   - 避免过深的嵌套

2. **使用 .gitignore**
   - 在每个工作区创建 .gitignore
   - 忽略构建输出、缓存、临时文件

3. **定期同步**
   - 每天至少提交一次
   - 重要节点及时推送
   - 查看状态确认没有遗漏

4. **分支开发**
   - 新功能使用新分支
   - 测试通过后再合并到主分支
   - 使用清晰的分支名

5. **文档维护**
   - 重要决策更新到 docs/
   - 会议记录完整
   - 计划和任务同步

## 备份内容说明

完整备份 OpenClaw 配置：

### 备份的目录

- `workspace/` - 身份信息、用户信息、灵魂、工具
- `agents/main/sessions/` - 对话历史
- `identity/` - 设备认证
- `cron/` - 定时任务
- `devices/` - 配对设备
- `canvas/` - Canvas 相关数据
- `openclaw.json` - 主配置文件

### 排除的文件

自动排除以减小备份体积：

- `node_modules/` - npm 依赖（可通过 `npm install` 恢复）
- `*.lock` - 临时锁定文件
- `*.log` - 日志文件
- `*.db`、`*.sqlite` - 数据库文件
- `*.tmp`、`*.temp` - 临时文件
- `extensions/` - 扩展包（可重新安装）

## 迁移到新电脑

### 简单三步

1. **克隆 oneyemo 仓库**到新电脑
2. **复制你的工作区**（包含备份脚本）到新电脑
3. **配置路径**（如果用户名或系统不同）
4. **恢复备份**：
   ```powershell
   # 将备份目录的内容复制到 .openclaw
   Copy-Item -Recurse "你的工作区\openclaw-backup\*" "~\.openclaw"
   ```

### 恢复依赖（如果需要）

```powershell
cd ~/.openclaw/extensions
npm install
```

## 团队协作提示

- **沟通及时**：遇到问题在团队群里沟通
- **定期同步**：重要更新及时推送代码
- **互相帮助**：成员遇到困难时互相支持
- **文档维护**：重要决策及时更新到 docs/
- **备份习惯**：每天备份一次 OpenClaw 数据

## 技巧

### 快速查看 .openclaw 位置

```powershell
# 方法 1
echo $env:USERPROFILE\.openclaw

# 方法 2
echo ~\.openclaw

# 方法 3
dir $env:USERPROFILE\.openclaw
```

### 批处理修改用户名

如果不确定用户名，在脚本中使用：
```powershell
# 自动获取当前用户名
$username = $env:USERNAME
$sourceDir = "C:\Users\$username\.openclaw"
```

### 批量创建工作区

```powershell
# 创建师傅和小师妹的工作区
mkdir shifu-workspace
mkdir xiaomeimei-workspace

# 创建各自的备份目录
mkdir shifu-workspace\openclaw-backup
mkdir xiaomeimei-workspace\openclaw-backup
```

## 更新日志

### 2026-01-31
- 重新设计为团队公共仓库模式
- 每个成员有独立工作区
- 备份脚本在工作区内运行
- 添加完整的工作区管理指南
- 增加备份和恢复技巧
