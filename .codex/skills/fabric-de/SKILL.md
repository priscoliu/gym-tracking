---
name: fabric-de
description: Microsoft Fabric data engineering for WTW projects using PySpark notebooks, Delta Lake, Bronze/Silver/Gold medallion layers, Fabric Lakehouses, cross-workspace abfss writes, Power Query handoff patterns, and naming standards. Use when building, editing, reviewing, or troubleshooting Fabric notebooks, lakehouse tables, medallion pipelines, reference joins, or Fabric-specific ETL logic.
---

# WTW Fabric Data Engineering

Use this skill for Microsoft Fabric engineering work in this repository.

Bias toward notebook-safe, Lakehouse-aware, naming-consistent solutions that match the WTW medallion approach already used here.

## Non-Negotiables

- Use `.ipynb` for Fabric notebooks, never `.py`
- In notebook JSON, keep each cell `source` as an array of strings, one line per element
- Apply `F.trim(F.upper(...))` on both sides of join keys when joining business text fields
- Backtick-quote special-character column names
- Cast before aliasing in final selects
- Use `PascalCase` for final Fabric output columns
- Do not use emojis in notebook code, SQL, markdown headers, comments, or DAX code

## Naming Standards

- ETL artifacts: `[SS]_[layer]_[action]_[subject].ipynb`
- Bronze tables: `src_[source]_[content]`
- Silver tables: `clean_[content]` or `master_[entity]`
- Gold tables: `fact_[process]` and `dim_[context]`
- Reference tables: `ref_Chloe_[subject]_[type]`
- Python variables and functions: `camelCase`
- DAX variables: `_camelCase`

## Medallion Model

### Bronze

- Prefix: `01`
- Purpose: raw ingestion with minimal or no transformation

### Silver

- Prefix: `02`
- Purpose: standardise, clean, dedupe, enrich

### Gold

- Prefix: `03`
- Purpose: star-schema-ready facts, dimensions, and bridges

## Notebook Build Order

1. Write the markdown header with purpose, inputs, outputs, and mapping notes.
2. Define imports, constants, table names, and target paths.
3. Load source data and inspect with schema, sample rows, and counts.
4. Apply type casting first.
5. Apply transforms, unions, and standardisation.
6. Join reference data using normalised keys.
7. Select final columns in the required order.
8. Write output and validate row count and shape.

## Write Rules

Choose the write method based on workspace location.

### Same workspace

Use `saveAsTable("LakehouseName.table_name")`.

### Cross-workspace

Build an `abfss://` target path and use `.save(TARGET_PATH)`.

After cross-workspace writes:

- read the table back
- validate row count
- validate a small sample

## Common PySpark Patterns

### Join normalisation

```python
df.join(
    dfRef,
    F.trim(F.upper(df["SourceKey"])) == F.trim(F.upper(dfRef["RefKey"])),
    "left"
)
```

### Special-character columns

```python
F.col("`COL NAME`")
```

### Null-safe numeric pattern

```python
F.coalesce(F.col("amount"), F.lit(0.0))
```

### Final select

```python
dfFinal = df.select(
    F.col("source_col").cast(StringType()).alias("PascalCaseName")
)
```

## Chloe Silver Standard

For Chloe Silver outputs, preserve the shared standard column order before writing when the notebook belongs to that flow.

If the user is working in Chloe pipelines, check the existing notebooks or shared source skill for the full standard column list before modifying the final select.

## SQL and M Rules

- CRM SQL: do not use CTEs
- Fabric SQL: CTEs are acceptable
- Spark SQL pattern: `spark.sql("SELECT * FROM LakehouseName.Table_Name")`
- Safe numeric Power Query conversion: `each try Number.From(_) otherwise 0, type nullable number`

## Fabric CLI

If Fabric CLI is available, prefer it for inspection tasks such as:

- auth status
- workspace discovery
- item lookup
- lakehouse table listing
- notebook runs
- import and export

Use `fab` commands carefully and prefer read operations unless the user asks to deploy or execute.

## Shared Source Material

Use the existing repo material when you need deeper detail:

- `.agent/skills/fabric-de/workflow-data-exploration.md`
- `.agent/skills/fabric-de/workflow-medallion.md`
- `.agent/skills/fabric-de/SKILL.md`
- `AGENT_GUIDELINES.md`

## WTW Workspace Context

This repo already centers around:

- APAC Sales Operations
- Bronze, Silver, and Gold Lakehouses
- Chloe Silver notebooks
- Global Loom Gold modeling

When details are unclear, inspect nearby notebooks and existing naming patterns before inventing a new convention.

## Final Checks

Before finishing:

- confirm the notebook stays as valid `.ipynb`
- confirm joins normalise both sides
- confirm output naming matches the target layer
- confirm writes match the destination workspace pattern
- confirm the final table shape and column order are intentional
