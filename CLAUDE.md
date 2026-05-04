# WTW Data Solutions — Claude Project Context

## What This Project Is

Central data engineering hub for WTW.
Full guidelines: `AGENT_GUIDELINES.md`. Workflows: `.agent/workflows/`.

> **Skills note**: Both Antigravity (`.agent/skills/`) and Claude Code (`~/.claude/skills/`) use `wtw-powerbi` as the Power BI skill.
> Keep both copies in sync — same SKILL.md + references/ structure. Update both when making changes.

## Stack

Python · PySpark · SQL · DAX · Power Query (M) · HTML5/CSS · Microsoft Fabric · Power BI

## File Registry (current state)

All Fabric source files are now under `fabric-workspace/` at the project root.

| Layer | Folder | Files |
|---|---|---|
| Bronze | `fabric-workspace/Fabric-Bronze/Billing/` | `src_Saiba_crb.m`, `src_arias_crb.m`, `src_eclipse_crb.m`, `src_eclipse_london.m`, `src_eglobal_income_report.m`, `src_eglobal_premium_report.m`, `src_gswin_crb.m`, `src_ret_oracle.m`, `src_wr_spm.m` |
| Bronze | `fabric-workspace/Fabric-Bronze/CRM/` | `01_bronze_pipeline_crm.json` (Fabric Data Pipeline) |
| Silver | `fabric-workspace/Fabric-Silver/Chloe/` | `02_silver_notebook_eclipse.ipynb`, `02_silver_notebook_arias.ipynb`, `02_silver_notebook_gswin.ipynb`, `02_silver_notebook_saiba.ipynb`, `02_silver_notebook_eglobal.ipynb`, `ref_Chloe_eglobal_product_mapping.m` |
| Silver | `fabric-workspace/Fabric-Silver/Baseline/` | `arias_crb_baseline.m`, `eclipse_crb_baseline.m`, `eglobal_income_baseline.m`, `gswin_crb_baseline.m`, `ret_oracle_baseline.m`, `saiba_crb_baseline.m`, `wr_spm_baseline.m` |
| Silver | `fabric-workspace/Fabric-Silver/CRM/` | `02_silver_clean_crm_account.sql`, `02_silver_clean_crm_opportunity.sql`, `02_silver_clean_crm_opportunity_unified.sql`, `02_silver_clean_crm_product.sql`, `02_silver_clean_crm_profitcenter.sql`, `02_silver_clean_crm_users.sql`, `02_silver_master_crm_sales.sql`, `02_silver_notebook_crm_crb.ipynb`, `APAC Sales Model.ipynb`, `ref_legacy_cis_schema.md` |
| Gold | `fabric-workspace/Global-Loom/New Gold layer notebooks/` | `gold_01_dim_client.ipynb`, `gold_02_dim_financial_geography.ipynb`, `gold_03_fact_transaction.ipynb`, `gold_04_fact_transaction_premium.ipynb`, `gold_05_dim_policy.ipynb`, `gold_06_dim_product.ipynb`, `gold_07_dim_organisation.ipynb`, `gold_08_cross_sell_checks_and_views.ipynb` |
| Gold | `fabric-workspace/Global-Loom/Archieve files/` | Old v1 notebooks — archived, do not use |
| Gold | `fabric-workspace/Global-Loom/Docs/` | `2026-04-27-data-gaps.md`, `Gold_Layer_Documentation 1.md` |
| Source | `fabric-workspace/Source-Analysis/` | Original Alteryx `.yxmd` |

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
- Write pattern — **depends on destination workspace**:
  - **Same workspace** (Lakehouse attached to notebook): `.saveAsTable("LakehouseName.table_name")`
  - **Cross-workspace** (target in different workspace): `.save(TARGET_PATH)` where `TARGET_PATH = f"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/{SCHEMA}/{TABLE_NAME}"`
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
- Primary: `#7F35B2` (WTW Corporate Purple)
- Performance: Outstanding `#16A34A` · Met `#22C55E` · Near `#F59E0B` · Below `#EF4444` · Critical `#DC2626`
- Neutrals: Text `#1E1B4B` · Body `#374151` · Muted `#6B7280` · Border `#E5E7EB` · Surface `#F9FAFB` · Canvas `#FFFFFF`

### Design Principles
1. **Data first, chrome last** — every element earns its place by aiding comprehension
2. **Purple is the signal, white is the canvas** — use `#7F35B2` for hierarchy and accent only
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
| fabric, pyspark, delta, bronze, silver, gold, lakehouse, notebook, abfss | `.agent/skills/fabric-de/SKILL.md` |
| alteryx, migration, yxmd, alteryx workflow | `.agent/workflows/alteryx-migration.md` |
| global loom, PAS, star schema, fact, dim | `.agent/workflows/global-loom.md` |
| DAX, measure, KPI, HTML card, Power BI | `.agent/skills/wtw-powerbi/SKILL.md` |
| xlsx, excel, csv | `.agent/skills/xlsx/SKILL.md` |
| pptx, slides, deck | `.agent/skills/pptx/SKILL.md` |
| docx, report, proposal | `.agent/skills/docx/SKILL.md` |
