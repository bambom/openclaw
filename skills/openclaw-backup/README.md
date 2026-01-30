# OpenClaw Backup Skill

多用户 OpenClaw 备份解决方案，支持大师兄、师傅、小师妹等团队成员各自备份到同一个 git 仓库。

## 适用场景

- **团队成员协作**：每个人在各自的电脑上备份 OpenClaw 数据
- **迁移便利**：换电脑时直接复制备份文件夹即可
- **版本控制**：通过 git 管理历史版本
- **空间优化**：自动排除 node_modules、临时文件等

## 快速开始

### 第一步：获取 Skill

将此 skill 复制到你的 OpenClaw skills 目录：
```
E:\Workspace\openclaw\skills\openclaw-backup\
```

### 第二步：配置备份路径

编辑 `scripts/backup-openclaw.ps1`，修改第 8-9 行：

```powershell
# 根据你的身份选择备份目录
# 大师兄
$backupDir = "E:\Workspace\oneyoemo\dashixiong-workspace\openclaw-backup"

# 师傅
$backupDir = "E:\Workspace\oneyoemo\shifu-workspace\openclaw-backup"

# 小师妹
$backupDir = "E:\Workspace\oneyoemo\shimei-workspace\openclaw-backup"
```

详细配置说明请查看 [CONFIG_EXAMPLES.md](CONFIG_EXAMPLES.md)

### 第三步：执行备份

**方式 1：仅备份**
```powershell
powershell -ExecutionPolicy Bypass -File "scripts\backup-openclaw.ps1"
```

**方式 2：备份并自动提交到 Git**
```batch
scripts\backup-and-commit.bat
```

## 文件说明

| 文件 | 说明 |
|------|------|
| SKILL.md | Skill 说明文档 |
| .gitignore | Git 忽略规则模板 |
| scripts/backup-openclaw.ps1 | 主备份脚本（可配置） |
| scripts/backup-and-commit.bat | 自动备份并提交的批处理 |
| CONFIG_EXAMPLES.md | 配置示例和常见问题 |

## 备份内容

备份包含完整的 OpenClaw 配置：

- `workspace/` - 身份信息、用户信息、灵魂、工具、心跳任务
- `agents/main/sessions/` - 对话历史
- `identity/` - 设备认证信息
- `cron/` - 定时任务配置
- `devices/` - 已配对设备
- `canvas/` - Canvas 相关数据
- `openclaw.json` - 主配置文件

## 排除的文件

自动排除以减小备份体积：

- `node_modules/` - npm 依赖（可通过 `npm install` 恢复）
- `*.lock` - 临时锁定文件
- `*.log` - 日志文件
- `*.db`、`*.sqlite` - 数据库文件
- `*.tmp`、`*.temp` - 临时文件
- `extensions/` - 扩展包（可重新安装）

## 迁移到新电脑

### 简单三步：

1. **安装 OpenClaw**
2. **克隆共享仓库**
3. **复制备份文件夹**
   ```powershell
   Copy-Item -Recurse "你的备份目录\*" "~\.openclaw"
   ```

### 恢复依赖（如果需要）

```powershell
cd ~/.openclaw/extensions
npm install
```

## 团队协作示例

假设仓库结构为：

```
oneyoemo/
├── dashixiong-workspace/      # 大师兄的备份
│   └── openclaw-backup/
├── shifu-workspace/           # 师傅的备份
│   └── openclaw-backup/
└── shimei-workspace/           # 小师妹的备份
    └── openclaw-backup/
```

每个人配置自己的备份目录后，都可以使用相同的备份脚本！

## 定时自动备份

### Windows 任务计划程序

1. 打开"任务计划程序"
2. 创建基本任务
3. 触发器：每天指定时间
4. 操作：启动程序
   - 程序：`powershell.exe`
   - 参数：`-ExecutionPolicy Bypass -File "E:\Workspace\openclaw\skills\openclaw-backup\scripts\backup-openclaw.ps1"`

### Cron 式自动备份

如果使用 Git Bash 或 WSL，可以添加 cron 任务：

```bash
# 编辑 crontab
crontab -e

# 每天凌晨 2 点备份
0 2 * * * powershell -ExecutionPolicy Bypass -File "/e/Workspace/openclaw/skills/openclaw-backup/scripts/backup-openclaw.ps1"
```

## 安全提醒

⚠️ **重要提示**：

- `identity/device-auth.json` 和 `credentials/` 可能包含敏感 token
- **仅备份到私有仓库**
- 提交前检查是否包含敏感信息
- 考虑在提交前加密敏感文件

## 常见问题

### Q: 备份速度慢怎么办？

A: robocopy 已经是最快的复制工具之一。如果仍然慢：
1. 检查是否有杀毒软件干扰
2. 将备份目录放在 SSD 上
3. 减小备份范围（修改 .gitignore）

### Q: 如何查看备份了多少文件？

A: 备份完成后会显示统计信息：
- 备份文件数
- 原始大小
- 备份大小
- 节省空间百分比

### Q: 忘记配置备份路径了怎么办？

A: 打开 `scripts/backup-openclaw.ps1` 第 8 行，查看 `$backupDir` 的值。

### Q: 如何恢复特定版本的备份？

A: 使用 Git 回退：
```bash
# 查看历史
git log --oneline

# 恢复到某个版本
git checkout <commit-hash> -- (备份目录)/
```

## 技巧与最佳实践

1. **定期备份**：建议每天备份一次
2. **测试恢复**：定期测试备份是否能正常恢复
3. **监控大小**：如果备份大小异常增长，检查是否有大文件未被排除
4. **团队同步**：定期与团队成员同步备份状态
5. **文档更新**：有新需求时及时更新此文档

## 更新日志

### 2026-01-31
- 初始版本发布
- 支持多用户配置
- 自动排除大文件和临时文件
- 提供自动化批处理脚本
