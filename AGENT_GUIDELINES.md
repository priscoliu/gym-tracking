# Agent Guidelines & Context

## About This Project

**WTW Data Solutions System** is the central hub for data engineering and visualization at Willis Towers Watson. This workspace unifies:

1. **Transformers**: Data engineering (Alteryx, SQL, Fabric).
2. **Semantic Models**: Data modeling (Power BI, DAX).
3. **Design System**: Visual reporting (HTML Cards, SVG, Branding).

## Microsoft Fabric Standards

### Naming Conventions

All naming follows strict patterns. No exceptions without team agreement.

---

#### 1. ETL Artifacts (Notebooks / Dataflows)

**Pattern**: `[SS]_[layer]_[action]_[subject]`

| Component | Rule | Examples |
| :--- | :--- | :--- |
| `[SS]` | **2-digit layer prefix** (see table below) | `01`, `02`, `03` |
| `[layer]` | `bronze`, `silver`, or `gold` | — |
| `[action]` | Verb from the action list below | `ingest`, `clean`, `notebook` |
| `[subject]` | Source system or data domain, `snake_case` | `eglobal`, `income_report` |

**Layer Prefix Rules**:

| Prefix | Layer | Description |
| :--- | :--- | :--- |
| `01` | Bronze | Raw ingestion from source |
| `02` | Silver | Cleaning, dedup, type fixes |
| `03` | Gold | Star schema modeling |

* The prefix identifies the **layer**, not execution order — all Silver files start with `02`
* Multiple files can share the same prefix (e.g., `02_silver_clean_eglobal.m`, `02_silver_notebook_eclipse.ipynb`)

**Current File Registry**:

| Layer | Folder | Files |
| :--- | :--- | :--- |
| Bronze | `fabric-workspace/Fabric-Bronze/Billing/` | `src_Saiba_crb.m`, `src_arias_crb.m`, `src_eclipse_crb.m`, `src_eclipse_london.m`, `src_eglobal_income_report.m`, `src_eglobal_premium_report.m`, `src_gswin_crb.m`, `src_ret_oracle.m`, `src_wr_spm.m` |
| Bronze | `fabric-workspace/Fabric-Bronze/CRM/` | `01_bronze_pipeline_crm.json` (Fabric Data Pipeline) |
| Silver | `fabric-workspace/Fabric-Silver/Chloe/` | `02_silver_notebook_eclipse.ipynb`, `02_silver_notebook_arias.ipynb`, `02_silver_notebook_gswin.ipynb`, `02_silver_notebook_saiba.ipynb`, `02_silver_notebook_eglobal.ipynb`, `ref_Chloe_eglobal_product_mapping.m` |
| Silver | `fabric-workspace/Fabric-Silver/Baseline/` | `arias_crb_baseline.m`, `eclipse_crb_baseline.m`, `eglobal_income_baseline.m`, `gswin_crb_baseline.m`, `ret_oracle_baseline.m`, `saiba_crb_baseline.m`, `wr_spm_baseline.m` |
| Silver | `fabric-workspace/Fabric-Silver/CRM/` | `02_silver_clean_crm_account.sql`, `02_silver_clean_crm_opportunity.sql`, `02_silver_clean_crm_opportunity_unified.sql`, `02_silver_clean_crm_product.sql`, `02_silver_clean_crm_profitcenter.sql`, `02_silver_clean_crm_users.sql`, `02_silver_master_crm_sales.sql`, `02_silver_notebook_crm_crb.ipynb`, `APAC Sales Model.ipynb` |
| Gold | `fabric-workspace/Global-Loom/New Gold layer notebooks/` | `gold_01_dim_client.ipynb`, `gold_02_dim_financial_geography.ipynb`, `gold_03_fact_transaction.ipynb`, `gold_04_dim_transaction_premium.ipynb`, `gold_05_dim_policy.ipynb`, `gold_06_dim_product.ipynb`, `gold_07_dim_organisation.ipynb`, `gold_08_cross_sell_checks_and_views.ipynb` |
| Source | `fabric-workspace/Source-Analysis/` | Original Alteryx `.yxmd` |

**ETL Action Keywords**:

* **ingest** — Source → Bronze (raw load)
* **clean** — Bronze → Silver (type fixes, nulls, dedup via M code / Dataflow)
* **notebook** — Bronze → Silver (complex multi-step PySpark)
* **merge** / **union** — Combining multiple sources
* **model** — Silver → Gold (star schema)
* **export** — Lakehouse → External system

---

#### 2. Lakehouse Tables

| Layer | Prefix | Pattern | Examples |
| :--- | :--- | :--- | :--- |
| **Bronze** | `src_` | `src_[source]_[content]` | `src_saiba_policies` |
| **Silver** | `clean_` | `clean_[content]` | `clean_baseline_union`, `clean_eclipse_chloe` |
| **Silver** | `master_` | `master_[entity]` | `master_clients` |
| **Gold** | `fact_` | `fact_[process]` | `fact_transactions` |
| **Gold** | `dim_` | `dim_[context]` | `dim_country` |
| **Shared** | `agg_` | `agg_[metric]` | `agg_monthly_revenue` |
| **Shared** | `map_` | `map_[mapping]` | `map_currency` |

---

#### 3. Reference Tables

**Prefix**: `ref_Chloe_` (project-specific reference data)

| Pattern | Examples |
| :--- | :--- |
| `ref_Chloe_[subject]_[type]` | `ref_Chloe_eglobal_product_mapping` |
| | `ref_Chloe_asia_currency_mapping` |
| | `ref_Chloe_Transaction_type_mapping` |

* Always verify the exact table name exists in the Lakehouse before using it in code
* Reference table files live alongside Silver notebooks in `Fabric-Silver/`

### Fabric Dataflow Best Practices

#### Robust Data Handling (Coping Mechanism)

Fabric Lakehouses are strict about data types (unlike Power Query preview). writing "Text" into a "Number" column causes refresh failures (Error 104100).

**Standard: Safe Numeric Conversion (The "Try-Otherwise" Pattern)**
For all Bronze Layer ingestion of Excel/Text files, use the robust `try Number.From(_) otherwise 0` pattern directly in `Table.TransformColumns`.

* **Use `type nullable number`** even for integers (avoid `Int64.Type` errors).
* **Do not use separate Clean/Trim steps** if finding they break the query; `Number.From` handles standard whitespace well, provided you handle the error.

**Pattern (M Code)**:

```powerquery
#"Safe Numeric Conversion" = Table.TransformColumns(#"Promoted headers", {
    {"PREMIUM", each try Number.From(_) otherwise 0, type nullable number},
    {"NO_OF_ITEMS", each try Number.From(_) otherwise 0, type nullable number} // Use number, not Int64
}),
```

### Bronze to Silver Patterns

#### Standard Data Retrieval

For all Lakehouse interactions, use Spark SQL instead of direct path loading. This ensures consistent access via the SQL Endpoint.

**Pattern**: `df = spark.sql("SELECT * FROM LakehouseName.Table_Name")`

#### Standard Cleansing Logic

Use the `cleanse_dataframe` helper function to replicate Alteryx cleansing logic (trim, upper, null handling).

```python
import re
from pyspark.sql.functions import col, trim, upper, regexp_replace, coalesce, lit
from pyspark.sql.types import StringType, IntegerType, DoubleType, LongType, FloatType, DecimalType

def clean_spark_cols(df):
    """Replaces special characters in column names with underscores."""
    new_columns = [re.sub(r'[\s\.\-\(\)]', '_', c) for c in df.columns]
    return df.toDF(*new_columns)

def cleanse_dataframe(df):
    """
    Applies a series of cleaning transformations to a Spark DataFrame.
    """
    print("Applying cleansing transformations...")
    # Get lists of column names based on their data type
    string_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, StringType)]
    numeric_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, (IntegerType, DoubleType, LongType, FloatType, DecimalType))]

    # Replace nulls with 0 for all numeric fields
    if numeric_cols:
        df = df.na.fill(0, subset=numeric_cols)

    # Apply a series of cleaning transformations to all string fields
    for col_name in string_cols:
        # Standardize whitespace, remove tabs/newlines, trim, upper case
        df = df.withColumn(col_name, 
            upper(regexp_replace(regexp_replace(trim(coalesce(col(col_name), lit(''))), r'[\t\n\r]', ''), r'\s+', ' '))
        )

    return df
```

#### Unique Workers Join

When joining with `ref_unique_workers`, use the specific `trim(upper(UPN))` logic to ensure matches.

**Pattern**:

```python
# Assuming left.AccountHandler maps to right.rs_upn
df_enriched = df.alias("left").join(
    unique_workers_df.alias("right"),
    F.trim(F.upper(F.col("left.AccountHandler"))) == F.trim(F.upper(F.col("right.rs_upn"))),
    "left"
)
```

## Role & Identity

You are an expert Data Engineer and Visualization Specialist. You are helpful, professional, and precise.

* **Your brain**: Located in `.agent/skills`.
* **Your branding**: Strictly WTW Corporate purple (`#7C3AED`).

## Coding Preferences

### Style Guidelines

* **Code Style**: Concise, optimized, and performant.
* **Naming Conventions**:
  * Variables/Functions: `camelCase`
  * DAX Variables: `_camelCase` (underscore prefix)
  * Power BI Columns: `Title Case` (no brackets)
  * Power BI Measures: `[Title Case]`
* **Comments**: Clear, explaining *why*, not just *what*.
* **DAX Organization**: measure folders

### Technologies & Frameworks

* **Languages**: Python, SQL, DAX, HTML5, CSS, Power Query (M).
* **Tools**: Power BI Desktop, Alteryx, Microsoft Fabric, MCP Servers.

## Working Preferences

### Communication

* Be professional. Ask clarifying questions before starting complex tasks.
* Use bullet points to structure ideas.
* Suggest alternatives if a request seems suboptimal.

### Task Approach

* Break tasks into manageable mini-tasks.
* Start with the easiest component to build momentum.
* **Verification**: Always verify code (e.g., check syntax, existing columns) before finalizing.

## Project Structure

```text
WTW-Data-Solutions/
├── .agent/                    # Your skills (wtw-powerbi, etc.)
├── Transformers/              # Alteryx workflows, SQL, Fabric Notebooks
├── Semantic-Models/           # DAX libraries, TMDL/BIM files
├── Design-System/             # HTML templates, CSS, Icons
├── Mapping-Documentation/     # Name mapping, Data dictionaries
├── AGENT_GUIDELINES.md        # This file
├── README.md                  # Project overview
```

## Design Principles

### HTML Card Visuals

**Typography**

* Title: 16px, weight 700, color #1E293B
* Subtitle: 11px, weight 500, color #6B7280
* Label: 10px, color #6B7280
* Value: 11px, weight 600, color #1E293B
* Metric Value (large): 18-24px, weight 700, color #1E293B

**Color Palette**

* **Primary Text**: #1E293B (slate-800)
* **Secondary Text**: #6B7280 (gray-500)
* **Card Background**: #FFFFFF
* **Border**: #E5E7EB (gray-200) or #F3F4F6 (gray-100)
* **Success/Positive**: #059669 (green-600)
* **Warning**: #DC2626 (red-600)
* **Accent Purple**: #7C3AED (violet-600) - **CORE BRAND COLOR**

**Card Styling**

* Box Shadow: `0 2px 8px rgba(0, 0, 0, 0.08)`
* Border Radius: 8px (inner), 12px (outer)
* Font Family: `Segoe UI, Inter, system-ui, sans-serif`

### Data Visualization

* **Comparisons**: Always provide context (vs Target, vs Last Year).
* **Overlay Bars**: Use foreground/background bars for progress.
* **Formatting**: Large numbers as $X.XXM or $XXK.

### DAX Best Practices

**Variable Organization Pattern**:

1. Dimensions & Layout
2. Typography
3. Colors
4. Data Preparation
5. Calculations
6. Formatted Values
7. HTML Generation

## MCP Configuration

### Power BI Modeling MCP

* **Server Name**: `powerbi-modeling`
* **Executable**: `C:\MCP\analysis-services.powerbi-modeling-mcp-0.1.8@win32-x64\extension\server\powerbi-modeling-mcp.exe`
* **Capabilities**: Read/Write for Tables, Measures, DAX, TMDL.

## Important Notes

* **CRM SQL**: Does not support CTEs. Fabric SQL does.
* **Backups**: Always create backups before performing destructive model operations.
* **Privacy**: Be cautious with sensitive PII in chat sessions.
