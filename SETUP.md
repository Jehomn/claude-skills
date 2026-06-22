# 新机器安装指南

## 一键部署

```powershell
powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\skills\scripts\setup.ps1"
```

脚本自动判断场景：
- **已有旧技能目录** → 备份 → 克隆仓库 → 拷回本地独有技能
- **全新机器** → 直接克隆
- **已部署过** → `git pull` 增量更新

## 手动安装（备选）

### 全新安装

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude"
git clone https://github.com/Jehomn/claude-skills.git "$env:USERPROFILE\.claude\skills"
```

### 已有本地独有技能的合并安装

```powershell
Rename-Item "$env:USERPROFILE\.claude\skills" "$env:USERPROFILE\.claude\skills.bak"
git clone https://github.com/Jehomn/claude-skills.git "$env:USERPROFILE\.claude\skills"
# 把 skills.bak 中仓库没有的文件夹拷回 skills\
```

### 后续更新

```powershell
cd "$env:USERPROFILE\.claude\skills"
git pull
```

## 环境依赖（按需）

```powershell
pip install pyyaml openai --break-system-packages   # source-library-builder
npm install -g puppeteer docx                        # ppt-builder / docx
choco install xpdf                                   # pdftotext
```

## 项目 CLAUDE.md 模板

```markdown
## 写作约束
严格遵守 `WRITING_STANDARDS.md` 中的全部规范。
```
