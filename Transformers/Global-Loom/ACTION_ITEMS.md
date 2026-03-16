# Global Loom — Action Items

> **Updated**: 2026-03-16 (15:36 AEDT)
> **Status**: 1 blocking item remains (SIC code investigation). All other actions complete.

---

## 🔴 Blocking (Must Complete Before Execution)

### 1. Investigate SIC Code Linkage
**Goal**: Find which table contains SIC codes to link `dim_industry`

**Steps**:
```sql
-- Run in Fabric notebook attached to The_Global_Loom
-- Check vwParty for SIC code columns
DESCRIBE rpt.vwParty;
SELECT * FROM rpt.vwParty WHERE PartyId = 1;

-- Check vwPolicy for SIC code columns
DESCRIBE rpt.vwPolicy;
SELECT * FROM rpt.vwPolicy WHERE PolicyId = 1;

-- If found, check distinct count & null %
SELECT COUNT(*) AS Total,
       COUNT(DISTINCT SicCode) AS DistinctSIC,
       SUM(CASE WHEN SicCode IS NULL THEN 1 ELSE 0 END) AS Nulls
FROM rpt.vwParty;
```

**Decision Tree**:
- ✅ **If SIC column found on vwParty**: Add `IndustryKey` FK to `dim_party`, join via SIC code
- ✅ **If SIC column found on vwPolicy**: Add `IndustryKey` FK to `dim_policy`, join via SIC code
- ⚠️ **If no SIC column found**: Keep `dim_industry` as standalone reference table (no FK)

**Owner**: Prisco
**Deadline**: Before creating dim_industry notebook

---

### ~~2. Modify dim_party Notebook (Denormalize Carrier Hierarchy)~~ ✅ DONE

**File**: `notebooks/dimensions/03_gold_dim_party.ipynb`

**Changes Applied**:
- LEFT JOIN `ref.CarrierHierarchy` on `CompCode` (using `trim(upper())` on both sides)
- Added 6 carrier columns: `GlobalCarrierId`, `CarrierName`, `OperatingCompanyId`, `OperatingCompany`, `GlobalParentId`, `GlobalParent`
- Updated Unknown member row with null carrier columns
- DQ checks validate carrier population rate and flag non-carrier parties with carrier data

**Completed by**: Antigravity, 2026-03-16

---

### ~~3. Create dim_industry Notebook~~ ✅ DONE

**File**: `notebooks/dimensions/03_gold_dim_industry.ipynb` (CREATED)

**Source**: `ref.IndustryHierarchy` (1,005 rows)
**PK**: `SIC87IndustryId`
**Columns**: SIC87IndustryId, SIC87FullCode, SIC87IndustryDescription, IsDeleted + Unknown member

> ⚠️ Cell 3 column list is intentionally semi-populated. After running Cell 2 in Fabric,
> review the schema output and uncomment/add any additional hierarchy columns.
> FK linkage still depends on Action #1 (SIC code investigation).

**Completed by**: Antigravity, 2026-03-16

---

### ~~4. Delete dim_carrier Notebook~~ ✅ DONE

**File**: `notebooks/dimensions/03_gold_dim_carrier.ipynb` — **DELETED**

**Reason**: Carrier hierarchy now denormalized into `dim_party` (star schema pattern)

**Completed by**: Antigravity, 2026-03-16

---

## ⚠️ Recommended (Before Power BI)

### 5. Identify Which 3 DSIs Feed CFInvoice

**Goal**: Document for future `fact_invoice` work

**Query**:
```sql
SELECT
    d.DataSourceInstanceId,
    d.DataSourceInstanceName,
    COUNT(*) AS InvoiceCount,
    SUM(DocumentAmount) AS TotalDocAmount
FROM rpt.vwCFInvoice i
LEFT JOIN rpt.vwDataSourceInstance d ON i.DataSourceInstanceId = d.DataSourceInstanceId
GROUP BY d.DataSourceInstanceId, d.DataSourceInstanceName
ORDER BY InvoiceCount DESC;
```

**Update**: Document results in [01_star_schema_plan.md](docs/01_star_schema_plan.md#47-fact_invoice)

**Owner**: Prisco
**Deadline**: Nice-to-have before Phase 5

---

## 💡 Optional Quick Wins (When You Have Time)

These 1-day enhancements add dbt-like benefits without the overhead:

### 6. Create Reusable DQ Functions
**Goal**: Standardize data quality checks across all notebooks

**Effort**: 1 day

**Implementation**:
```python
# Create utils/dq_checks.py in the project root

def assert_unique_not_null(df, pk_col, table_name="table"):
    """Validate primary key is unique and non-null."""
    total = df.count()
    dupes = total - df.select(pk_col).distinct().count()
    nulls = df.filter(F.col(pk_col).isNull()).count()

    assert dupes == 0, f"❌ {table_name}: Found {dupes} duplicate {pk_col}!"
    assert nulls == 0, f"❌ {table_name}: Found {nulls} null {pk_col}!"
    print(f"✅ {table_name}: PK validation passed")
    return True

def assert_fk_integrity(df_fact, df_dim, fk_col, pk_col, fact_table, dim_table):
    """Validate foreign key has no orphans."""
    orphans = df_fact.join(
        df_dim,
        df_fact[fk_col] == df_dim[pk_col],
        "left_anti"
    ).count()

    assert orphans == 0, f"❌ {fact_table}.{fk_col} → {dim_table}.{pk_col}: {orphans} orphans!"
    print(f"✅ {fact_table} → {dim_table}: FK integrity passed")
    return True

# Usage in Cell 5 of every notebook:
from utils.dq_checks import assert_unique_not_null
assert_unique_not_null(df_final, "PartyId", "dim_party")
```

**Value**: 80% of dbt's testing benefit

---

### 7. Enable Fabric Lineage View
**Goal**: Visualize table dependencies (already built into Fabric)

**Effort**: 5 minutes

**Steps**:
1. Open Fabric workspace settings
2. Navigate to **Data Lineage** tab
3. Enable "Show lineage view"
4. Refresh notebooks to populate lineage graph

**Value**: 70% of dbt's lineage benefit (auto-generated, free)

---

### 8. Add Git Pre-Commit Hooks
**Goal**: Cleaner Git diffs (convert notebooks → Python before commit)

**Effort**: 1 day

**Implementation**:
```bash
# Install jupytext
pip install jupytext

# Create .git/hooks/pre-commit
#!/bin/bash
jupytext --to py:percent notebooks/**/*.ipynb
git add notebooks/**/*.py

# Make executable
chmod +x .git/hooks/pre-commit
```

**Result**: Git shows clean Python diffs instead of messy notebook JSON

**Value**: 50% of dbt's version control benefit

---

### 9. Standardize Cell 5 DQ Checks
**Goal**: Consistent testing pattern across all 11 notebooks

**Effort**: 2 days

**Steps**:
1. Create `utils/dq_checks.py` (from #6 above)
2. Update Cell 5 in all dimension notebooks to use reusable functions
3. Update Cell 7 in fact notebooks to add FK integrity checks
4. Add financial totals validation to fact_transaction

**Template Cell 5** (dimensions):
```python
from utils.dq_checks import assert_unique_not_null

assert_unique_not_null(df_final, "PartyId", "dim_party")
print(f"   Total rows: {df_final.count():,}")
```

**Template Cell 7** (facts):
```python
from utils.dq_checks import assert_unique_not_null, assert_fk_integrity

# PK check
assert_unique_not_null(df_final, "TransactionId", "fact_transaction")

# FK integrity checks
assert_fk_integrity(df_final, df_dim_policy, "PolicyId", "PolicyId",
                    "fact_transaction", "dim_policy")
assert_fk_integrity(df_final, df_dim_product, "ProductId", "ProductId",
                    "fact_transaction", "dim_product")
```

**Value**: Catches 90% of DQ issues before Power BI

---

## 🔮 Future Considerations: dbt Integration

**Status**: Not recommended now, revisit if conditions change

### When to Re-Evaluate dbt

Re-assess dbt if **2+ of these conditions** become true:

| Condition | Current State | Threshold for dbt |
|-----------|---------------|-------------------|
| **Table count** | 10 gold tables | 50+ tables |
| **Team size** | 1 person (you) | 3+ data engineers contributing |
| **Testing complexity** | Manual DQ checks | 100+ automated tests needed |
| **SQL preference** | PySpark (complex logic) | Team prefers SQL |
| **Regulatory approval** | Business case required | Approval process simplified |
| **dbt-fabric maturity** | Early stage | Production-ready adapter |
| **Multiple environments** | 1 workspace | Dev/Test/Prod environments |

**Current Score**: 0/7 conditions met → **dbt not recommended**

---

### dbt Decision Matrix

| Your Need | Current Solution | dbt Benefit | Recommendation |
|-----------|-----------------|-------------|----------------|
| **Complex transformations** | PySpark (window functions, UDFs) | SQL-only (limited) | ❌ Keep PySpark |
| **Data quality testing** | Manual asserts in Cell 5 | YAML tests (automated) | ⚠️ Use Quick Win #6 instead |
| **Documentation** | Manual `.md` files | Auto-generated site | ⚠️ Not worth migration effort |
| **Lineage visualization** | Fabric Lineage View | dbt DAG | ≈ Fabric already has this |
| **Orchestration** | Fabric Data Pipelines | Need external scheduler | ❌ Fabric is simpler |
| **Version control** | Notebook JSON | Clean SQL files | ⚠️ Use Quick Win #8 instead |
| **Cost** | $0 (F16 included) | $0 (Core) or $$$ (Cloud) | ≈ Tie |

**Decision**: Implement **Optional Quick Wins #6-9** to get 70-80% of dbt's value with 5 days effort instead of 5-7 weeks migration.

---

### If You Decide to Pursue dbt Later

**Business Case Template**:
> "We've scaled from 10 to 50+ tables with 3+ data engineers. Our current manual testing approach requires 10+ hours/week and has led to 3 production data quality incidents. dbt would:
> 1. Automate 100+ data quality tests (save 10 hours/week)
> 2. Auto-generate documentation (save 4 hours/month)
> 3. Provide change impact analysis via lineage (reduce incident risk)
>
> Investment: 6 weeks migration + ongoing maintenance
> ROI: 14 hours/week saved = $75K/year (at $100/hour)"

**Migration Checklist**:
- [ ] Confirm team is SQL-first (not PySpark)
- [ ] Validate dbt-fabric adapter is production-ready
- [ ] Get regulatory approval (security review, data governance)
- [ ] Allocate 6-8 weeks for migration
- [ ] Train team on dbt concepts (models, tests, macros)
- [ ] Set up dbt project structure
- [ ] Migrate 1 table as proof-of-concept
- [ ] Migrate remaining tables in priority order
- [ ] Configure CI/CD for dbt runs
- [ ] Deprecate Fabric notebooks gradually

**Resources**:
- dbt-fabric docs: https://github.com/Microsoft/dbt-fabric
- dbt best practices: https://docs.getdbt.com/best-practices
- WTW data governance: [internal link]

---

## 📝 Checklist Before Fabric Execution

- [ ] **Action #1**: SIC code linkage investigated ← 🔴 REMAINING BLOCKER
- [x] **Action #2**: dim_party modified (carrier hierarchy added) ✅
- [x] **Action #3**: dim_industry notebook created ✅
- [x] **Action #4**: dim_carrier notebook deleted ✅
- [ ] README.md updated (remove carrier, add industry)
- [ ] 01_star_schema_plan.md updated (ERD reflects carrier denormalization)

---

## Notebook Execution Order (After Actions Complete)

### Phase 2: Dimensions (Parallel)
```bash
# Run simultaneously (no dependencies)
03_gold_dim_date.ipynb
03_gold_dim_data_source.ipynb
03_gold_dim_financial_segment.ipynb
03_gold_dim_geography.ipynb
03_gold_dim_product.ipynb
03_gold_dim_industry.ipynb          # NEW

# Run after small dims
03_gold_dim_party.ipynb             # MODIFIED (with carrier hierarchy)

# Run after party
03_gold_dim_policy.ipynb            # 20M rows — monitor runtime
```

### Phase 3: Bridge + Fact (Sequential)
```bash
03_gold_bridge_policy_party.ipynb
03_gold_fact_transaction.ipynb      # 85M rows (aggregates 471M detail)
```

**Estimated Runtime**: 60-90 minutes total

---

## Post-Execution Validation

After running all notebooks, verify:

```sql
-- 1. Row counts
SELECT 'dim_date' AS table_name, COUNT(*) AS rows FROM The_Global_Loom.dim_date
UNION ALL SELECT 'dim_product', COUNT(*) FROM The_Global_Loom.dim_product
UNION ALL SELECT 'dim_party', COUNT(*) FROM The_Global_Loom.dim_party
UNION ALL SELECT 'dim_financial_segment', COUNT(*) FROM The_Global_Loom.dim_financial_segment
UNION ALL SELECT 'dim_geography', COUNT(*) FROM The_Global_Loom.dim_geography
UNION ALL SELECT 'dim_data_source', COUNT(*) FROM The_Global_Loom.dim_data_source
UNION ALL SELECT 'dim_industry', COUNT(*) FROM The_Global_Loom.dim_industry
UNION ALL SELECT 'dim_policy', COUNT(*) FROM The_Global_Loom.dim_policy
UNION ALL SELECT 'bridge_policy_party', COUNT(*) FROM The_Global_Loom.bridge_policy_party
UNION ALL SELECT 'fact_transaction', COUNT(*) FROM The_Global_Loom.fact_transaction;

-- 2. Orphan FK check (fact → dims)
SELECT COUNT(*) AS OrphanPolicies
FROM The_Global_Loom.fact_transaction f
LEFT JOIN The_Global_Loom.dim_policy p ON f.PolicyId = p.PolicyId
WHERE p.PolicyId IS NULL;

SELECT COUNT(*) AS OrphanProducts
FROM The_Global_Loom.fact_transaction f
LEFT JOIN The_Global_Loom.dim_product pr ON f.ProductId = pr.ProductId
WHERE pr.ProductId IS NULL;

-- 3. Financial totals validation
SELECT
    SUM(GrossPremium) AS TotalGrossPremium,
    SUM(NetPremium) AS TotalNetPremium,
    SUM(GrossBrokerage) AS TotalGrossBrokerage
FROM The_Global_Loom.fact_transaction;

-- Compare with source detail table
SELECT
    SUM(GrossPremium) AS TotalGrossPremium,
    SUM(NetPremium) AS TotalNetPremium,
    SUM(GrossBrokerage) AS TotalGrossBrokerage
FROM rpt.vwTransactionDetailUSD;

-- 4. Carrier hierarchy population
SELECT
    GlobalPartyRole,
    COUNT(*) AS TotalParties,
    SUM(CASE WHEN GlobalCarrierId IS NOT NULL THEN 1 ELSE 0 END) AS WithCarrierData
FROM The_Global_Loom.dim_party
WHERE GlobalPartyRole IN ('Carrier', 'Client', 'Broker')
GROUP BY GlobalPartyRole;
```

**Expected Results**:
- All row counts match plan
- Zero orphan FKs
- Financial totals match between fact and detail
- Carrier parties have hierarchy data populated

---

## Questions / Issues

Contact: Prisco Liu
Workspace: `The_Global_Loom`
Fabric SKU: F16
