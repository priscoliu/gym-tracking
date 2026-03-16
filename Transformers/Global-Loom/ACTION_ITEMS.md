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
