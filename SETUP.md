# 新机器安装指南

## 全新安装

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude"
git clone https://github.com/Jehomn/claude-skills.git "$env:USERPROFILE\.claude\skills"
```

## 已有本地独有技能的合并安装

如果机器上已装过部分技能且有本地独有内容，用三步安全合并：

```powershell
# 1. 备份现有技能
Rename-Item "$env:USERPROFILE\.claude\skills" "$env:USERPROFILE\.claude\skills.bak"

# 2. 克隆仓库
git clone https://github.com/Jehomn/claude-skills.git "$env:USERPROFILE\.claude\skills"

# 3. 把备份中仓库没有的技能拷回来
$repoSkills = @('bb-analysis','glm-chat','ppt-builder','source-library-builder','vet-lit-review')
Get-ChildItem "$env:USERPROFILE\.claude\skills.bak" -Directory | Where-Object {
    $_.Name -notin $repoSkills
} | Copy-Item -Recurse -Destination "$env:USERPROFILE\.claude\skills\"
```

之后每次更新仓库技能：

```powershell
cd "$env:USERPROFILE\.claude\skills"
git pull
```

## 环境依赖（按需）

```powershell
# Python（source-library-builder）
pip install pyyaml openai --break-system-packages

# Node.js（ppt-builder、docx 生成等）
npm install -g puppeteer docx

# pdftotext（PDF 文本提取）
# 从 https://www.xpdfreader.com/download.html 下载
# 或 choco install xpdf
```

## 项目 CLAUDE.md 模板

每个项目的 CLAUDE.md 加入对共享规范的引用：

```markdown
## 写作约束
严格遵守 `WRITING_STANDARDS.md` 中的全部规范。
```
