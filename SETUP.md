# 新机器安装指南

## 1. 安装 Claude Code

参照 Anthropic 官方文档安装 Claude Code CLI。

## 2. 克隆技能仓库

```powershell
# 在用户目录下创建 .claude 目录（如果还没有）
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude"

# 克隆技能仓库
git clone https://github.com/Jehomn/claude-skills.git "$env:USERPROFILE\.claude\skills"
```

## 3. 项目设置

每个项目目录下放置自己的 `CLAUDE.md`。最低限度内容：

```markdown
# 项目名

## 写作约束
严格遵守仓库 `WRITING_STANDARDS.md` 中的全部规范。
```

或直接复制仓库根目录的 `WRITING_STANDARDS.md` 中的 5 节规则到 CLAUDE.md。

## 4. 环境依赖（按需）

```powershell
# Python 依赖（source-library-builder）
pip install pyyaml openai --break-system-packages

# Node.js 依赖（ppt-builder 等）
npm install -g puppeteer docx

# PDF 工具
# pdftotext 从 https://www.xpdfreader.com/download.html 下载
# 或 choco install xpdf
```

## 5. 验证

```powershell
# 确认技能目录结构
Get-ChildItem "$env:USERPROFILE\.claude\skills" -Recurse -Depth 1

# 应该看到: source-library-builder/ bb-analysis/ ppt-builder/ vet-lit-review/ glm-chat/
# 以及 WRITING_STANDARDS.md README.md SETUP.md
```
