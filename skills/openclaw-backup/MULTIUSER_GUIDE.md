# OpenClaw Backup Skill - 多用户独立版本

每个用户在自己的 oneyoemo 目录下创建独立的备份脚本，避免互相干扰。

## 为什么需要独立脚本？

1. **路径不同**：每个用户的 oneyoemo 工作区路径不同
2. **独立配置**：各自配置自己的备份目录
3. **避免冲突**：不会因为一个人修改影响其他人
4. **灵活部署**：每个人可以选择自己的存储位置

## 快速开始（三步搞定）

### 第一步：选择你的用户身份

| 用户 | 常见oneyoemo路径 | 说明 |
|------|----------------|------|
| **大师兄**（李剑辛） | `E:\Workspace\oneyoemo\` | 默认配置，无需修改 |
| **师傅** | `E:\Workspace\oneyoemo\` | 可能在D盘、E盘等 |
| **小师妹** | `C:\oneyoemo\` | 可能在C盘根目录 |

### 第二步：复制模板脚本到你的oneyoemo目录

在你的 oneyemo 目录下创建备份脚本文件夹：

```powershell
# 大师兄（默认位置，可跳过）
# 备份脚本已经存在于：E:\Workspace\oneyoemo\backup-scripts\

# 师傅（假设在 E:\Workspace\oneyoemo）
mkdir E:\Workspace\oneyoemo\backup-scripts
# 然后复制下面的模板脚本到这个目录

# 小师妹（假设在 C:\oneyoemo）
mkdir C:\oneyoemo\backup-scripts
# 然后复制下面的模板脚本到这个目录
```

### 第三步：编辑脚本配置

打开你刚复制的 `backup-openclaw.ps1`，修改第 3-6 行：

```powershell
# ==================== 配置区域 ====================
# 1. OpenClaw 源目录（根据你的系统修改）
$sourceDir = "C:\Users\你的用户名\.openclaw"

# 2. 备份目标目录（你的 oneyemo 路径）
$backupDir = "C:\oneyoemo\openclaw-backup"  # 修改为你的路径
# ==================================================
```

**示例配置：**

**小师妹（C:\oneyoemo）：**
```powershell
$sourceDir = "C:\Users\xiaomeimei\.openclaw"
$backupDir = "C:\oneyoemo\openclaw-backup"
```

**师傅（E:\oneyoemo）：**
```powershell
$sourceDir = "C:\Users\shifu\.openclaw"
$backupDir = "E:\oneyoemo\openclaw-backup"
```

**大师兄（E:\Workspace\oneyoemo）：**
```powershell
$sourceDir = "C:\Users\bambo\.openclaw"
$backupDir = "E:\Workspace\oneyoemo\openclaw-backup"
```

## 模板脚本说明

| 文件 | 说明 |
|------|------|
| `backup-openclaw.ps1` | 主备份脚本模板（复制到你的oneyoemo目录后修改配置） |
| `.gitignore` | Git忽略规则（复制到你的备份目录） |
| `CONFIG_GUIDE.md` | 详细配置指南 |

## 使用流程

### 日常备份

```powershell
# 进入你的 oneyemo 目录
cd C:\oneyoemo  # 或 E:\Workspace\oneyoemo 等

# 运行备份
.\backup-scripts\backup-openclaw.ps1
```

### 自动备份（可选）

创建 Windows 计划任务：
1. 打开"任务计划程序"
2. 创建基本任务
3. 触发器：每天指定时间
4. 操作：启动程序
   - 程序：`powershell.exe`
   - 参数：`-ExecutionPolicy Bypass -File "C:\oneyoemo\backup-scripts\backup-openclaw.ps1"`

### 提交到 Git

每个人的备份目录不同，所以各自提交：

```bash
# 小师妹
cd C:\oneyoemo
git add openclaw-backup/
git commit -m "backup: OpenClaw data sync"
git push

# 师傅
cd E:\Workspace\oneyoemo
git add openclaw-backup/
git commit -m "backup: OpenClaw data sync"
git push

# 大师兄
cd E:\Workspace\oneyoemo
git add openclaw-backup/
git commit -m "backup: OpenClaw data sync"
git push
```

## 目录结构示例

```
C:\oneyoemo/                    # 小师妹的 oneyemo
├── backup-scripts/
│   ├── backup-openclaw.ps1   # 她的个人备份脚本
│   └── .gitignore
└── openclaw-backup/         # 她的备份文件

E:\oneyoemo/                    # 师傅的 oneyemo
├── backup-scripts/
│   ├── backup-openclaw.ps1   # 他的个人备份脚本
│   └── .gitignore
└── openclaw-backup/         # 他的备份文件

E:\Workspace\oneyoemo/         # 大师兄的 oneyemo
├── backup-scripts/
│   ├── backup-openclaw.ps1   # 我的个人备份脚本
│   └── .gitignore
└── openclaw-backup/         # 我的备份文件
```

## 优势

1. **完全独立**：每个人的脚本互不干扰
2. **灵活配置**：可以根据自己的路径调整
3. **便于维护**：不需要协调修改同一个文件
4. **安全可靠**：配置错误不会影响其他人

## 常见问题

### Q: 如何找到我的 .openclaw 目录？

A: 打开 PowerShell，运行：
```powershell
$env:USERPROFILE\.openclaw
# 或者
echo ~\.openclaw
```

### Q: 不确定自己的 oneyemo 路径怎么办？

A: 问师傅或大师兄，或者：
- 检查 Git 克隆位置
- 检查项目文件夹位置

### Q: 可以把备份脚本放到其他位置吗？

A: 可以！只要正确配置 `$sourceDir` 和 `$backupDir` 即可，脚本可以放在任何位置。

### Q: 多个电脑都需要备份怎么办？

A: 在每台电脑上复制脚本并配置路径即可，可以使用相同的 git 仓库。

### Q: 团队如何同步备份状态？

A: 定期在团队群里分享备份成功的截图或日志，互相确认是否正常。

## 迁移到新电脑

1. **克隆你的 oneyemo 仓库**到新电脑
2. **复制你的备份脚本**（如果在新电脑上没有）
3. **配置路径**（如果用户名或路径不同）
4. **恢复备份**：
   ```powershell
   Copy-Item -Recurse "openclaw-backup\*" "~\.openclaw"
   ```

## 最佳实践

1. **第一次配置后测试**：运行脚本确认备份成功
2. **定期备份**：建议每天备份一次
3. **检查备份大小**：如果异常增长，检查是否有大文件未被排除
4. **定期提交到Git**：防止本地数据丢失
5. **团队协作**：遇到问题及时在群里沟通

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

如果不确定用户名，在脚本中使用变量：

```powershell
# 自动获取当前用户名
$username = $env:USERNAME
$sourceDir = "C:\Users\$username\.openclaw"
```

### 监控备份文件变化

可以在脚本最后添加：

```powershell
# 记录备份时间
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"$timestamp - Backup completed" | Out-File "backup.log" -Append
```

## 更新日志

### 2026-01-31
- 重新设计为多用户独立版本
- 每个人在自己的 oneyemo 目录创建备份脚本
- 避免共享 skill 文件的配置冲突
- 提供灵活的配置选项
