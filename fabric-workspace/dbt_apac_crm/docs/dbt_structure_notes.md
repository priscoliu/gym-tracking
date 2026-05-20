# dbt Best-Practice Review — Notes for our project

Sources reviewed (dbt official docs):
1. [How we structure our dbt projects](https://docs.getdbt.com/best-practices/how-we-structure/1-guide-overview)
2. [Style guide — models](https://docs.getdbt.com/best-practices/how-we-style/1-how-we-style-our-dbt-models)
3. [Style guide — SQL](https://docs.getdbt.com/best-practices/how-we-style/2-how-we-style-our-sql)
4. [Style guide — YAML](https://docs.getdbt.com/best-practices/how-we-style/5-how-we-style-our-yaml)
5. [Style guide — Jinja](https://docs.getdbt.com/best-practices/how-we-style/4-how-we-style-our-jinja)
6. [Materialization best practices](https://docs.getdbt.com/best-practices/materializations/1-guide-overview)
7. [Don't nest your curlies](https://docs.getdbt.com/best-practices/dont-nest-your-curlies)
8. [Writing custom generic data tests](https://docs.getdbt.com/best-practices/writing-custom-generic-tests)

Review date: 2026-05-20
Project: APAC CRM dbt (Bronze Lakehouse → Silver views → Gold star schema → Power BI)

---

## Core dbt principle

> Move data from **source-conformed** (shaped by external systems) to **business-conformed** (shaped by business definitions).

Three layers: **Staging → Intermediate → Marts**

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
- ✅ Cascade defaults in `dbt_project.yml`
- ✅ Tests + docs per folder in `schema.yml`
- ✅ Folder-based selection over tags

### Mart practices
- ✅ Materialize as tables
- ✅ Test PKs with `unique` + `not_null`

### Materialization strategy
- ✅ Progressive: **View → Table → Incremental** (only escalate when needed)
- ✅ Staging = view, Marts = table

### SQL style
- ✅ Lowercase SQL keywords (`select`, `from`, `where`)
- ✅ CTE pattern with logical names
- ✅ `select * from renamed` at end

---

## ⚠️ Major deviations from dbt style — and why we keep them

These are **deliberate decisions driven by Power BI being the consumer**:

### 1. Column casing — PascalCase vs snake_case

| dbt official | Ours | Why we differ |
|---|---|---|
| `account_id`, `customer_name` (snake_case) | `AccountId`, `AccountName` (PascalCase) | Power BI semantic model convention; matches Kimball style and existing dashboards |

**Rule:** Bronze → snake_case (D365 native), Staging → cast to PascalCase, Marts → keep PascalCase.

### 2. Pluralization — `orders` vs singular

| dbt official | Ours | Why we differ |
|---|---|---|
| `stg_orders`, `customers` (plural) | `stg_crm_account`, `stg_crm_opportunity` (singular) | Singular matches D365 entity names; matches existing Power BI tables |

### 3. PK naming — `<object>_id` vs PascalCase

| dbt official | Ours | Why we differ |
|---|---|---|
| `customer_id` | `AccountId`, `OpportunityId` | Power BI relationship column naming |

### 4. Timestamp naming — `<event>_at` vs `CreatedOn`

| dbt official | Ours | Why we differ |
|---|---|---|
| `created_at`, `updated_at` (event + at) | `CreatedOn`, `ModifiedOn` | Preserves D365 column semantics; recognized by users coming from CRM |

### 5. Marts: star schema vs wide tables

- **dbt official:** Wide denormalized tables — *"storage is cheap, compute is expensive"*
- **Ours:** Star schema (`fct_*`, `dim_*`)
- **Why:** Power BI's relationship engine and DAX measures are designed for star schema. Wide tables hurt the semantic model.

### 6. Mart naming: prefixed vs plain

- **dbt official:** Plain English entity names (`orders.sql`)
- **Ours:** `fct_transaction.sql`, `dim_client.sql` (per project CLAUDE.md)
- **Why:** Kimball / Power BI convention. Immediate clarity on facts vs dimensions.

### 7. Single underscore in staging — `stg_crm_account` vs `stg_jaffle_shop__customers`

- **dbt official:** Double underscore separates source from entity
- **Ours:** Single underscore (folder structure provides grouping)
- **Why:** Only one source (D365) for now; folder disambiguates

---

## 🆕 New patterns to adopt going forward

### Folder structure — restructure staging by source

Current: flat `models/staging/` with all 14 files.

Future-proof: group by source for when Marketing/Billing are added.

```
models/staging/
└── crm/
    ├── _crm__sources.yml
    ├── _crm__models.yml
    └── stg_crm_*.sql (× 14)
```

### SQL style adjustments (low-cost wins)

| Rule | Current | Should be |
|---|---|---|
| Line length max 80 chars | mostly OK | enforce |
| Indent 4 spaces | varies | 4 spaces consistent |
| Trailing commas | present | keep |
| Comments separate column groupings by type | absent | add `-- ids`, `-- strings`, `-- numerics` |
| Be explicit: `inner join` not `join` | OK | keep |
| `union all` not `union` | N/A yet | apply when intermediate uses union |
| Prefix columns when joining multiple tables | apply at intermediate | mandatory |
| No table aliases (avoid `c` for `customers`) | already verbose | keep |

### Jinja style

- 2 spaces inside `{{ }}` — `{{ source('bronze', 'src_crm_account') }}` ✓
- 4-space indent inside Jinja blocks
- Don't worry about whitespace control

### YAML style

- 2 spaces indent
- Lines max 80 chars
- Explicit list format even for single entries
- Recommended: install [Prettier](https://prettier.io/) for auto-format

### "Don't nest your curlies"

Inside a `{{ ... }}` expression, **never use another `{{ ... }}`**. Use the function/variable directly.

```sql
-- ✅ correct
{{ dbt_utils.date_spine(start_date=var('start_date')) }}

-- ❌ wrong (passes literal string)
{{ dbt_utils.date_spine(start_date="{{ var('start_date') }}") }}
```

Only exception: hooks (`on-run-start`, `post-hook`).

---

## ❌ What doesn't apply to our case (skip)

| Practice | Why skip |
|---|---|
| `base/` subdirectories for delete tables / unions | No delete tables. ANZ vs APAC leads collapse done in Bronze. |
| Source subdirectories (`jaffle_shop/`, `stripe/`) | Single source — will adopt when Marketing/Billing come in |
| Snapshots (Type 2 SCD) | Bronze Upsert handles current needs |
| dbt Mesh / project splitting | Tiny project (~50 models max) |
| Department subfolders in marts | Single domain (sales) — skip until > 10 marts |
| `dbt-codegen` for auto-generating staging | 14 tables manageable manually |
| Custom generic tests | Built-in `unique/not_null/accepted_values/relationships` cover our needs |

---

## DAG philosophy (worth remembering)

> "Narrow the DAG, widen the tables."

- ✅ Multiple **inputs** to a model = good
- ❌ Multiple **outputs** from a model = red flag

Goal: fewer, wider, richer intermediate concepts feeding into flexible marts.

---

## Materialization decision tree (from official docs)

```
Start: View
  │
  ▼
Query too slow for users? → Convert to Table
  │
  ▼
Table build too slow? → Convert to Incremental
```

**Don't pre-optimize.** Default everything to view, escalate only when measured pain justifies it.

| Layer | Materialization |
|---|---|
| Staging | View (no storage; always fresh) |
| Intermediate | Ephemeral (default) or View in dev schema (for easier debugging) |
| Marts | Table (or Incremental if rebuild becomes slow) |
| Snapshots | Special (managed by dbt) |

---

## 📋 Concrete action items

1. **Now:** Restructure `models/staging/` → `models/staging/crm/` subdirectory
2. **Now:** Split `schema.yml` → `_crm__sources.yml` + `_crm__models.yml`
3. **As we write intermediate:** add `-- ids / -- strings / -- numerics` column-group comments
4. **As we write intermediate:** group by business concept (`models/intermediate/sales_pipeline/`)
5. **Document deviations** explicitly in CLAUDE.md (Power BI consumer requires star schema + PascalCase)
6. **When adding 2nd source:** Marketing → `models/staging/marketing/`, etc.
