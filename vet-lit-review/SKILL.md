---
name: vet-lit-review
description: |
  兽医学文献快报Skill。当用户想要研究一个兽医学/动物医学临床问题时使用——快速检索最新文献，提取核心证据，输出排版精美的PDF快报。
  触发场景：兽医临床问题研究、动物疾病诊疗证据查询、兽药/麻醉方案对比、兽医文献综述、循证兽医学决策支持。
  触发词：研究一下、查一下文献、证据如何、有没有最新研究、做个文献综述、帮我找找关于XX的文献、XX是什么研究现状、快速综述。
  仅限兽医学/动物医学领域。不用于简单的名词解释、非学术性问答。
---

# 兽医学文献快报

你正在执行一次兽医学文献快报（Veterinary Literature Flash Review）。最终产出一份**排版精美的PDF报告**。

## 前置准备

### 环境确认

依赖：`pip install reportlab markdown requests`（或 `pip install reportlab markdown requests --break-system-packages`）

**Python 路径**：系统可能有多个 Python 版本。执行脚本前先确认可用 Python：
- 先试 `python3`，再试 `python`，都不可用则检查 `C:\Python314\python.exe` 或 `where python`
- 用确认可用的 Python 路径执行所有脚本命令

**网络环境**：在中国大陆访问 PubMed Entrez API、Semantic Scholar、学术期刊网站时，需要 VPN/代理。检索前执行快速连通性检查：

```bash
python -c "import urllib.request; r=urllib.request.urlopen('https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&retmax=1&term=dog&retmode=json', timeout=10); print('PubMed OK' if r.status==200 else f'Status {r.status}')"
```

如果超时或返回错误，**提醒用户打开 VPN 后重试**。PubMed API 不通时不要继续检索——所有后续数据源都依赖外网。

检查 `scripts/md_to_pdf.py` 和 `scripts/lit_search.py` 可用。

### 明确研究问题

收到用户输入后，确认以下信息。用户已经给得足够明确就不追问，直接开始：
1. **研究主题**：具体的临床问题/药物/疾病/手术方案
2. **关注的方向**（可选）：有没有特别想关注的临床维度？
3. **时间范围**（可选）：默认近5年

---

## 第一步：问题解析

把用户问题拆成结构化检索单元，**先写下来再搜**：

- **PICO 拆解**（临床问题）：患者/问题(P)、干预(I)、对照(C)、结局(O)
- **关键词组**：中英文各一套，含同义词和 MeSH 词
- **检索范围**：默认近5年，用户可指定
- **检索策略笔录**：写下主要检索式，避免漫无目的搜

### 查询构建原则（关键）

PubMed 对短查询响应最好。实测经验：

- ✅ 5-8 个关键词：`brachycephalic syndrome dog surgery palatoplasty` → 25 篇
- ❌ 15+ 个关键词：`dog brachycephalic airway obstruction BOAS diagnosis surgery treatment palatoplasty` → 0 篇

**策略**：把复杂 PICO 拆成 2-3 个短查询，每个查询聚焦一个子问题。例如：
- 查询1（诊断）：`brachycephalic dog diagnosis exercise test plethysmography`
- 查询2（手术）：`brachycephalic syndrome dog surgery palatoplasty`
- 查询3（预后）：`brachycephalic dog postoperative outcome complications`

每个短查询单独调用 `lit_search.py`，最后合并去重。脚本内置查询长度提示（>12词会警告）。

---

## 第二步：文献检索与筛选

### 2.1 运行检索脚本

每个子查询运行一次，使用 `--text` 模式直接输出可读文献列表：

```bash
python scripts/lit_search.py --query "[短查询1]" --max 30 --text
python scripts/lit_search.py --query "[短查询2]" --max 30 --text
```

输出格式：每篇文献包含 PMID、作者、年份、期刊、标题、摘要（前300字）、研究类型。

**可用输出模式**：
- `--text`：全文摘要模式（默认推荐，用于筛选文献）
- `--brief`：仅标题+类型（用于快速扫描）
- 不加 flag：JSON 模式（用于程序化处理）

**如果 PubMed 返回 0 结果**：
脚本已内置自动降级：PubMed vet filter 返回 0 时自动用 `--no-vet-filter` 重试一次。若仍为 0：
1. 缩短查询词（删除次要关键词，只留 3-5 个核心词）
2. 换用更通用的同义词（如 `surgery` 替代 `palatoplasty`）
3. 尝试 `"[疾病/药物]"[MeSH Terms]` 的 MeSH 词检索

**S2 限流说明**：Semantic Scholar 可能返回 HTTP 429，脚本已内置指数退避重试（起始 5s，最大 20s）。不依赖 S2 —— PubMed 是主源。

### 2.2 补搜指南源

根据主题获取权威指南。**优先用 PubMed 检索**（WebFetch 在部分环境可能不可用）：

| 来源 | 首选方式（PubMed） | 备选（WebFetch） |
|------|-------------------|-----------------|
| WSAVA | `"WSAVA"[org] AND guideline[ptyp]` | wsava.org/guidelines |
| ACVIM | `"consensus statement"[tiab] AND "J Vet Intern Med"[journal]` | — |
| ISFM/AAFP | `guideline[ptyp] AND "J Feline Med Surg"[journal]` | — |
| AAHA | `"AAHA"[org] AND guideline[ptyp]` | aaha.org/guidelines |
| RECOVER | PubMed: `recover[tiab] AND cpr[tiab] AND veterinary[sb]` | recoverinitiative.org |
| IVIS | — | ivis.org（仅 WebFetch） |

WebFetch 不可用时的通用替代：直接在 PubMed 搜索 `"[主题词]"[tiab] AND (guideline[ptyp] OR "consensus"[tiab]) AND veterinary[sb]`。

### 2.3 筛选文献

按纳入/排除标准筛选：

**纳入：**
- 兽医学：RCT、观察性研究、病例系列、系统综述/荟萃分析、临床指南（WSAVA/AAHA/ACVAA/ISFM/AAFP/RECOVER/ACVIM）、病例报告（罕见病/新技术）、叙述性综述（权威作者/高被引）
- 比较医学：动物模型研究，需有明确临床转化价值
- 人类医学：仅当兽医直接证据不足，或作为横断对比参照（必须标注来源域差异）

**排除：**
- 纯体外实验（in vitro only）
- 会议摘要（最近6个月内且无全文替代的除外）
- 非同行评议的个人博客/自媒体
- 人类医学纯临床研究，无动物/比较医学关联性

符合纳入标准的高质量文献**全部保留**进入报告，不对数量做人为限制。如需人医参照，追加检索（不加 veterinary filter）。

---

## 第三步：全文获取

筛选完成后，对入选的每篇文献逐篇获取全文。获取不到全文的，抓取 PubMed 完整结构化摘要。

### 3.1 运行全文获取脚本

```bash
python scripts/fetch_fulltext.py --pmids "PMID1,PMID2,..." --output papers_full.json
```

脚本按以下优先级尝试获取全文：

| 优先级 | 来源 | 方式 | 说明 |
|--------|------|------|------|
| 1 | PubMed Central (PMC) | E-utils elink → 解析 PMC XML | 提取引言/方法/结果/讨论/结论各章节 |
| 2 | Europe PMC | REST API | 检查 OA PDF 和全文链接 |
| 3 | Unpaywall | DOI API | 查找合法 OA 版本（含预印本/机构仓储） |
| 4 | PubMed 降级 | E-utils efetch | 完整结构化摘要（不截断，含 Objectives/Methods/Results/Conclusions 分段） |

`--email` 参数可选但推荐提供，用于 Unpaywall 礼貌访问。

**输出结构** (`papers_full.json`)：
```json
[
  {
    "pmid": "12345678",
    "title": "...",
    "authors": ["Last FM", ...],
    "journal": "...",
    "year": "2024",
    "doi": "10.xxx/yyy",
    "access_status": "full_text | abstract_only",
    "access_source": "PMC (PMC123456) | PubMed",
    "abstract": "完整摘要，无截断...",
    "pub_types": ["..."],
    "mesh_terms": ["..."],
    "full_text_sections": {
      "pmc_id": "PMC123456",
      "abstract": "...",
      "introduction": "...",
      "methods": "...",
      "results": "...",
      "discussion": "...",
      "conclusions": "..."
    }
  }
]
```

`access_status` 为 `full_text` 时，`full_text_sections` 包含各章节内容；为 `abstract_only` 时该字段为 `null`，使用 `abstract` 字段。

### 3.2 用人类可读模式审阅

```bash
python scripts/fetch_fulltext.py --pmids "..." --text
```

`--text` 模式直接输出每篇论文的全文/摘要内容到终端，方便阅读和提取要点。

### 3.3 逐文献提取

逐篇阅读 `papers_full.json` 中各篇内容，提取以下信息：

- 研究设计类型 + 样本量 + 对象特征
- 核心发现（1-2句，带关键数字）
- 临床价值判断（1句）
- 证据强度标记：
  - **强（●●●）**：多中心RCT、高质量系统综述/Meta分析、权威指南推荐
  - **中（●●○）**：单中心RCT、高质量观察性研究、样本充足的病例对照
  - **弱（●○○）**：小型RCT(n<30)、病例系列、专家共识、回顾性研究

全文获取的论文重点关注方法学细节和讨论中的局限性；仅获取摘要的论文如实标注获取限制。

---

## 第四步：按模板成文

严格遵循 `references/report-template.md` 的骨架。报告结构：

```
封面页
一句话结论（≤80字）
一页总览（证据矩阵表4-10行 + 临床行动建议2-3条）
分区证据卡片（4-6张，每张200-300字，可能含人医参照卡片）
入选文献详览（全部入选文献的完整摘要+全文要点，按篇逐一呈现）
研究动向（每个方向≤100字）
研究缺口（≤80字）
结论与思考（100-500字，四段式：临床建议/矛盾与张力/盲区/人医启发）
来源（全部文献标注PMID/DOI + 检索时间 + 检索平台）
```

每篇入选文献提取：

- 研究设计类型 + 样本量 + 对象特征
- 核心发现（1-2句，带关键数字）
- 临床价值判断（1句）
- 证据强度标记：
  - **强（●●●）**：多中心RCT、高质量系统综述/Meta分析、权威指南推荐
  - **中（●●○）**：单中心RCT、高质量观察性研究、样本充足的病例对照
  - **弱（●○○）**：小型RCT(n<30)、病例系列、专家共识、回顾性研究

---

## 第五步：PDF生成

成文保存为 `[主题]_文献快报.md`，运行转换：

```bash
python scripts/md_to_pdf.py "[主题]_文献快报.md" "[主题]_文献快报.pdf" --author "Jehomn Bea"
```

脚本使用 ReportLab 生成 PDF，自动生成封面（标题+副标题"兽医学文献快报"+作者+检索信息）、页眉页脚、证据矩阵表（海军蓝表头）、证据卡片（钢蓝左边框）、人医参照卡片（琥珀金左边框）、一句话结论高亮框。

### PDF 生成后：弹出资源管理器

PDF 和 MD 文件生成完成后，用资源管理器定位到输出文件，方便用户立即找到：

```powershell
explorer /select,"<完整路径>\[主题]_文献快报.pdf"
```

---

## 写作风格

### 核心原则

"看完第1页就能做决策。"

### 风格规则

| 规则 | 说明 |
|------|------|
| 数字优先 | 不说"效果更好"，说"呼吸暂停风险降低38%，RR=0.62" |
| 一句一事 | 每句话只传递一个信息点 |
| 无背景铺陈 | 不开场介绍疾病背景/流行病学，直接进入证据 |
| 结论先行 | 每个卡片/段落第一句就是结论 |
| 证据强度每一处都标 | 强/中/弱 + 一句话理由 |
| 不确定性直接说 | 不模糊、不回避，"目前证据不能回答这个问题" |

### 人医参照写法

必须标注来源域差异，格式固定：

> **人医参照：** Cochrane系统综述（2023）显示丙泊酚在儿童麻醉中呼吸暂停发生率18-30%。兽医学尚无同等质量数据。**跨物种外推需谨慎**。

### 缩写规范

- 首次出现：**"中文全称（English Full Name, ABBR）"**。示例："短头阻塞性气道综合征（Brachycephalic Obstructive Airway Syndrome, BOAS）"
- 后文直接用缩写：BOAS
- 标题中也遵守：标题首次出现的缩写同样展述，后文标题可沿用缩写
- 不预设读者知道任何缩写，哪怕兽医通用缩写（如 CBC、NSAID）也须首次展述

### 禁区

- 套话："综上所述""值得注意的是""不难发现""在当今AI快速发展的时代"
- 空洞词："赋能""抓手""打造""说白了""本质上""换句话说"
- 不写"需要更多研究"，写"目前最缺X类型的证据"
- 不写"可能""或许"软化语气，除非不确定性本身就是结论
- 不写叙事性背景（"XX病在兽医临床中越来越常见"——删）
- 搜不到的信息写"该信息暂缺"，不编造

### 篇幅控制

| 板块 | 限制 |
|------|------|
| 一句话结论 | ≤80字 |
| 每张证据卡片 | 200-300字 |
| 证据矩阵表 | 4-10行 |
| 研究动向 | ≤100字/方向 |
| 研究缺口 | ≤80字 |
| 结论与思考 | 100-500字 |
| 全文（不含参考文献） | 2000-5000字 |

### 结论与思考：四维框架

100-500字，四段式。这是全文的收束——**不是前面证据的概括重复**，而是综合所有证据后的判断和反思：

1. **临床建议** — 基于现有证据，今天临床实践该怎么做？不给虚话，给出具体可操作的建议
2. **矛盾与张力** — 证据之间有冲突吗？怎么理解和解释这种冲突？冲突本身可能意味着什么？
3. **盲区** — 目前最缺什么证据？缺的这个为什么重要？不是"需要更多研究"，而是"最缺X类型的证据，因为Y"
4. **人医启发** — 人医同领域的证据给了什么参照？有什么警示？有什么可以借鉴但必须谨慎的方向？

---

## 质检清单

交付前逐条自检：

- [ ] PICO拆解是否清晰？检索是否拆成了2-3个短查询（非一个长查询）？
- [ ] 关键词是否覆盖中英文+同义词+MeSH？
- [ ] 检索了PubMed + Semantic Scholar + 指南源？
- [ ] 人医参照是否检索并标注了来源域差异？
- [ ] 入选文献是否覆盖了主要临床维度？所有符合纳入标准的高质量文献是否全部保留？
- [ ] 每篇入选文献是否标注了证据强度+理由？
- [ ] 一句话结论是否≤80字且能独立传达核心信息？
- [ ] 证据矩阵表是否覆盖了主要临床维度？
- [ ] 分区证据卡片每张是否200-300字？
- [ ] 结论与思考是否回应了四维框架的每一问？
- [ ] 是否有触犯禁区（套话、空洞形容词、编造信息）？
- [ ] 是否对入选文献运行了 `fetch_fulltext.py`？
- [ ] 每篇文献的获取状态（全文/仅摘要）是否在报告中标注？
- [ ] 仅获取摘要的文献，摘要是否完整（非截断）且标注了获取限制？
- [ ] 所有文献标注了PMID/DOI？
- [ ] 检索时间和平台是否注明？
- [ ] 所有缩写首次出现是否用"中文（English Full Name, ABBR）"格式展述？
- [ ] PDF排版美观、矩阵表可读、证据强度标记清晰？
