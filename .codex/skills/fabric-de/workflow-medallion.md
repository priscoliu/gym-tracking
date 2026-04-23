# Workflow: Medallion Layer Build

Reference for building Bronze, Silver, and Gold layer notebooks in Microsoft Fabric. Follow the phases in order. Never skip Phase 0 (data exploration) before designing Gold.

---

## Layer Summary

| Layer | Prefix | Table naming | Job |
|-------|--------|-------------|-----|
| Bronze | `01` | `src_[source]_[content]` | Raw ingestion — no transforms, no business logic |
| Silver | `02` | `clean_[content]` / `master_[entity]` | Clean, dedupe, standardise, enforce schema |
| Gold | `03` | `fact_[process]` / `dim_[context]` / `bridge_[rel]` | Star schema for Power BI + AI |

ETL artifact naming: `[SS]_[layer]_[action]_[subject].ipynb`

---

## Bronze Layer

**Job**: Land raw source data exactly as received. No transformations. No business logic. If source is wrong, Bronze is wrong — intentionally. It is the audit trail.

**Cell structure**:
1. Markdown header — source system, target table, pipeline/schedule
2. Setup & config — imports, source connection, target lakehouse + table name constants
3. Ingest — read from source, `printSchema()`, `display(df.limit(3))`, `df.count()`
4. Write raw — overwrite mode, no column changes

**Write**:
```python
df.write.format("delta").mode("overwrite").option("overwriteSchema", "true") \
    .saveAsTable("APAC_CRM_Analytics_LH.src_saiba_crb")
```

**Rules**:
- No column renaming, casting, or filtering in Bronze
- No joins to reference tables
- Preserve source column names exactly as they arrive

---

## Silver Layer (Chloe)

**Job**: Clean, deduplicate, standardise. Every source system lands as its own clean table with the same 28-column contract. Downstream Gold reads Silver — it must trust it completely.

**Cell structure**:
1. Markdown header — notebook name, source table(s), output table, Alteryx tool mapping
2. Setup & config — imports, all table names as named constants
3. Load Bronze — `printSchema()` + `display(df.limit(3))` + `df.count()`
4. Transformations — cast datatypes first, then transform (never the reverse)
5. Union (if multiple source streams) — standardise column names before union
6. Reference joins — TRIM+UPPER both sides, drop temp join key after
7. Write — select STANDARD_COLUMNS in order, write, validate row count

**Standard column contract** (all Chloe Silver notebooks must output these 28 columns in this order):
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

**Reference join pattern**:
```python
df_ref = df_ref_raw.select(
    F.upper(F.trim(F.col("JoinKey"))).alias("_join_key"),
    F.col("MappedValue"),
)
df = df.join(
    df_ref,
    F.trim(F.upper(df["SourceKey"])) == df_ref["_join_key"],
    "left"
).drop("_join_key")
```

**Write** (Silver usually writes cross-workspace to APAC_Reporting_LH):
```python
TARGET_WORKSPACE_ID = "76ec20c3-c400-415a-99c6-708f8207d5f9"
TARGET_LAKEHOUSE_ID = "34b6eb71-e1ed-4b06-832f-38346b869a1c"  # APAC_Reporting_LH
TARGET_PATH = (
    f"abfss://{TARGET_WORKSPACE_ID}@onelake.dfs.fabric.microsoft.com/"
    f"{TARGET_LAKEHOUSE_ID}/Tables/dbo/clean_saiba_chloe"
)
df_final.write.format("delta").mode("overwrite").option("overwriteSchema", "true").save(TARGET_PATH)

# Always validate after cross-workspace write
df_check = spark.read.format("delta").load(TARGET_PATH)
print(f"Rows written: {df_check.count():,}")
display(df_check.limit(5))
```

---

## Gold Layer

**Job**: Star schema for Power BI Direct Lake + AI agent access. Reads from Silver only. Never does cleaning — if something needs fixing, fix it upstream.

### Phase 0 — Explore First

See [workflow-data-exploration.md](workflow-data-exploration.md). Do not design the schema until Phase 0 is complete and a decision log is written.

---

### Phase 1 — Star Schema Design

**Grain decision**:
- One fact row = one measurable event (transaction, invoice, claim)
- If the lowest-grain source table exceeds Fabric SKU capacity, aggregate to a coarser header grain
- Keep full-grain data in the lakehouse only (for AI agent queries — not in Power BI semantic model)

**Aggregation pattern** (collapse detail to header grain):
```python
df_detail_agg = (
    df_detail_raw
    .groupBy("TransactionId")
    .agg(
        F.sum("GrossPremium").alias("GrossPremium"),
        F.sum("NetPremium").alias("NetPremium"),
        F.sum("GrossBrokerage").alias("GrossBrokerage"),
        F.sum("NetBrokerage").alias("NetBrokerage"),
        F.count("TransactionDetailId").alias("DetailRowCount"),
        # all financial columns via SUM
    )
)
df_fact = df_header.join(df_detail_agg, "TransactionId", "left")
# Coalesce all financials to 0 — some headers have no detail rows
```

**Star schema rules**:

| Decision | Rule |
|----------|------|
| Fact grain | One row = one measurable business event |
| Dimension keys | Use the database surrogate ID as PK — validate 100% uniqueness explicitly. Business keys are often DSI-scoped and not globally unique |
| Unknown member rows | Every dim needs a `-1` row. Without it, FK joins on sentinel values silently drop rows |
| Date keys | `YYYYMMDD` integer (`TransactionDateKey`) — enables role-playing date relationships in Power BI |
| Star vs snowflake | Prefer star — denormalize low-cardinality lookups into the parent dim. Power BI performs better with fewer joins |
| Many-to-many | Use a bridge table (e.g. `bridge_policy_party`) — never flatten M:M into the fact |
| Deferred tables | If a table covers <20% of data sources or <20% of rows, defer to Phase 2. Don't let partial data compromise the primary fact |
| Capacity planning | Confirm Fabric SKU limit before finalising row estimates. F16 = 300M rows/table, ~1.5B total model |

**Document every decision** — one line per table:
> "dim_geography from ref.FinancialGeographyHierarchy not rpt.vwFinancialGeography — fact FKs point to GlobalFinancialGeographyId which aligns to the ref table grain"

---

### Phase 2 — Build Order

Dependencies matter. Dims must exist before bridge; bridge must exist before fact.

```
Step 1 — Small dims (no dependencies, run in parallel):
  dim_date
  dim_data_source
  dim_financial_segment
  dim_geography
  dim_product
  dim_industry

Step 2 — Medium dims (may join ref tables, run after Step 1):
  dim_party

Step 3 — Large dims (run after Step 2, monitor runtime):
  dim_policy  ← 20M+ rows, can take 15+ min

Step 4 — Bridge (dims must exist first):
  bridge_policy_party

Step 5 — Fact (all dims and bridge must exist):
  fact_transaction  ← aggregates 471M detail rows, ~30 min
```

---

### Gold Notebook Cell Structure

Consistent across all Gold notebooks. Add cells, never remove or reorder.

**Dimension notebooks (7 cells)**:
```
Cell 1: Markdown header
  -- Notebook name, grain (one row = one X), source table(s), output table, row estimate

Cell 2: Setup & config
  -- imports, Spark config (datetime rebase if needed), source + target table name constants

Cell 3: Read Silver source
  -- printSchema() + display(df.limit(3)) + df.count()

Cell 4: Transform
  -- select columns, rename, cast to final types, derive DateKeys (YYYYMMDD int)
  -- cast BEFORE .alias() in every select expression

Cell 5: Add Unknown member row
  -- PK = -1, all string attributes = "Unknown", all numeric = 0 or null
  -- union with df_final before writing

Cell 6: DQ checks
  -- assert no duplicate PKs
  -- assert no null PKs
  -- print row count and spot-check key columns

Cell 7: Write
  -- .saveAsTable() if same workspace, .save(abfss path) if cross-workspace
  -- print final row count to confirm
```

**Fact notebooks (8 cells)** — insert between Cell 3 and 4:
```
Cell 3b: Read + aggregate detail table
  -- groupBy header PK, SUM all financial columns
  -- LEFT JOIN aggregated detail onto header
  -- coalesce all financials to 0
```

**DateKey derivation** (standard pattern for all date columns):
```python
F.date_format(F.col("TransactionDate"), "yyyyMMdd").cast(IntegerType()).alias("TransactionDateKey")
```

**Unknown member row pattern** (dims only):
```python
unknown_row = spark.createDataFrame([(-1,)], ["PolicyId"]) \
    .withColumn("PolicyKey", F.lit("Unknown")) \
    .withColumn("PolicyDescription", F.lit("Unknown")) \
    .withColumn("IsDeleted", F.lit(False))
    # all columns must be present, types must match

df_final = df_transformed.union(unknown_row)
```

---

### Phase 3 — Post-Execution Validation

Run after all notebooks complete. Do not mark the project done until all checks pass.

```sql
-- 1. Row counts — verify all tables match Phase 1 estimates
SELECT 'fact_transaction'       AS TableName, COUNT(*) AS Rows FROM The_Global_Loom.fact_transaction
UNION ALL SELECT 'dim_date',         COUNT(*) FROM The_Global_Loom.dim_date
UNION ALL SELECT 'dim_party',        COUNT(*) FROM The_Global_Loom.dim_party
UNION ALL SELECT 'dim_policy',       COUNT(*) FROM The_Global_Loom.dim_policy
UNION ALL SELECT 'dim_product',      COUNT(*) FROM The_Global_Loom.dim_product
UNION ALL SELECT 'dim_geography',    COUNT(*) FROM The_Global_Loom.dim_geography
UNION ALL SELECT 'dim_financial_segment', COUNT(*) FROM The_Global_Loom.dim_financial_segment
UNION ALL SELECT 'dim_data_source',  COUNT(*) FROM The_Global_Loom.dim_data_source
UNION ALL SELECT 'bridge_policy_party', COUNT(*) FROM The_Global_Loom.bridge_policy_party;

-- 2. Orphan FK checks — zero expected in every direction
SELECT COUNT(*) AS OrphanPolicies
FROM The_Global_Loom.fact_transaction f
LEFT JOIN The_Global_Loom.dim_policy p ON f.PolicyId = p.PolicyId
WHERE p.PolicyId IS NULL;

SELECT COUNT(*) AS OrphanProducts
FROM The_Global_Loom.fact_transaction f
LEFT JOIN The_Global_Loom.dim_product pr ON f.ProductId = pr.ProductId
WHERE pr.ProductId IS NULL;

-- 3. Financial totals reconciliation — fact must match source detail
SELECT SUM(GrossPremium) AS TotalGross, SUM(NetPremium) AS TotalNet
FROM The_Global_Loom.fact_transaction;
-- Compare against source:
SELECT SUM(GrossPremium) AS TotalGross, SUM(NetPremium) AS TotalNet
FROM rpt.vwTransactionDetailUSD;

-- 4. Unknown member rows — must exist in every dim
SELECT 'dim_policy'   AS Dim, COUNT(*) AS UnknownRows FROM The_Global_Loom.dim_policy   WHERE PolicyId = -1
UNION ALL SELECT 'dim_party',   COUNT(*) FROM The_Global_Loom.dim_party   WHERE PartyId = -1
UNION ALL SELECT 'dim_product', COUNT(*) FROM The_Global_Loom.dim_product WHERE ProductId = -1;
```

**Validation checklist**:
- [ ] All row counts match Phase 1 estimates
- [ ] Zero orphan FKs in every fact → dim join
- [ ] Financial totals reconcile between fact and source detail table
- [ ] Unknown member rows (`-1`) present in every dimension
- [ ] No duplicate PKs in any dimension

---

## Lessons from Global-Loom

| Situation | Rule |
|-----------|------|
| Header table has dimension FKs but no financials | Profile which table carries money before designing. It is often the child detail table, not the header |
| Source has both `ref` and `rpt` version of the same hierarchy | Use `ref` — it is the superset (more columns, same or fewer rows) |
| Candidate dim has unexpectedly large row count | Validate uniqueness. Check for versioning or cross-source duplication before assuming it is a problem |
| Business key uniqueness looks suspicious | Run `COUNT(*) vs COUNT(DISTINCT key)` explicitly. Business keys are often scoped within a data source |
| A table covers only some data sources | Quantify coverage %. Under ~20% → defer to Phase 2, not the primary fact |
| Lookup table would create a snowflake join | Denormalize columns onto the parent dim — star schema performs better in Power BI |
| Complex placements produce extreme fan-out | Check the full distribution. 1% of parents can generate 46% of child rows — design aggregation and runtime estimates around this |
| Pre-1900 timestamps in source tables | `spark.sql.parquet.datetimeRebaseModeInRead = CORRECTED` — must be set before reading or Spark throws on load |
| Empty financial columns in detail table | Profile every financial column for non-null %. Columns at 0% are dead — drop from the fact schema |
