# WTW Data Solutions — Claude Project Context

## What This Project Is

Central data engineering hub for WTW.
Full guidelines: `AGENT_GUIDELINES.md`. Workflows: `.agent/workflows/`.

> **Skills note**: Both Antigravity (`.agent/skills/`) and Claude Code (`~/.claude/skills/`) use `wtw-powerbi` as the Power BI skill.
> Keep both copies in sync — same SKILL.md + references/ structure. Update both when making changes.

## Stack

Python · PySpark · SQL · DAX · Power Query (M) · HTML5/CSS · Microsoft Fabric · Power BI

## File Registry (current state)

| Layer | Folder | Files |
|---|---|---|
| Bronze | `Transformers/Alteryx-Migration/Fabric-Bronze/Billing/` | `src_Saiba_crb.m`, `src_arias_crb.m`, `src_eclipse_crb.m`, `src_eclipse_london.m`, `src_eglobal_income_report.m`, `src_eglobal_premium_report.m`, `src_gswin_crb.m` |
| Bronze | `Transformers/Alteryx-Migration/Fabric-Bronze/CRM/` | `01_bronze_pipeline_crm.json` (Fabric Data Pipeline) |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/Chloe/` | `02_silver_notebook_eclipse.ipynb`, `02_silver_notebook_arias.ipynb`, `02_silver_notebook_gswin.ipynb`, `02_silver_notebook_saiba.ipynb`, `02_silver_notebook_eglobal.ipynb`, `ref_Chloe_eglobal_product_mapping.m` |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/Baseline/` | *(not started — ignore)* |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/CRM/` | *(not started — ignore)* |
| Gold | `Transformers/Global-Loom/notebooks/facts/` | `03_gold_fact_transaction.ipynb`, `03_gold_fact_invoice.ipynb` |
| Gold | `Transformers/Global-Loom/notebooks/dimensions/` | `03_gold_dim_date.ipynb`, `03_gold_dim_policy.ipynb`, `03_gold_dim_party.ipynb`, `03_gold_dim_product.ipynb`, `03_gold_dim_geography.ipynb`, `03_gold_dim_financial_segment.ipynb`, `03_gold_dim_data_source.ipynb` |
| Gold | `Transformers/Global-Loom/notebooks/bridge/` | `03_gold_bridge_policy_party.ipynb` |
| Gold | `Transformers/Global-Loom/exploration/` | `00_explore_pas_silver.ipynb`, `00_explore_deep_dive.ipynb` *(Phase 0 — PAS profiling)* |
| Gold | `Transformers/Global-Loom/docs/` | `INDEX.md`, `EXECUTIVE_SUMMARY.md`, `ACTION_ITEMS.md`, `FILE_STRUCTURE.md`, `OPTIMIZATION_SUMMARY.md`, `00_data_exploration_results.md`, `01_star_schema_plan.md`, `02_validation_summary.md`, `03_source_table_audit.md` |
| Source | `Transformers/Alteryx-Migration/Source-Analysis/` | Original Alteryx `.yxmd` |

## Naming Conventions (strict)

- **ETL artifacts**: `[SS]_[layer]_[action]_[subject]` — e.g. `02_silver_notebook_eclipse.ipynb`
- **Bronze tables**: `src_[source]_[content]` — e.g. `src_saiba_policies`
- **Silver tables**: `clean_[content]` or `master_[entity]`
- **Gold tables**: `fact_[process]`, `dim_[context]`
- **Reference tables**: `ref_Chloe_[subject]_[type]`
- **Final Fabric columns**: `PascalCase` (no spaces or special chars)
- **Variables/Functions**: `camelCase` · **DAX vars**: `_camelCase`

## Critical Coding Rules

- Fabric notebooks: **always `.ipynb`**, never `.py`
- **CRITICAL - Notebook source format**: When editing `.ipynb` files, the `source` field MUST be an array of strings (one per line), NOT a single string. Fabric upload fails with 400 error otherwise.
  - Correct: `"source": ["line1\n", "line2\n", "line3"]`
  - Wrong: `"source": "line1\nline2\nline3"`
- Spark SQL: `spark.sql("SELECT * FROM LakehouseName.Table_Name")`
- Join keys: always `F.trim(F.upper())` on **both** sides — no exceptions
- Special-char columns: backtick-quote them — `` F.col("`COL NAME`") ``
- Safe numeric M conversion: `each try Number.From(_) otherwise 0, type nullable number`
- Write pattern: `df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable("table_name")`
- CRM SQL: **no CTEs**. Fabric SQL: CTEs OK.
- **No emojis in code**: No emojis in Python/PySpark, SQL, DAX measure code, print statements, notebook markdown headers, or comments. Emojis are allowed in Power BI HTML card visual output (status icons, badges rendered inside DAX string HTML).

## MCP Servers

- `powerbi-modeling` — Read/Write Tables, Measures, DAX, TMDL (v0.2.2, exe at `C:\MCP\powerbi-modeling-mcp\extension\server\powerbi-modeling-mcp.exe`)

## Design Context

**Audience**: Mixed — daily analysts + executive stakeholders.
**Personality**: Modern · Confident · Clear · Precise · Global
**Tone**: Premium consulting firm deliverable. Never playful, never default BI tool aesthetic.
**Primary outputs**: Power BI HTML cards and dashboard design.
**Theme**: Light mode only.

### Brand Colors
- Primary: `#7C3AED` (WTW Corporate Purple)
- Performance: Outstanding `#16A34A` · Met `#22C55E` · Near `#F59E0B` · Below `#EF4444` · Critical `#DC2626`
- Neutrals: Text `#1E1B4B` · Body `#374151` · Muted `#6B7280` · Border `#E5E7EB` · Surface `#F9FAFB` · Canvas `#FFFFFF`

### Design Principles
1. **Data first, chrome last** — every element earns its place by aiding comprehension
2. **Purple is the signal, white is the canvas** — use `#7C3AED` for hierarchy and accent only
3. **Density with breathing room** — tight meaning, but key numbers need space to land
4. **Hierarchy through weight before colour** — font size/weight first; colour for status only
5. **Corporate credibility** — looks senior-analyst-made, not AI-generated

### Anti-references (never produce)
- Generic Power BI defaults (blue bars, no hierarchy)
- Startup aesthetic (gradients, rounded blobs)
- Excel dump (wall of numbers, no whitespace)
- AI aesthetic (glowing gradients, neon, over-engineered cards, emojis)

> Full spec: `.impeccable.md` · Brand detail: `.agent/skills/wtw-powerbi/references/`

## Task Routing

| Trigger | Load |
|---|---|
| alteryx, migration, pyspark, notebook | `.agent/workflows/alteryx-migration.md` |
| global loom, PAS, gold layer, star schema | `.agent/workflows/global-loom.md` |
| DAX, measure, KPI, HTML card, Power BI | `.agent/skills/wtw-powerbi/SKILL.md` |
| xlsx, excel, csv | `.agent/skills/xlsx/SKILL.md` |
| pptx, slides, deck | `.agent/skills/pptx/SKILL.md` |
| docx, report, proposal | `.agent/skills/docx/SKILL.md` |
