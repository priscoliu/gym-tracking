---
name: fabric-de
description: Use when building, editing, or reviewing Microsoft Fabric Data Engineering work — PySpark notebooks, Delta Lake writes, Bronze/Silver/Gold lakehouse layers, cross-workspace abfss paths, reference joins, naming conventions, or any Fabric-specific PySpark pattern
---

# WTW Fabric Data Engineering

## Architecture — Medallion Layers

| Layer | SS | Table prefix | Purpose |
|-------|----|-------------|---------|
| Bronze | `01` | `src_[source]_[content]` | Raw ingestion — no transforms |
| Silver | `02` | `clean_[content]` / `master_[entity]` | Clean, dedupe, standardise |
| Gold | `03` | `fact_[process]` / `dim_[context]` | Star schema for reporting |
| Reference | — | `ref_Chloe_[subject]_[type]` | Lookup/mapping tables |

ETL artifact naming: `[SS]_[layer]_[action]_[subject].ipynb`
Actions: `ingest`, `clean`, `notebook`, `merge`, `union`, `model`, `export`

Always verify reference tables exist in Lakehouse before using.

---

## Notebook Standards

**Format**: Always `.ipynb` — never `.py`

**CRITICAL — `source` field**: Must be an array of strings (one element per line). Fabric upload fails with 400 error on single-string format.

```json
// Correct
"source": ["from pyspark.sql import functions as F\n", "import sys\n"]

// Wrong
"source": "from pyspark.sql import functions as F\nimport sys"
```

**No emojis**: Not in Python, SQL, DAX, print statements, markdown headers, or comments.
Emojis are only allowed inside Power BI HTML card string output (rendered in visuals).

---

## Cell Structure

1. **Markdown header** — notebook title, purpose, source table(s), output table(s), Alteryx tool mapping if applicable
2. **Setup & config** — imports, all table names as named constants, target path variables
3. **Load Bronze** — `printSchema()` + `display(df.limit(3))` + `df.count()`
4. **Transformations** — cast datatypes first, then transform
5. **Union** (if multiple streams) — standardise column names before union
6. **Reference joins** — TRIM+UPPER on both sides, drop temp join key after
7. **Write** — select STANDARD_COLUMNS, write, validate with row count

---

## Write Patterns

Choose based on destination workspace:

**Same workspace** (Lakehouse is attached to the notebook):
```python
df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable("LakehouseName.table_name")
```

**Cross-workspace** (target Lakehouse is in a different Fabric workspace):
```python
TARGET_WORKSPACE_ID = "..."   # Fabric workspace GUID
TARGET_LAKEHOUSE_ID = "..."   # Lakehouse GUID
TARGET_SCHEMA = "dbo"
TARGET_TABLE_NAME = "clean_source_chloe"
TARGET_PATH = (
    f"abfss://{TARGET_WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/"
    f"{TARGET_LAKEHOUSE_ID}/Tables/{TARGET_SCHEMA}/{TARGET_TABLE_NAME}"
)

df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").save(TARGET_PATH)

# Always validate after cross-workspace write
df_check = spark.read.format("delta").load(TARGET_PATH)
print(f"Rows written: {df_check.count()}")
print(f"Columns: {len(df_check.columns)}")
display(df_check.limit(5))
```

---

## PySpark Patterns

### Join keys — no exceptions, both sides
```python
df.join(
    df_ref,
    F.trim(F.upper(df["col"])) == F.trim(F.upper(df_ref["ref_col"])),
    "left"
)
```

### Special-character column names
```python
F.col("`COL NAME`")   # backtick-quote columns with spaces or special chars
```

### Null-safe numeric
```python
F.coalesce(F.col("amount"), F.lit(0.0)).cast(DoubleType())
```

### Final select — cast BEFORE alias
```python
df_final = df.select(
    F.col("source_col").cast(StringType()).alias("PascalCaseName"),
    F.coalesce(F.col("usd_amount"), F.lit(0.0)).cast(DoubleType()).alias("AmountUsd"),
)
```

---

## Reference Table Join Pattern

```python
# Prepare ref table with normalised join key
df_ref = df_ref_raw.select(
    F.upper(F.trim(F.col("JoinKey"))).alias("_join_key"),
    F.col("MappedValue1"),
    F.col("MappedValue2"),
)

# Join and drop temp key
df = df.join(
    df_ref,
    F.trim(F.upper(df["SourceKey"])) == df_ref["_join_key"],
    "left"
).drop("_join_key")
```

---

## Silver — Standard Column Set (Chloe layer)

All Chloe Silver notebooks standardise to this 28-column order before writing:

```python
STANDARD_COLUMNS = [
    "AccountHandler", "BrokerageUsd", "BusinessType", "ClientIdWtw", "ClientName",
    "DataSource", "Department", "DunsNumber", "ExpiryDate", "FinalDate",
    "Globs", "GlobsSplitPc", "InceptionDate", "InsurerCountry", "InsurerMapping",
    "InsurerName", "InvoiceDate", "InvoicePolicyNumber", "Lloyds", "PartyIdWtw",
    "PolicyDescription", "PremiumUsd", "ReinsuranceDescription", "RevenueCountry",
    "SubProductClass", "SystemId", "SystemProductId", "TransactionType",
]
df_final = df_final.select(*STANDARD_COLUMNS)
```

---

## Power Query (M) Patterns

Safe numeric conversion — always use this, never `Int64.Type`:
```powerquery
{"COL", each try Number.From(_) otherwise 0, type nullable number}
```

---

## SQL Rules

| Context | Rule |
|---------|------|
| CRM SQL (D365) | No CTEs |
| Fabric SQL (Lakehouse) | CTEs OK |
| Spark SQL | `spark.sql("SELECT * FROM LakehouseName.Table_Name")` |

---

## Naming Conventions

| Context | Convention | Example |
|---------|-----------|---------|
| Final Fabric output columns | `PascalCase` | `PremiumUsd`, `ClientName` |
| Python variables / functions | `camelCase` | `dfFinal`, `targetPath` |
| DAX variables | `_camelCase` | `_totalPremium` |
| Power BI columns | `Title Case` | `Policy Number` |
| Lakehouse table reference | `LakehouseName.table_name` | `APAC_CRM_Analytics_LH.src_saiba_crb` |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Single-string `source` in `.ipynb` | Array of strings, one element per line |
| Missing TRIM+UPPER on one side of join | Always on BOTH sides — no exceptions |
| `saveAsTable()` to a different workspace | Use `.save(TARGET_PATH)` with abfss path |
| Cast after `.alias()` | Cast BEFORE `.alias()` in final select |
| `Int64.Type` in Power Query | `type nullable number` always |
| Emojis in notebook code or headers | Only in Power BI HTML card string output |
| Non-standard column order in Silver | Apply STANDARD_COLUMNS before writing |
