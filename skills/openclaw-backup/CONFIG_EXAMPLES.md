# OpenClaw Backup - 配置示例

## 快速配置指南

### 第一步：确定你的用户身份

选择你的身份并配置对应的备份路径：

| 用户 | 备份目录 |
|------|---------|
| 大师兄（李剑辛） | `E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup` |
| 师傅 | `E:\Workspace\oneyoemo\shifu-workspace\openclaw-backup` |
| 小师妹 | `E:\Workspace\oneyoemo\shimei-workspace\openclaw-backup` |

### 第二步：编辑备份脚本

打开 `scripts/backup-openclaw.ps1`，找到第8行附近：

```powershell
# 2. 备份目标目录（每个用户不同）
$backupDir = "E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup"
```

将 `$backupDir` 修改为你的备份目录：

**师傅的配置：**
```powershell
$backupDir = "E:\Workspace\oneyoemo\shifu-workspace\openclaw-backup"
```

**小师妹的配置：**
```powershell
$backupDir = "E:\Workspace\oneyoemo\shimei-workspace\openclaw-backup"
```

### 第三步：创建你的备份目录

在 git 仓库中创建你的工作区目录：

```bash
cd E:\Workspace\oneyoemo

# 师傅执行
mkdir shifu-workspace\openclaw-backup

# 小师妹执行
mkdir shimei-workspace\openclaw-backup
```

### 第四步：复制.gitignore到你的备份目录

```powershell
# 师傅
Copy-Item "E:\Workspace\openclaw\skills\openclaw-backup\.gitignore" "E:\Workspace\oneyoemo\shifu-workspace\openclaw-backup\"

# 小师妹
Copy-Item "E:\Workspace\openclaw\skills\openclaw-backup\.gitignore" "E:\Workspace\oneyoemo\shimei-workspace\openclaw-backup\"
```

### 第五步：测试备份

```powershell
powershell -ExecutionPolicy Bypass -File "E:\Workspace\openclaw\skills\openclaw-backup\scripts\backup-openclaw.ps1"
```

如果看到"备份完成！"，说明配置成功！

## 仓库结构示例

配置完成后，仓库结构如下：

```
oneyoemo/
├── dashixiong-workspace/      # 大师兄的备份
│   └── openclaw-backup/
│       ├── workspace/
│       ├── agents/
│       ├── identity/
│       └── .gitignore
├── shifu-workspace/           # 师傅的备份
│   └── openclaw-backup/
│       ├── workspace/
│       ├── agents/
│       ├── identity/
│       └── .gitignore
└── shimei-workspace/           # 小师妹的备份
    └── openclaw-backup/
        ├── workspace/
        ├── agents/
        ├── identity/
        └── .gitignore
```

## 常见问题

### Q: OpenClaw源目录不在 C:\Users\bambo\.openclaw 怎么办？

A: 编辑 `backup-openclaw.ps1` 第5行：
```powershell
$sourceDir = "C:\你的用户名\.openclaw"
```

### Q: 想自动推送到远程仓库怎么办？

A: 创建一个定时任务或编辑 `backup-and-commit.bat` 最后一行添加 `git push`。

### Q: 备份速度太慢怎么办？

A: robocopy 已经是最快的复制工具之一。如果仍然慢，可以考虑：
1. 只备份必要文件（修改 .gitignore）
2. 使用 SSD 硬盘
3. 关闭杀毒软件临时排除相关目录

### Q: 如何查看备份了哪些文件？

A: 运行备份脚本后会显示：
- 备份文件数
- 备份大小
- 节省空间百分比
