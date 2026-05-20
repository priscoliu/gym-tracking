# dbt Project Structure — Review Notes

Source: [dbt official guide on project structure](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview)

Review date: 2026-05-20
Project: APAC CRM dbt (Bronze Lakehouse → Silver views → Gold star schema → Power BI)

---

## Core dbt principle

> Move data from **source-conformed** (shaped by external systems) to **business-conformed** (shaped by business definitions).

Three layers handle this arc:
- **Staging** — atomic building blocks, 1:1 with sources
- **Intermediate** — purpose-built transformation steps (joins, pivots)
- **Marts** — business-defined entities

---

## ✅ What we already do that matches official guidance

### Staging layer
- ✅ One staging model per source table (14 Bronze → 14 staging)
- ✅ Only `{{ source() }}` macro in staging
- ✅ Light transformations only: type casting, renaming, simple computed columns
- ✅ No joins, no aggregations
- ✅ Pattern: `with source as (...) → renamed as (...) → select * from renamed`
- ✅ Materialized as **views**

### Project organization
- ✅ Cascade defaults in `dbt_project.yml` (staging → view, marts → table)
- ✅ Tests + docs per folder in `schema.yml`
- ✅ Folder-based selection over tags

### Mart practices
- ✅ Materialize as tables
- ✅ Test PKs with `unique` + `not_null`

---

## ⚠️ Where we deviate — and why it's justified

### Naming convention

| dbt official | Ours | Why we differ |
|---|---|---|
| `stg_jaffle_shop__customers` (double underscore, plural) | `stg_crm_account` (single underscore, singular) | Single source (D365); singular matches D365 entity names; consistent with existing Power BI semantic model |

### Mart structure: star schema vs wide tables

- **dbt official:** Wide denormalized tables — *"storage is cheap, compute is expensive"*
- **Ours:** Star schema (`fct_*`, `dim_*`)
- **Why:** Power BI is the consumer. Power BI's relationship engine and DAX measures are designed for star schema. Wide tables hurt the semantic model. This is a deliberate architectural decision driven by the consumer tool.

### Mart naming: prefixed vs plain

- **dbt official:** Plain English entity names (`orders.sql`)
- **Ours:** `fct_transaction.sql`, `dim_client.sql` (per project CLAUDE.md)
- **Why:** Power BI / Kimball convention. Makes facts vs dimensions immediately clear for measure modeling.

---

## ❌ What doesn't apply to our case (skip)

| Practice | Why skip |
|---|---|
| `base/` subdirectories for delete tables / unions | No delete tables. ANZ vs APAC leads collapse already done in Bronze. |
| Source subdirectories (`jaffle_shop/`, `stripe/`) | Single source (D365). Reconsider when we onboard other LOBs. |
| Snapshots (Type 2 SCD) | Bronze Upsert handles current needs. Add when historical tracking is required. |
| dbt Mesh / project splitting | Tiny project (~50 models max). Mesh is for 1000+ model projects. |
| Department subfolders in marts | Single domain (sales). Skip until we exceed ~10 marts. |
| `dbt-codegen` for auto-generating staging | 14 tables is manageable manually. Worth installing when we add more sources. |

---

## 🤔 Open decisions

### Intermediate layer materialization

- **dbt default:** Ephemeral (interpolated into downstream models)
- **dbt recommended:** View in a custom schema for easier debugging
- **Our current:** View in same schema as staging
- **Recommendation:** Keep as view. If int models get hard to debug, move to a `dev_intermediate` schema.

### Single `schema.yml` vs split files

- **dbt:** `_jaffle_shop__sources.yml` + `_jaffle_shop__models.yml` (one file per topic)
- **Ours:** Single `schema.yml` (combines sources + models)
- **Trade-off:** Their pattern scales better; ours is simpler for one source
- **Recommendation:** Keep single file until we exceed ~30 models in staging

---

## 📋 Action items as we build out

1. **Keep current naming** — document the why in CLAUDE.md
2. **Intermediate layer** — group by business concept (e.g., `models/intermediate/sales_pipeline/`)
3. **Marts** — flat structure for now (single domain)
4. **When adding a second source** — restructure staging into source-named subdirectories
5. **When intermediate gets complex** — consider custom schema for easier debugging

---

## DAG philosophy (worth remembering)

> "Narrow the DAG, widen the tables."

- ✅ Multiple **inputs** to a model = good (bringing components together)
- ❌ Multiple **outputs** from a model = red flag (model serving too many purposes)

Goal: fewer, wider, richer intermediate concepts feeding into flexible marts.
