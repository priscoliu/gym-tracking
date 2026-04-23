# Workflow: Data Exploration (Phase 0)

Use this before designing any Gold layer or new lakehouse schema. The goal is **decisions, not observations**. Every query should answer a specific question that blocks a design choice.

---

## The 5 Questions That Must Be Answered

| Question | Why |
|----------|-----|
| What is the grain of each table? One row = one what? | Determines fact vs dim candidates |
| Where do the financial columns live? | Often NOT the header/envelope table |
| What is the FK integrity between parent and child tables? | Zero orphans = safe to design around |
| What is the coverage? Which tables span all data sources? | Narrow coverage = defer to Phase 2 |
| Which columns are CONSTANT (0–1 distinct values)? | Drop them — they add no information |

---

## Notebook Setup

**Naming**: `00_explore_[subject].ipynb` — always `00_`, never a Silver or Gold prefix.

**Spark config** (required for tables with pre-1900 timestamps — party, policy, bridge):
```python
from pyspark.sql import functions as F
from pyspark.sql.types import *
from pyspark.sql import Row
from collections import defaultdict

spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "CORRECTED")
spark.conf.set("spark.sql.parquet.int96RebaseModeInRead", "CORRECTED")
```

**Table registry** (always use schema-qualified names — never bare table names):
```python
REF_TABLES = {
    "CarrierHierarchy":             "ref.CarrierHierarchy",
    "FinancialGeographyHierarchy":  "ref.FinancialGeographyHierarchy",
    "FinancialSegmentHierarchy":    "ref.FinancialSegmentHierarchy",
    "IndustryHierarchy":            "ref.IndustryHierarchy",
}
RPT_TABLES = {
    "vwTransaction":            "rpt.vwTransaction",
    "vwTransactionDetailUSD":   "rpt.vwTransactionDetailUSD",
    "vwPolicy":                 "rpt.vwPolicy",
    "vwParty":                  "rpt.vwParty",
    # add all source tables
}
ALL_TABLES = {**REF_TABLES, **RPT_TABLES}

def safe_read(table_name):
    qualified = ALL_TABLES.get(table_name, table_name)
    try:
        return spark.table(qualified)
    except Exception as e:
        print(f"Failed to read {qualified}: {e}")
        return None
```

---

## Cell Structure (run sequentially)

### Cell 1 — Table Discovery
```python
for schema_name in ["ref", "rpt", "dbo"]:
    print(f"Schema: {schema_name}")
    try:
        display(spark.sql(f"SHOW TABLES IN {schema_name}"))
    except Exception as e:
        print(f"  (not found: {e})")
```

### Cell 2 — Table Overview (row counts + column counts)
```python
results = []
for short_name, qualified_name in ALL_TABLES.items():
    df = safe_read(short_name)
    if df:
        results.append(Row(
            Schema="ref" if short_name in REF_TABLES else "rpt",
            Table=short_name,
            RowCount=df.count(),
            ColumnCount=len(df.columns)
        ))
        print(f"{short_name}: {df.count():,} rows x {len(df.columns)} cols")

overview_df = spark.createDataFrame(results)
display(overview_df.orderBy(F.desc("RowCount")))
```
Sort descending — the large tables are your fact candidates.

### Cell 3 — Schema Inspection
```python
for short_name in ALL_TABLES:
    df = safe_read(short_name)
    if df:
        print(f"\n{'='*60}\n{short_name} ({len(df.columns)} columns)\n{'='*60}")
        df.printSchema()
```
Share this output with your AI assistant. Never share raw data values.

### Cell 4 — Null Analysis
```python
for short_name in ALL_TABLES:
    df = safe_read(short_name)
    if df is None:
        continue
    total = df.count()
    null_exprs = [
        F.round((F.sum(F.when(F.col(c).isNull(), 1).otherwise(0)) / F.lit(total)) * 100, 1).alias(c)
        for c in df.columns
    ]
    null_pcts = df.select(null_exprs).collect()[0]
    print(f"\n{short_name} -- Null Analysis ({total:,} rows)")
    for c in df.columns:
        pct = null_pcts[c]
        if pct and pct > 0:
            print(f"  {c:<40} {pct:>6.1f}% null")
```

### Cell 5 — Cardinality Analysis
```python
for short_name in ALL_TABLES:
    df = safe_read(short_name)
    if df is None:
        continue
    total = df.count()
    distinct_exprs = [F.countDistinct(F.col(c)).alias(c) for c in df.columns]
    distinct_counts = df.select(distinct_exprs).collect()[0]

    print(f"\n{short_name} -- Cardinality ({total:,} rows)")
    for c in df.columns:
        dist = distinct_counts[c]
        ratio = dist / total if total > 0 else 0
        if ratio > 0.95:    tag = "UNIQUE KEY"
        elif ratio > 0.5:   tag = "HIGH"
        elif dist > 20:     tag = "MEDIUM"
        elif dist > 1:      tag = "LOW (dim candidate)"
        else:               tag = "CONSTANT -- drop candidate"
        print(f"  {c:<40} {dist:>10,} distinct  ({ratio:.1%})  {tag}")
```
CONSTANT columns (0–1 distinct values) carry no information — document them for removal.

### Cell 6 — Date Column Ranges
```python
for short_name in ALL_TABLES:
    df = safe_read(short_name)
    if df is None:
        continue
    date_cols = [f.name for f in df.schema.fields if isinstance(f.dataType, (DateType, TimestampType))]
    if not date_cols:
        continue
    print(f"\n{short_name} -- Date Columns")
    for col_name in date_cols:
        stats = df.select(
            F.min(col_name).alias("min"),
            F.max(col_name).alias("max"),
            F.countDistinct(col_name).alias("distinct"),
            F.sum(F.when(F.col(col_name).isNull(), 1).otherwise(0)).alias("nulls")
        ).collect()[0]
        print(f"  {col_name}: {stats['min']} -> {stats['max']}  |  {stats['distinct']:,} distinct  |  {stats['nulls']:,} nulls")
```
Flag impossible dates (far future, pre-1900, year 3000+) — DQ issues that need handling.

### Cell 7 — Shared Columns (FK Candidates)
```python
column_to_tables = defaultdict(list)
for short_name in ALL_TABLES:
    df = safe_read(short_name)
    if df:
        for col_name in df.columns:
            column_to_tables[col_name].append(short_name)

shared = {k: v for k, v in column_to_tables.items() if len(v) >= 2}
for col_name, tables in sorted(shared.items(), key=lambda x: len(x[1]), reverse=True):
    print(f"\n{col_name} (appears in {len(tables)} tables):")
    for t in tables:
        print(f"  -- {t}")
```
Columns appearing in 3+ tables are your primary join keys.

### Cell 8 — Sample Data
```python
for short_name in ALL_TABLES:
    df = safe_read(short_name)
    if df:
        print(f"\n{short_name} -- Sample (5 rows)")
        display(df.limit(5))
```
Review locally only. Never share raw data externally.

### Cell 9 — Deep Dive on Fact Candidates
Run targeted queries on the 2–3 tables that are primary fact candidates. See Deep Dive Queries below.

---

## Deep Dive Query Set

Run these on every primary fact candidate. Save each result as a JSON file.

```sql
-- 1. Grain validation: is the candidate PK truly unique?
SELECT
    COUNT(*)                    AS TotalRows,
    COUNT(DISTINCT CandidateId) AS UniqueIds,
    CASE WHEN COUNT(*) = COUNT(DISTINCT CandidateId)
         THEN 'UNIQUE' ELSE 'DUPLICATES EXIST' END AS Verdict
FROM rpt.vwTable;

-- 2. FK integrity: do all child rows have a matching parent?
SELECT COUNT(*) AS OrphanRows
FROM rpt.vwChild c
LEFT ANTI JOIN rpt.vwParent p ON c.ParentId = p.ParentId;

-- 3. Coverage: % of rows with a given FK populated (not NULL or -1)
SELECT
    COUNT(*) AS Total,
    SUM(CASE WHEN FkCol IS NOT NULL AND FkCol != -1 THEN 1 ELSE 0 END) AS HasValue,
    ROUND(SUM(CASE WHEN FkCol IS NOT NULL AND FkCol != -1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS CoveragePct
FROM rpt.vwTable;

-- 4. Fan-out distribution: how many child rows per parent?
SELECT
    CASE
        WHEN cnt = 1            THEN '1 row'
        WHEN cnt BETWEEN 2 AND 5   THEN '2-5 rows'
        WHEN cnt BETWEEN 6 AND 10  THEN '6-10 rows'
        WHEN cnt BETWEEN 11 AND 50 THEN '11-50 rows'
        ELSE '50+ rows'
    END AS Bucket,
    COUNT(*) AS ParentCount,
    SUM(cnt) AS TotalChildRows
FROM (
    SELECT ParentId, COUNT(*) AS cnt
    FROM rpt.vwChild
    GROUP BY ParentId
)
GROUP BY Bucket
ORDER BY ParentCount DESC;

-- 5. Data source coverage: how many DSIs does this table cover?
SELECT
    COUNT(DISTINCT DataSourceInstanceId) AS DSICount,
    COUNT(*) AS TotalRows
FROM rpt.vwTable;

-- 6. Financial column population: which columns actually have values?
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN GrossPremium IS NOT NULL THEN 1 ELSE 0 END) AS HasGrossPremium,
    ROUND(SUM(CASE WHEN GrossPremium IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS GrossPremiumPct
    -- repeat for each financial column
FROM rpt.vwTable;
```

---

## Evidence Rule

Save every deep dive result as a named JSON file in `exploration/results/`. Name by question, not by date:
- `Q1a_policy_uniqueness.json`
- `Q2b_transaction_invoice_coverage.json`
- `Q3b_detail_orphans.json`

These files are the audit trail for every architectural decision. When someone asks "why did you defer fact_invoice?" — the answer is in the JSON, not your memory.

---

## Decision Log (write after Phase 0)

After all queries are complete, write one sentence per table explaining what you decided and why. Examples:

> "Primary fact = vwTransaction + SUM(vwTransactionDetailUSD) — detail table is 471M rows, exceeds F16 limit for Power BI. Aggregate to 85M header grain."

> "fact_invoice deferred to Phase 2 — only 3/56 data sources, covers 9.5% of transactions."

> "Use PolicyId as dim_policy PK — 100% unique. PolicyKey is 72.6% unique, scoped within data source."

> "dim_geography from ref.FinancialGeographyHierarchy (1,082 rows) not rpt.vwFinancialGeography (31,019 rows) — fact FKs reference GlobalFinancialGeographyId, which maps to the ref table grain."

This decision log becomes the Phase 1 spec. Write it before touching any notebook.

---

## Profiling Checklist

- [ ] Row counts and column counts for all source tables
- [ ] Schemas shared with AI assistant
- [ ] Null % per column — CONSTANT columns identified
- [ ] Cardinality per column — unique keys confirmed
- [ ] Date column ranges — impossible dates flagged
- [ ] Shared columns mapped (FK candidates identified)
- [ ] Deep dive queries run on all fact candidates
- [ ] All results saved as named JSON files
- [ ] Decision log written for every table
- [ ] Fabric SKU capacity limit confirmed (F16 = 300M rows/table, ~1.5B total)
