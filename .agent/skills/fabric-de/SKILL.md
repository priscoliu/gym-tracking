---
name: fabric-de
description: Use when building, editing, or reviewing Microsoft Fabric Data Engineering work — PySpark notebooks, Delta Lake writes, Bronze/Silver/Gold lakehouse layers, cross-workspace abfss paths, reference joins, naming conventions, or any Fabric-specific PySpark pattern
---

# WTW Fabric Data Engineering

## Workflows

| Workflow | When to use |
|----------|-------------|
| [workflow-data-exploration.md](workflow-data-exploration.md) | Starting a new project — profiling source tables, understanding grain, validating FK integrity, building the decision log before any schema design |
| [workflow-medallion.md](workflow-medallion.md) | Building Bronze, Silver, or Gold layer notebooks — cell structure, build order, star schema design, post-execution validation |

---

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

---

## Fabric CLI (`fab`)

**Install**: `pip install ms-fabric-cli` — command is `fab`

### Auth

```bash
fab auth status          # check current login
fab auth login           # authenticate (browser prompt)
fab auth logout
```

### Navigation

```bash
fab dir                                          # list all accessible workspaces
fab dir "WorkspaceName.Workspace"               # list all items in a workspace
fab get "WorkspaceName.Workspace" -q .          # full workspace JSON (id, settings, roles)
fab get "WorkspaceName.Workspace/Item.Type" -q id   # get a single property
fab pwd                                          # show current working path
fab cd "WorkspaceName.Workspace"                # change working directory
```

### Items

```bash
fab get "WS.Workspace/LH.Lakehouse" -q .        # lakehouse properties
fab table list "WS.Workspace/LH.Lakehouse"      # list Delta tables in lakehouse
fab job run "WS.Workspace/NB.Notebook"          # trigger notebook run
fab import <local_path> "WS.Workspace"          # deploy artifact to workspace
fab export "WS.Workspace/Item.Type" <local_path>  # export item definition
fab open "WS.Workspace/Item.Type"               # open in browser
```

**Item types used as path suffixes**: `.Workspace` `.Lakehouse` `.Notebook` `.DataPipeline` `.Dataflow` `.Report` `.SemanticModel` `.SQLEndpoint` `.CopyJob`

**Output tip**: Use `-q .` for full JSON, `-q id` for a single field, `-q "field.nested"` for nested fields (JMESPath syntax).

---

## WTW Reference — APAC Sales Operations

### Workspace

| Property | Value |
| --- | --- |
| Name | APAC Sales Operations |
| Workspace ID | `76ec20c3-c400-415a-99c6-708f8207d5f9` |
| OneLake DFS endpoint | `onelake.dfs.fabric.microsoft.com` |
| Region | Southeast Asia |
| Admins | Prisco Liu · Jun Shun Ng · Christopher Meyer · Prashant Poojari |

### Key Lakehouses

| Lakehouse | ID | Layer | Role |
| --- | --- | --- | --- |
| `APAC_CRM_Analytics_LH` | `1c0d3357-c170-4ddd-9738-e1c90bbe99f2` | Bronze | CRM + billing source data |
| `APAC_Reporting_LH` | `34b6eb71-e1ed-4b06-832f-38346b869a1c` | Silver | Chloe Silver outputs |
| `The_Global_Loom` | `2d1524ac-d471-4885-aedf-cd7ee45ba05e` | Gold | Star schema reporting layer |
| `Bronze_Marketing_LH` | `0ebd6604-a5db-4624-b535-497cd55663c1` | Bronze | Marketing data |
| `Silver_Marketing_LH` | `02c29258-772c-45bc-a7a4-2ff0eac5d43f` | Silver | Marketing cleaned |

Cross-workspace abfss path template (writing to this workspace from another workspace):

```python
WORKSPACE_ID = "76ec20c3-c400-415a-99c6-708f8207d5f9"
LAKEHOUSE_ID = "<see table above>"
TARGET_PATH = f"abfss://{WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/{LAKEHOUSE_ID}/Tables/dbo/{TABLE_NAME}"
```

### Notebooks — full inventory

| Name | Layer | Purpose |
| --- | --- | --- |
| `00_explore_pas_silver` | Explore | Phase 0 PAS data profiling |
| `02_silver_notebook_arias` | Silver | Arias → clean_arias_chloe |
| `02_silver_notebook_Eclipse` | Silver | Eclipse → clean_eclipse_chloe |
| `02_silver_notebook_eglobal` | Silver | Eglobal → clean_eglobal_chloe |
| `02_silver_notebook_gswin` | Silver | GSwin → clean_gswin_chloe |
| `02_silver_notebook_saiba` | Silver | Saiba → clean_saiba_chloe |
| `03_gold_fact_transaction` | Gold | Fact: transactions |
| `03_gold_fact_invoice` | Gold | Fact: invoices |
| `03_gold_dim_date` | Gold | Dim: date |
| `03_gold_dim_policy` | Gold | Dim: policy |
| `03_gold_dim_party` | Gold | Dim: party |
| `03_gold_dim_product` | Gold | Dim: product |
| `03_gold_dim_geography` | Gold | Dim: geography |
| `03_gold_dim_financial_segment` | Gold | Dim: financial segment |
| `03_gold_dim_data_source` | Gold | Dim: data source |
| `03_gold_bridge_policy_party` | Gold | Bridge: policy ↔ party |
| `APAC Sales Model` | ? | Outside naming convention — needs review |
| `CRB Transformation` / `CRB MR Transformation` | ? | CRB — outside naming convention |
| `_HWC_IAPhasing` | ? | HWC project — non-standard prefix |

### Pipelines

| Name | Convention | Notes |
| --- | --- | --- |
| `01_bronze_ingest_CRM` | ✅ | D365 CRM ingestion |
| `APAC Dim Table Refresh` | ✗ | Refresh dims |
| `APAC Sales dashboard Pipeline` | ✗ | |
| `CRB Pipeline` / `CRB MR Pipeline` | ✗ | CRB refresh |
| `crm_bronze_ETL_allLobs_file` | ✗ | |
| `Get CRM Billing Data` | ✗ | |
| `Income Report Pipeline` | ✗ | |
| `_HWC_Data_Pipeline` | ✗ | HWC project |

### Known issues in workspace

| Item | Issue |
| --- | --- |
| `01_bronze_ingest_CRB_billing` + `01_bronze_ingestion_CRB_billing` | Likely duplicate — two items with near-identical names |
| `Get_ImcomeReport` dataflow | Typo — should be `Income` |
| `AsisClientManagementWorkspaceUsage` report | Typo — should be `Asia` |
| `StagingLakehouseForDataflows_*` (×2) + warehouses (×2) | Auto-created by Dataflows Gen2 — stale, can be cleaned up |
