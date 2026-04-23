# WTW Data Solutions - Codex Project Context

## What This Project Is

Central data engineering hub for WTW.
Full operating guidance: `AGENT_GUIDELINES.md`.
Shared workflows live in `.agent/workflows/`.

This Codex repo setup is derived from `CLAUDE.md` and keeps the project context local to this workspace.

## Stack

Python, PySpark, SQL, DAX, Power Query (M), HTML5/CSS, Microsoft Fabric, Power BI

## File Registry

| Layer | Folder | Files |
|---|---|---|
| Bronze | `Transformers/Alteryx-Migration/Fabric-Bronze/Billing/` | `src_Saiba_crb.m`, `src_arias_crb.m`, `src_eclipse_crb.m`, `src_eclipse_london.m`, `src_eglobal_income_report.m`, `src_eglobal_premium_report.m`, `src_gswin_crb.m` |
| Bronze | `Transformers/Alteryx-Migration/Fabric-Bronze/CRM/` | `01_bronze_pipeline_crm.json` |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/Chloe/` | `02_silver_notebook_eclipse.ipynb`, `02_silver_notebook_arias.ipynb`, `02_silver_notebook_gswin.ipynb`, `02_silver_notebook_saiba.ipynb`, `02_silver_notebook_eglobal.ipynb`, `ref_Chloe_eglobal_product_mapping.m` |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/Baseline/` | not started - ignore |
| Silver | `Transformers/Alteryx-Migration/Fabric-Silver/CRM/` | not started - ignore |
| Gold | `Transformers/Global-Loom/notebooks/facts/` | `03_gold_fact_transaction.ipynb`, `03_gold_fact_invoice.ipynb` |
| Gold | `Transformers/Global-Loom/notebooks/dimensions/` | `03_gold_dim_date.ipynb`, `03_gold_dim_policy.ipynb`, `03_gold_dim_party.ipynb`, `03_gold_dim_product.ipynb`, `03_gold_dim_geography.ipynb`, `03_gold_dim_financial_segment.ipynb`, `03_gold_dim_data_source.ipynb` |
| Gold | `Transformers/Global-Loom/notebooks/bridge/` | `03_gold_bridge_policy_party.ipynb` |
| Gold | `Transformers/Global-Loom/exploration/` | `00_explore_pas_silver.ipynb`, `00_explore_deep_dive.ipynb` |
| Gold | `Transformers/Global-Loom/docs/` | `INDEX.md`, `EXECUTIVE_SUMMARY.md`, `ACTION_ITEMS.md`, `FILE_STRUCTURE.md`, `OPTIMIZATION_SUMMARY.md`, `00_data_exploration_results.md`, `01_star_schema_plan.md`, `02_validation_summary.md`, `03_source_table_audit.md` |
| Source | `Transformers/Alteryx-Migration/Source-Analysis/` | Original Alteryx `.yxmd` |

## Naming Conventions

- ETL artifacts: `[SS]_[layer]_[action]_[subject]`
- Bronze tables: `src_[source]_[content]`
- Silver tables: `clean_[content]` or `master_[entity]`
- Gold tables: `fact_[process]`, `dim_[context]`
- Reference tables: `ref_Chloe_[subject]_[type]`
- Final Fabric columns: `PascalCase`
- Variables and functions: `camelCase`
- DAX vars: `_camelCase`

## Critical Coding Rules

- Fabric notebooks: always `.ipynb`, never `.py`
- In `.ipynb`, the `source` field must be an array of strings, not a single string
- Spark SQL pattern: `spark.sql("SELECT * FROM LakehouseName.Table_Name")`
- Join keys: always `F.trim(F.upper())` on both sides
- Special-character columns must be backtick-quoted
- Safe numeric M conversion: `each try Number.From(_) otherwise 0, type nullable number`
- Same-workspace writes: use `.saveAsTable("LakehouseName.table_name")`
- Cross-workspace writes: use `.save(TARGET_PATH)` with `abfss://...`
- CRM SQL: no CTEs
- Fabric SQL: CTEs are OK
- No emojis in Python, PySpark, SQL, DAX measure code, notebook markdown headers, or comments

## MCP Servers

- `powerbi-modeling` - Read/write tables, measures, DAX, and TMDL

## Design Context

Audience: mixed daily analysts and executive stakeholders.
Tone: premium consulting deliverable.
Theme: light mode only.

Brand colors:

- Primary: `#7F35B2`
- Outstanding: `#16A34A`
- Met: `#22C55E`
- Near: `#F59E0B`
- Below: `#EF4444`
- Critical: `#DC2626`
- Text: `#1E1B4B`
- Body: `#374151`
- Muted: `#6B7280`
- Border: `#E5E7EB`
- Surface: `#F9FAFB`
- Canvas: `#FFFFFF`

Design principles:

1. Data first, chrome last.
2. Purple is the signal, white is the canvas.
3. Density with breathing room.
4. Hierarchy through weight before colour.
5. Corporate credibility over novelty.

## Task Routing

Load these repo-local Codex skill copies when the task matches:

| Trigger | Load |
|---|---|
| fabric, pyspark, delta, bronze, silver, gold, lakehouse, notebook, abfss | `.codex/skills/fabric-de/SKILL.md` |
| DAX, measure, KPI, HTML card, Power BI | `.codex/skills/wtw-powerbi/SKILL.md` |

Shared non-skill workflows remain in:

- `.agent/workflows/alteryx-migration.md`
- `.agent/workflows/global-loom.md`
