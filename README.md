# Claude Code Skills

自用 Claude Code Skills，开源分享。

## 技能列表

| 技能 | 说明 |
|------|------|
| `ppt-builder` | **父技能**——从源材料到 PPTX 课件的完整流水线。前期筹备委托 `source-library-builder`，自身专注排版工程（pptxgenjs） |
| `source-library-builder` | 前期资料库搭建——六阶段方法论（定范围→源发现→筛选→索引→精读→合成），可独立使用或作为 `ppt-builder` 子技能 |
| `bb-analysis` | 双轴分析法深度研究——系统性研究产品/公司/概念/人物的双轴分析框架，产出一份排版精美的 PDF 研究报告 |
| `vet-lit-review` | 兽医学文献快报——快速检索兽医临床问题最新文献，提取核心证据，输出排版精美的 PDF 快报 |

## 安装

将技能目录放入 `~/.claude/skills/` 即可，Claude Code 会自动发现。

```bash
git clone https://github.com/Jehomn/claude-skills.git
cp -r claude-skills/* ~/.claude/skills/
```
