# Global Loom — PAS Data Warehouse

> **Quick Navigation**: See [docs/INDEX.md](docs/INDEX.md) for complete file directory

## Project Overview

| Field | Value |
|---|---|
| **Project** | Global Loom (PAS Data Warehouse) |
| **Source System** | PAS (Policy Administration System) — 56 global data sources |
| **Fabric Lakehouse** | `The_Global_Loom` |
| **Fabric Capacity** | F16 (300M rows/table, 1.5B total model) |
| **Architecture** | Medallion (Bronze → Silver → Gold) |
| **Gold Layer Pattern** | Star Schema (10 tables: 7 dims + 1 fact + 1 bridge + 1 deferred) |
| **Business Use Case** | Cross-sell analytics, financial reporting, AI insights |
| **Consumers** | Power BI Direct Lake + AI Agent |
| **Column Naming** | PascalCase (`PolicyNumber`, `CarrierKey`) |
| **Status** | ✅ Design complete, ⚠️ 2 items blocking execution |

---

## 📁 Project Files

### For Stakeholders
- **[docs/EXECUTIVE_SUMMARY.md](docs/EXECUTIVE_SUMMARY.md)** — Business-focused summary (for your boss)
- **[docs/ACTION_ITEMS.md](docs/ACTION_ITEMS.md)** — What needs to be done next
- **[docs/INDEX.md](docs/INDEX.md)** — Complete file directory & navigation

### Documentation (Read in Order)
1. **[docs/00_data_exploration_results.md](docs/00_data_exploration_results.md)** — 471M rows profiled
2. **[docs/01_star_schema_plan.md](docs/01_star_schema_plan.md)** — Star schema design
3. **[docs/02_validation_summary.md](docs/02_validation_summary.md)** — Validation report

### Notebooks
- **[exploration/](exploration/)** — Data profiling notebooks + 23 query results
- **[notebooks/dimensions/](notebooks/dimensions/)** — 8 dimension notebooks (7 ready, 1 needs modification)
- **[notebooks/facts/](notebooks/facts/)** — 2 fact notebooks (1 ready, 1 deferred)
- **[notebooks/bridge/](notebooks/bridge/)** — 1 bridge notebook (ready)

---

## Key Metrics

| Metric | Value |
|--------|-------|
| **Source Tables** | 18 (ref + rpt schemas) |
| **Transaction Details** | 471M rows → aggregated to 85M transactions |
| **Policies** | 20M unique across 56 data sources |
| **Parties** | 3.7M local → 626K global entities (for cross-sell) |
| **Product Classes** | 16 (Property, Casualty, Marine, etc.) |
| **Gold Tables** | 10 total |
| **Total Model Size** | ~157M rows (well within F16 capacity) |
| **FK Integrity** | 100% (zero orphans across all 471M detail rows) |
| **Timeline** | 6 weeks to production |

---

## Business Use Cases

### 1. Cross-Sell Analytics
**Question**: "Which clients buy Property insurance but NOT Marine insurance?"

**Answer**: Use `GlobalPartyId` to group parties across data sources, then analyze product mix by `GlobalProductClass`.

**Value**: 3-5% revenue uplift from targeted cross-sell campaigns.

### 2. Financial Reporting
**Metrics Available**: GrossPremium, NetPremium, GrossBrokerage, NetBrokerage, Claims, Fees (15 total)

**Dimensions**: Date (Aus FY), Geography (9 levels), Segment (CRB/HCB/IRR), Product (16 classes)

**Value**: Unified global view vs 56 separate data source reports today.

### 3. AI-Powered Insights
**Detail Level**: 471M transaction detail rows (carrier-level granularity) available in lakehouse

**Use Case**: "Which carriers have the highest claim ratios for Marine products in APAC?"

**Value**: Deep analysis not possible in Power BI (F16 limit = 300M rows/table).

---

## Gold Layer Star Schema

```
                    ┌─────────────┐
                    │  dim_date   │
                    │  (~13K)     │
                    └──────┬──────┘
                           │
    ┌──────────┐    ┌──────▼──────────┐    ┌──────────────┐
    │dim_party │◄───┤fact_transaction │───►│ dim_product  │
    │ (3.7M)   │    │    (85M rows)   │    │   (31K)      │
    └────┬─────┘    └─────────────────┘    └──────────────┘
         │                  │
         │                  ▼
         │          ┌───────────────┐
         │          │ dim_geography │
         │          │    (1K)       │
         │          └───────────────┘
         ▼
┌─────────────────┐         ┌────────────────┐
│bridge_policy_   │────────►│  dim_policy    │
│  party (48.7M)  │         │    (20M)       │
└─────────────────┘         └────────────────┘
```

### Table Inventory

| Table | Rows | Source | Status |
|-------|------|--------|--------|
| **fact_transaction** | 85M | vwTransaction + agg(vwTransactionDetailUSD) | ✅ Ready |
| **dim_date** | 13K | Generated (Aus FY) | ✅ Ready |
| **dim_party** | 3.7M | vwParty + carrier hierarchy | ⚠️ Needs modification |
| **dim_policy** | 20M | vwPolicy | ✅ Ready |
| **dim_product** | 31K | vwProduct | ✅ Ready |
| **dim_geography** | 1K | FinancialGeographyHierarchy (ref) | ✅ Ready |
| **dim_financial_segment** | 4K | FinancialSegmentHierarchy (ref) | ✅ Ready |
| **dim_data_source** | 81 | vwDataSourceInstance | ✅ Ready |
| **dim_industry** | 1K | IndustryHierarchy (ref) | 🔴 Missing (needs creation) |
| **bridge_policy_party** | 48.7M | vwPolicyPartyRole | ✅ Ready |
| **fact_invoice** | 9.7M | vwCFInvoice | ❌ Deferred (only 3/56 DSIs) |

---

## Current Status

### ✅ Completed
- Phase 0: Data discovery (471M rows profiled, 23 deep dive queries)
- Phase 1: Star schema design (10 tables, join map, cross-sell path)
- Notebook creation (9/10 ready)
- Code validation (zero quality issues)
- Open questions resolved (all 5 answered)

### ⚠️ Blocking Items (2)
1. **Create dim_industry notebook** — Need to investigate SIC code linkage first
2. **Modify dim_party notebook** — Add carrier hierarchy (denormalize from dim_carrier)

### 🔴 To Delete
- `notebooks/dimensions/03_gold_dim_carrier.ipynb` — Merged into dim_party (star schema pattern)

---

## Next Steps

See [docs/ACTION_ITEMS.md](docs/ACTION_ITEMS.md) for detailed instructions.

**Quick Summary**:
1. Investigate SIC code linkage (run SQL queries)
2. Create `dim_industry` notebook
3. Modify `dim_party` notebook (add carrier hierarchy columns)
4. Delete `dim_carrier` notebook
5. Execute notebooks in Fabric (60-90 min total runtime)
6. Validate results (row counts, FK integrity, financial totals)

---

## Execution Plan

### Phase 2: Build Dimensions (Parallel)
```bash
# Small dimensions (run simultaneously)
notebooks/dimensions/03_gold_dim_date.ipynb
notebooks/dimensions/03_gold_dim_data_source.ipynb
notebooks/dimensions/03_gold_dim_financial_segment.ipynb
notebooks/dimensions/03_gold_dim_geography.ipynb
notebooks/dimensions/03_gold_dim_product.ipynb
notebooks/dimensions/03_gold_dim_industry.ipynb          # NEW (after creation)

# Medium dimension (after small dims)
notebooks/dimensions/03_gold_dim_party.ipynb             # MODIFIED (with carrier)

# Large dimension (after party)
notebooks/dimensions/03_gold_dim_policy.ipynb            # 20M rows
```

### Phase 3: Build Bridge + Fact (Sequential)
```bash
notebooks/bridge/03_gold_bridge_policy_party.ipynb
notebooks/facts/03_gold_fact_transaction.ipynb           # 85M rows (30 min)
```

**Estimated Total Runtime**: 60-90 minutes

---

## Standards & Conventions

### File Naming
- Exploration: `00_explore_[subject].ipynb`
- Dimensions: `03_gold_dim_[entity].ipynb`
- Facts: `03_gold_fact_[process].ipynb`
- Bridge: `03_gold_bridge_[relationship].ipynb`

### Table Naming
- Facts: `fact_transaction`
- Dimensions: `dim_party`, `dim_product`
- Bridge: `bridge_policy_party`

### Column Naming
- **PascalCase**: `PolicyNumber`, `TransactionDate`, `AmountUsd`
- **Surrogate keys**: `PolicyKey`, `CarrierKey`, `TransactionKey`
- **Date keys**: `TransactionDateKey`, `InvoiceDateKey` (YYYYMMDD int)

### Write Pattern
```python
df.write.format("delta").mode("overwrite").option("overwriteSchema", "true").saveAsTable("table_name")
```

### Notebook Source Format (CRITICAL)
**When editing `.ipynb` files, the `source` field MUST be an array of strings, NOT a single string.**

Fabric's notebook upload will fail with 400 Bad Request if source is a single string.

**Correct format:**
```json
"source": [
  "line1\n",
  "line2\n",
  "line3"
]
```

**Wrong format (will fail upload):**
```json
"source": "line1\nline2\nline3"
```

If notebooks fail to upload with 400 error, run this fix:
```python
import json
for nb in notebooks:
    with open(nb, 'r') as f:
        data = json.load(f)
    for cell in data.get('cells', []):
        if isinstance(cell.get('source'), str):
            lines = cell['source'].split('\n')
            cell['source'] = [line + '\n' if i < len(lines)-1 else line
                             for i, line in enumerate(lines)]
    with open(nb, 'w') as f:
        json.dump(data, f, indent=1)
```

### Notebook Presentation
- **No emojis**: Humans don't add emojis when coding. Avoid all emojis in:
  - Print statements
  - Markdown headers
  - Comments
  - Variable names
- **Professional tone**: Code should look human-written, not AI-generated
- **Use plain text instead**:
  - ✅ `print("Config complete")` → `print("Config: {SOURCE_TABLE} → {LAKEHOUSE}.{TABLE}")`
  - ✅ `print("Warning: long runtime")` → `print("WARNING: This takes ~30 minutes")`
  - ✅ `print("Error: duplicates found")` → `print("ERROR: Found {dupes} duplicate records")`

**Example** (human-written):
```python
print(f"Config: {SOURCE_TABLE} → {LAKEHOUSE}.{TABLE}")
print(f"Rows: {df.count():,}")
```

**Example** (AI-generated):
```python
print(f"✅ Config: {SOURCE_TABLE} → {LAKEHOUSE}.{TABLE}")
print(f"🎉 Super exciting config! 🚀")
```

---

## Contact

**Owner**: Prisco Liu
**Workspace**: The_Global_Loom
**Fabric Capacity**: F16
**Last Updated**: 2026-03-16
