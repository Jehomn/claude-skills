---
name: ppt-builder
description: Use whenever the user wants to create a professional slide deck (.pptx) from source materials (PDFs, books, documents, research). Triggers include: "make a PPT", "create slides", "build a deck", "generate a presentation", "把这做成PPT", "做课件", "生成幻灯片". Also trigger when the user mentions turning knowledge base / textbook / research into teaching materials, or when they have a large volume of source content to compress into structured slides. Do NOT trigger for simple 1-2 page slides, Google Slides, or general "make it pretty" requests unrelated to structured knowledge-to-slide pipelines.

本技能为父技能：前期资料筹备（策选→索引→精读→内容稿）委托子技能 `source-library-builder` 完成，本技能专注于从内容稿到 PPTX 的排版工程。
---

# PPT-Builder

A streamlined methodology for transforming large source materials into professional, citation-backed slide decks. Born from a successful 27-textbook → 109-slide veterinary anesthesia course project.

## When to Use

This skill applies when ALL of these are true:
- Source materials exist (PDFs, books, documents) in volume (>5 sources or >500 pages)
- A structured multi-page presentation is the goal (>20 slides)
- Content fidelity matters (citations, specific data, cross-referencing)

## The 5-Stage Pipeline (overview)

Don't jump to slide generation. Follow the stages in order:

```
1-4. 前期资料筹备 → 5. 排版工程: Generate PPTX
```

### Stages 1-4 — 前期资料筹备

**委托子技能 `source-library-builder` 完成。** 该技能覆盖完整的 6 阶段流水线：

1. 定范围（PICO/TIS 框架 + 排除清单）
2. 源发现（学术 + 本地 + 网页三线并行）
3. 源筛选（Tier 1/2 分层 + 纳入排除标准）
4. 全量索引（synonyms.yaml + grep 扩召回 + 0-3 评分 + 反证校验）
5. 精读比对（pdftotext 分段提取 + [差异]标注 + 证据分级 ●●●/●●○/●○○）
6. 知识合成（5 压缩操作 → 结构化 Markdown 内容稿）

调用方式：加载 `source-library-builder` skill，明确告知研究主题和输出目标（"用于生成 PPT 课件"）。该技能产出以下文件，其中 `内容稿.md` 是本技能 Stage 5 的唯一入口：

```
项目目录/
├── 研究范围.md
├── 源清单.md
├── synonyms.yaml
├── 索引表.md
├── 差异报告.md
└── 内容稿.md          ← ppt-builder 入口
```

**内容稿格式要求：**
- 每条结论有引用角标 `[1][2]`
- 数字具体，不模糊（"MAP < 60 mmHg 持续 >3min" 而非 "血压过低"）
- 机制按因果链解释："A → B → C"
- 中文引号「」不用 ASCII "
- 缩写首次出现用"中文译名（英文全名，ABBR）"格式
- 禁止句式："值得注意的是""大量研究表明""在临床实践中"
- 搜不到的信息标注"该信息暂缺"

### Stage 5 — Generate PPTX (2-4h/module + iteration)
Use **pptxgenjs direct encoding** (Node.js). Do NOT attempt HTML→PPTX translation — it will fail (CSS cascade pollution, font metric differences, rendering engine incompatibility). This lesson cost 3 failed attempts.

## Architecture: Template-Data Separation

Define 5-7 slide templates once. Express all content as JS data objects. This is how 109 slides are generated from ~500 lines of code.

**Templates** (write once):
| Template | Use case | Key params |
|----------|---------|-----------|
| `contentSlide` | Text + optional tip box | `sec, title, sub, paras[], tip` |
| `tableSlide` | Data tables | `tbl{h, r, cr}` — headers, rows, column ratios |
| `cover()` | Title slide | Author, affiliation, module TOC |
| `intro()` | Speaker intro | Photo + categorized credentials |
| `modTitle()` | Module divider | Auto-adapts section lists per module |
| `refBooks()` | Bibliography | Grouped reference list with abbreviations |

**Data** (write per slide):
```javascript
{ t:'table', mi:1, pim:7, sec:'Section', title:'Title',
  intro:'...', tbl:{h:[...], cr:[...], r:[[...]]}, refs:[...], pn:0 }
```
`t` = template type, `mi` = module index (color), `pim` = page-in-module (progress bar), `pn` = auto-assigned by counter.

## Critical Constraints

### Whitespace
**Target: <20% whitespace per slide.** Calculate: `(content_bottom - content_top) / (refs_divider - header_bottom)`. Adjust via font sizes, row heights, and spacing — not by adding fluff.

### Typography (Chinese)
- Font: **Microsoft YaHei** globally
- Quotes: 「」 only — ASCII " will break JS string parsing
- **Anti-widow rule:** no text line should end with 1-4 orphan characters. Widen text boxes, use `shrinkText`, or restructure layout. This is the most common bug.
- Page numbers: width ≥ 0.5" (prevents 2-digit wrapping), format with `padStart(2,'0')`

### Progress Bar
- `shrinkText: true, wrap: false` — never let narrow-segment labels wrap
- Dynamic text color: dark when fill <45%, white when ≥45% (text is centered)
- Module transitions: `addProgressBar(slide, modIdx, pim)` — seamless across merged modules

### Color System
Use a per-module accent color for module identity. Content slides share neutral palette (`#172228` body, `#F6F8F9` background). Cover/intro/ref pages use `#F5F5F7` (Apple warm light gray). Clinical tips: amber `#FFF8E1` background + `#F0A500` left border.

### References
Divider line at `refsY - 0.08` serves as layout boundary — all content must end ≥0.04" above it. Per-page refs at 8.5pt, full format, ≤5 per page.

## Common Pitfalls

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| HTML→PPTX looks wrong | Browser and PPT engines are fundamentally different | Skip translation; use pptxgenjs directly |
| Content feels thin | Wrote JS before content draft | Write Markdown draft first, review it, then code |
| Page numbers duplicated | Hardcoded page numbers | Use global counter in `main()`; auto-assign |
| Whitespace >30% | Fonts too small, rows too short | Scale up: table body 13pt at 0.46" row height |
| Footer overlap | Enlarged content without checking boundary | Refs divider = safety line; verify all elements above it |
| Module title bar invisible | Module color = slide background on cover | Use lighter tint for cover TOC bars |
| Two-column text disappears | Nested arrays from `.map(supText)` | Flatten with paragraph breaks: `forEach + push(...supText(t, size))` |

## Iteration Pattern

1. Build 3-4 sample slides first — validate templates, colors, spacing
2. Build one full module — validate content density and flow
3. Build remaining modules — templates already proven
4. Merge independent module files only after all are validated

Each build cycle: `node build.js` → open PPTX → review → fix 2-3 issues → repeat. Don't batch 10 changes.

## Output Standards

- All data citations traceable to source PDFs
- Book abbreviations follow project `CLAUDE.md` standard (e.g., "Lumb & Jones 6th" not "Lumb")
- Final output: `{项目名}.pptx` (semantic name, no version suffix)
- Git version control for all text/code assets (not PDF binaries)

## Reference

## Deep Reference

When the user needs deeper guidance, read `references/PPT工程手册.md` — the complete 18-chapter engineering manual bundled with this skill. It covers: photo layering, whitespace calculation, capnography handling, knowledge compression, aesthetic vocabulary building, trust calibration, failure decision logs, and the full 13-pattern meta-methodology. This file travels with the skill — no external dependencies.

**Read the manual BEFORE doing any of these:**
- Designing a cover, intro page, or closing page (manual §三, §八 for design tokens and photo techniques)
- Setting up the progress bar system (manual §四 for state machine and color-switching logic)
- Troubleshooting whitespace (manual §七 for calculation methodology)
- Establishing a book abbreviation standard (manual §九 for naming principles)
- Debugging a layout bug you can't explain (manual §十一 for the 12-item trap table)
- Starting a new module from scratch (manual §一 for the full 5-stage pipeline details)
- Planning file organization or naming conventions (manual §十 for version management patterns)
- Evaluating whether to automate a visual element or leave it manual (manual §十四, pattern 14.9 Escape Hatch)
