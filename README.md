# Claude Code Skills

自用 Claude Code Skills，开源分享。

## 技能列表

| 技能 | 说明 |
|------|------|
| `ppt-builder` | **父技能**——从源材料到 PPTX 课件的完整流水线。前期筹备委托 `source-library-builder`，自身专注排版工程（pptxgenjs） |
| `source-library-builder` | 前期资料库搭建——六阶段方法论（定范围→源发现→筛选→索引→精读→合成），可独立使用或作为 `ppt-builder` 子技能 |
| `bb-analysis` | 双轴分析法深度研究——系统性研究产品/公司/概念/人物的双轴分析框架，产出一份排版精美的 PDF 研究报告 |
| `vet-lit-review` | 兽医学文献快报——快速检索兽医临床问题最新文献，提取核心证据，输出排版精美的 PDF 快报 |
| `glm-chat` | GLM-5.2 对话——调用智谱 GLM-5.2 分析任务，支持多轮对话和会话持久化 |

## 环境要求

部分技能依赖外部工具和 API key，安装后需自行配置：

| 依赖 | 涉及技能 | 说明 |
|------|---------|------|
| `SCNET_API_KEY` | glm-chat | GLM API 密钥，注册于 scnet.cn |
| `QWEN_API_KEY` | source-library-builder | 通义千问 API 密钥，用于反证校验 |
| `pip install reportlab markdown requests` | vet-lit-review | PDF 生成和文献检索 |
| `pip install weasyprint markdown` | bb-analysis | PDF 报告生成 |
| `pip install pyyaml openai` | source-library-builder | 同义词检索和 LLM 校验 |
| `pdftotext` (xpdf) | source-library-builder | PDF 文本提取 |
| Node.js + `pptxgenjs` | ppt-builder | PPTX 生成 |

## 安装

将技能目录放入 `~/.claude/skills/` 即可，Claude Code 会自动发现。

```bash
git clone https://github.com/Jehomn/claude-skills.git
cp -r claude-skills/* ~/.claude/skills/
```
