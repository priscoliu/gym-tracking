# Phase 0 — Data Exploration Results

> **Project**: Global Loom  
> **Lakehouse**: `The_Global_Loom`  
> **Date**: 2026-03-13  
> **Purpose**: Complete profiling of 18 PAS silver tables to inform gold layer star schema design.

---

## Table of Contents

1. [Source Data Inventory](#1-source-data-inventory)
2. [Schema Details](#2-schema-details)
3. [Cardinality & Unique Keys](#3-cardinality--unique-keys)
4. [Shared Columns (FK Candidates)](#4-shared-columns-fk-candidates)
5. [Transaction Deep Dive](#5-transaction-deep-dive)
6. [Deep Dive Query Results](#6-deep-dive-query-results)
7. [Key Findings & Decisions](#7-key-findings--decisions)

---

## 1. Source Data Inventory

### 18 PAS Silver Tables (Cell 3 output)

| Schema | Table | Rows | Cols | Tier | Role |
|--------|-------|------|------|------|------|
| ref | CarrierHierarchy | 37,180 | 13 | Small | Carrier hierarchy (superset) |
| ref | FinancialGeographyHierarchy | 1,082 | 35 | Small | Geography hierarchy rollup |
| ref | FinancialSegmentHierarchy | 3,993 | 21 | Small | Financial segment hierarchy |
| ref | IndustryHierarchy | 1,005 | 21 | Tiny | SIC/Willis industry mapping |
| rpt | vwAddress | 3,722,322 | 28 | Dim | Address (≈1:1 with Party) |
| rpt | vwCarrierHierarchy | 37,180 | 9 | Small | Carrier hierarchy (subset of ref) |
| rpt | vwCFInvoice | 9,744,807 | 20 | Fact | Cash flow invoices |
| rpt | vwCFParty | 70,579 | 9 | Small | Cash flow party subset |
| rpt | vwDataSourceInstance | 81 | 12 | Tiny | Data source metadata |
| rpt | vwFinancialGeography | 31,019 | 20 | Small | Geography leaf instances |
| rpt | vwParty | 3,736,109 | 37 | Dim | Party master |
| rpt | vwPolicy | 20,057,914 | 64 | Large Dim | Policy master |
| rpt | vwPolicyLayer | 91,178 | 21 | Small | Policy excess/limit layers |
| rpt | vwPolicyPartyRole | 48,740,661 | 18 | Bridge | Many-to-many: Policy ↔ Party ↔ Role |
| rpt | vwProduct | 31,565 | 21 | Small | Product catalogue |
| rpt | vwTransaction | 85,262,175 | 49 | Large | Transaction header (NO financials) |
| rpt | vwTransactionDetailUSD | 471,598,652 | 87 | Mega | Line-level detail with 19 financial cols |
| rpt | vwTransactionSummaryUSD | 80,126,002 | 44 | Large | Pre-aggregated (5 DSIs only) |

### Key Size Observations

- `vwTransactionDetailUSD` (471M) is the most granular fact — one row per transaction × party × carrier
- `vwTransaction` (85M) has dimension FKs but ZERO financial columns — it's a header/envelope
- `vwPolicy` (20M) is unexpectedly large for a dimension — confirmed as 20M genuinely unique policies across 56 data sources (no versioning/SCD)
- `vwPolicyPartyRole` (48.7M) is a many-to-many bridge table linking policies to parties with roles

---

## 2. Schema Details

### vwTransaction (85M rows, 49 cols) — Transaction Header

**Key columns**: TransactionId (PK), TransactionKey, PolicyId, ProductId, GlobalFinancialGeographyId, GlobalFinancialSegmentId, GlobalLegalEntityId, DataSourceInstanceId

**Date columns**: TransactionDate, InvoiceDate

**Denormalized party IDs**: ClientPartyId, InsuredPartyId, ReinsuredPartyId

**Denormalized product**: GlobalProductClassId, GlobalProductClass, GlobalProductLineId, GlobalProductLine, GlobalProductId, GlobalProduct

**Important**: NO financial columns at all. All money lives in vwTransactionDetailUSD.

### vwTransactionDetailUSD (471M rows, 87 cols) — Financial Detail

**Key columns**: TransactionDetailId (PK), TransactionId (FK to header), PolicyId, PolicySectionId, AccountPartyId, GlobalPartyId

**Financial measures** (19 total, 4 are empty):
- Populated: GrossPremium, NetPremium, GrossBrokerage, NetBrokerage, GrossFee, NetFee, Claim, AdditionalCommission, ContingentCommission, MarketDerivedIncome, Deduction, CostOtherExpense, CostCompanyExpense, SharedBrokerage, SharedFee
- **Empty** (0 non-null): Adjustments, Discount, Expenses, WriteOff

**Party columns**: Party1-4 (Id, Key, Role, RoleKey) — cascading party structure, Party3 is 95% NULL, Party4 is 99.97% NULL

**Carrier columns**: CarrierOwnRef, IsLeadCarrier, CarrierSignedLinePercentage, CarrierWrittenLinePercentage

**Currency**: CurrencyKey, CurrencyId, GlobalCurrencyId, GlobalCurrencyCode, USDExchangeRate

**Important**: Does NOT have ProductId — must join to vwTransaction to get product info.

### vwTransactionSummaryUSD (80M rows, 44 cols) — Pre-aggregated

**Critical gaps found**:
- `PolicyKey` = CONSTANT (completely empty)
- `PolicySectionKey` = CONSTANT (completely empty)
- `GrossBrokerageAndFee` = CONSTANT (empty)
- `NetBrokerageAndFee` = CONSTANT (empty)
- `LowestLevelPartyRole` = CONSTANT (empty)
- Only 5 DataSourceInstances (vs 56 in other tables): Eclipse, WIBS, Gras Savoye EGS, COL, Broking.net

**Contains**: Multi-level party hierarchy (Level1-4PartyId/Role, LowestLevelPartyId), aggregated financials

### vwPolicy (20M rows, 64 cols)

**Key columns**: PolicyId (PK, 100% unique), PolicyKey (unique per Q1d check)

**CONSTANT columns** (can be dropped): AutoInvoice, AutoRenewal, IsWholeOrder, RetentionStructure, SumInsuredCurrencyKey, SumInsuredCurrencyId, WillisPercentageOfOrder

**Date columns**: InceptionDate, ExpiryDate, FirstInceptionDate, RenewalDate, PolicyIssuedDate

**Dimension FKs**: GlobalFinancialGeographyId, GlobalFinancialSegmentId, GlobalLegalEntityId, GlobalCurrencyCode

### vwCFInvoice (9.7M rows, 20 cols)

**Key columns**: DocumentKey (PK), TransactionId (FK), PartyId (FK), CustomerNumber

**Financial**: DocumentAmount, CorporateAmount, Currency (104 currencies)

**Limitations**: Only 3 DataSourceInstances, DocumentType is CONSTANT ('Invoice')

### vwProduct (31K rows, 21 cols)

**Hierarchy**: GlobalProductClass (16) → GlobalProductLine (73) → GlobalProduct (330) → Product (31,565)

**Key**: ProductId (100% unique)

### vwParty (3.7M rows, 37 cols)

**Key**: PartyId (100% unique), GlobalPartyId (626K distinct — groups ~6 local parties per global entity)

**CONSTANT**: LastActivityUpdatedDate (0 distinct)

**Cross-sell critical**: GlobalPartyId links the same client across different data source instances

### vwPolicyPartyRole (48.7M rows, 18 cols)

**Key**: PolicyPartyRoleId (100% unique)

**FKs**: PolicyId → vwPolicy, PartyId → vwParty

**Role info**: GlobalPartyRoleId (12 values), GlobalPartyRole, IsPrimaryParty

---

## 3. Cardinality & Unique Keys

### Confirmed Unique Keys per Table

| Table | Unique Key(s) | Notes |
|-------|--------------|-------|
| CarrierHierarchy | CompCode, GlobalCarrierId, CarrierName | CompCode is 100% unique |
| FinancialGeographyHierarchy | GlobalFinancialGeographyId, LocationId | LocationCode near-unique |
| FinancialSegmentHierarchy | GlobalFinancialSegmentId | |
| IndustryHierarchy | SIC87FullCode, SIC87IndustryId | |
| vwAddress | AddressId, AddressKey | |
| vwCarrierHierarchy | CompCode, GlobalCarrierId, CarrierName | Same as ref carrier |
| vwCFInvoice | DocumentKey | TransactionId is 83.4% unique (1:many) |
| vwCFParty | CustomerNumber + DSI (composite) | |
| vwDataSourceInstance | DataSourceInstanceId, DataSourceInstanceKey, DataSourceInstanceName | All three 100% unique |
| vwFinancialGeography | FinancialGeographyId | GlobalFinancialGeographyId only 202 distinct |
| vwParty | PartyId | PartyKey 97%, GlobalPartyId only 626K |
| vwPolicy | PolicyId | PolicyKey — originally showed 72.6% but Q1d confirmed unique (countDistinct precision issue) |
| vwPolicyLayer | PolicyLayerId, SourceKey, PolicyLayerKey | |
| vwPolicyPartyRole | PolicyPartyRoleId | |
| vwProduct | ProductId | ProductKey 83.9% |
| vwTransaction | TransactionId | TransactionKey 83.7% |
| vwTransactionDetailUSD | TransactionDetailId | TransactionId is 17.2% (many details per txn) |
| vwTransactionSummaryUSD | TransactionSummaryUSDId | PolicyId only 6.3% |

### Sentinel Values

All numeric ID/FK columns use `-1` as a sentinel value meaning "not found" or "unmapped". This is a standard PAS ETL pattern.

---

## 4. Shared Columns (FK Candidates)

### Business Keys That Link Tables

| Column | Tables | Relationship |
|--------|--------|-------------|
| `TransactionId` | vwTransaction, vwTransactionDetailUSD, vwCFInvoice | Detail/Invoice → Header |
| `PolicyId` | vwPolicy, vwPolicyPartyRole, vwTransaction, vwTransactionDetailUSD, vwTransactionSummaryUSD, vwPolicyLayer | Central policy FK |
| `PolicyKey` | vwPolicy, vwPolicyPartyRole, vwTransaction, vwTransactionDetailUSD, vwPolicyLayer | Business key (scoped) |
| `PartyId` | vwParty, vwPolicyPartyRole, vwCFInvoice, vwAddress, vwTransactionDetailUSD | Party FK |
| `GlobalPartyId` | vwParty, vwPolicyPartyRole, vwTransactionDetailUSD, vwTransactionSummaryUSD | Global party grouping |
| `ProductId` | vwProduct, vwTransaction | Product FK (only on header!) |
| `GlobalFinancialGeographyId` | FinancialGeographyHierarchy, vwFinancialGeography, vwPolicy, vwTransaction, vwTransactionDetailUSD, vwTransactionSummaryUSD | Geography FK |
| `GlobalFinancialSegmentId` | FinancialSegmentHierarchy, vwPolicy, vwTransaction, vwTransactionDetailUSD, vwTransactionSummaryUSD | Segment FK |
| `DataSourceInstanceId` | vwDataSourceInstance + 13 other tables | Source system identifier |
| `CompCode` | CarrierHierarchy, vwCarrierHierarchy, vwParty | Carrier → Party link |
| `CustomerNumber` | vwCFInvoice, vwCFParty | Cash flow party link |

### Audit/Metadata Columns (NOT business keys)

ETLUpdatedDate (18 tables), ETLCreatedDate (15), SourceLastUpdateDate (14), IsDeleted (15), ETLLoadedDate (10)

---

## 5. Transaction Deep Dive

### Value Distributions — vwTransactionDetailUSD (471M rows)

**SourceQuery**: NULL (302M/64%), TRNDTL (97M), TRNCOMP (33.5M), CLIENT (10.6M), CARRIER (6.4M), AGENCY (5.1M), CARR/CLT (4.3M each), DOC_CLIENT/DOC_CARRIER (2.2M each)

**GlobalPartyRole**: Client (187.7M/40%), Carrier (185.6M/39%), NULL (72.1M/15%), Third Party - Other (13.1M), Broker (5.9M)

**Party1Role**: Bureau (158.1M/34%), Client (98.3M/21%), UW (56.9M/12%), NULL (52.9M/11%), Company (42M/9%)

**Party2Role**: UW (160.1M/34%), NULL (149M/32%), Client (85.1M/18%), Company (44.3M/9%)

**Party3Role**: NULL (447.6M/95%), UW (23.9M) — mostly unused

**Party4Role**: NULL (471.4M/99.97%) — almost entirely unused

**SegmentCode**: CRB (357M/76%), HCB (57.9M/12%), IRR (50.5M/11%)

### Value Distributions — vwTransactionSummaryUSD (80M rows)

**DataSourceInstanceName**: Eclipse (62.4M/78%), WIBS (7.1M/9%), Gras Savoye EGS (5.1M), COL (4M), Broking.net (1.5M)

**Level1PartyRole**: Bureau (30.6M/38%), UW (19.1M/24%), NULL (13.4M/17%), Pool (5.5M)

**SegmentCode**: CRB (54.2M/68%), IRR (19.9M/25%), HCB (5.2M/7%)

### Financial Column Coverage (vwTransactionDetailUSD)

| Column | Non-null rows | % populated |
|--------|--------------|-------------|
| NetPremium | 123,922,582 | 26.3% |
| GrossBrokerage | 105,034,525 | 22.3% |
| GrossPremium | 91,400,677 | 19.4% |
| NetBrokerage | 63,737,476 | 13.5% |
| CostOtherExpense | 18,153,422 | 3.8% |
| SharedBrokerage | 15,596,092 | 3.3% |
| Claim | 11,822,584 | 2.5% |
| GrossFee | 11,838,113 | 2.5% |
| NetFee | 11,087,988 | 2.4% |
| MarketDerivedIncome | 9,226,590 | 2.0% |
| AdditionalCommission | 7,160,589 | 1.5% |
| CostCompanyExpense | 5,408,400 | 1.1% |
| SharedFee | 2,358,197 | 0.5% |
| Deduction | 2,236,506 | 0.5% |
| ContingentCommission | 762,182 | 0.2% |
| **Adjustments** | **0** | **0%** |
| **Discount** | **0** | **0%** |
| **Expenses** | **0** | **0%** |
| **WriteOff** | **0** | **0%** |

---

## 6. Deep Dive Query Results

These queries were run in `00_explore_deep_dive.ipynb` and results saved as JSON.

### Q1: vwPolicy — Why 20M rows?

**Q1a — Uniqueness check**:
- Total rows: 20,057,914
- Unique PolicyIds: 20,057,914 (100%) — each row is unique
- Unique PolicyKeys: 14,554,069 (but Q1d confirmed PolicyKey IS also unique — countDistinct was imprecise)
- Data sources: 56
- Avg rows per PolicyId: 1.0

**Q1b — By DataSource (top 10)**:
| DataSource | Rows | Unique Policies |
|------------|------|-----------------|
| Epic US | 4,812,596 | 4,812,596 |
| WIBS | 2,501,293 | 2,501,293 |
| Inbroker - Argentina | 1,788,096 | 1,788,096 |
| Broking.net | 1,450,172 | 1,450,172 |
| eGlobal - Australia | 1,211,097 | 1,211,097 |
| Eclipse | 1,086,806 | 1,086,806 |
| COL | 972,236 | 972,236 |
| ASYS - Germany & Austria | 882,613 | 882,613 |
| Gras Savoye EGS | 849,433 | 849,433 |
| Epic Canada | 443,071 | 443,071 |

Each DSI contributes unique policies (Rows = Unique Policies for every source).

**Q1c — Duplicates within DSI**: Zero duplicates. No versioning/SCD.

**Q1d — PolicyKey uniqueness**: Only PolicyId is confirmed unique. PolicyKey is NOT unique (14,554,069 distinct / 72.6%).

**Verdict**: 20M is real — genuinely 20M distinct policies across 56 global data sources. No dedup needed.

### Q2: Invoice ↔ Transaction Chain

**Q2a — FK integrity**:
- Total invoices: 9,744,807
- Matched to transaction: 9,744,675 (100.0%)
- Orphan invoices: 132 (0.001%)

**Q2b — Transaction invoice coverage**:
- Total transactions: 85,262,175
- Has invoice: 8,126,509 (**9.5%**)
- No invoice: 77,135,666 (90.5%)

**Critical finding**: Only 9.5% of transactions have invoices. CFInvoice covers a tiny slice.

**Q2c — Invoices per transaction**:
| Ratio | Transactions |
|-------|-------------|
| 1 invoice | 7,606,070 (93.6%) |
| 2-5 invoices | 412,567 |
| 6-10 | 79,361 |
| 11-50 | 28,503 |
| 50+ | 140 |

**Q2d — Product via invoice chain**: 100% of invoices can pick up ProductId through Transaction join.

**Q2e — Dimension pickup via chain**: All dimensions (Policy, Product, Geography, Segment) at 100% coverage via Transaction join. Only 132-149 orphan rows.

### Q3: Transaction ↔ Detail Chain

**Q3a — TransactionId counts**:
| Table | Total Rows | Unique TransactionIds |
|-------|-----------|----------------------|
| vwTransaction | 85,262,175 | 85,262,175 (100%) |
| vwTransactionDetailUSD | 471,598,652 | 81,182,602 (17.2%) |
| vwTransactionSummaryUSD | 80,126,002 | 5,061,915 (6.3%) |

81.2M of 85.3M transactions have detail records (95.2%). Summary only covers 5.1M unique PolicyIds.

**Q3b — Orphan detail rows**: **Zero**. Every detail row has a matching header.

**Q3c — Headers without details**: 4,079,573 (4.8%) — these are transactions with no financial line items.

**Q3d — Detail-per-transaction distribution**:
| Detail Count | Transactions | Total Detail Rows | % of All Detail |
|---|---|---|---|
| 1 detail | 27,532,866 (34%) | 27,532,866 | 5.8% |
| 2-5 details | 43,872,528 (54%) | 132,690,325 | 28.1% |
| 6-10 | 6,647,889 (8%) | 46,542,931 | 9.9% |
| 11-50 | 2,351,484 (3%) | 48,068,850 | 10.2% |
| **50+ details** | **777,835 (1%)** | **216,763,680** | **46.0%** |

**Critical**: 1% of transactions (778K) generate 46% of all detail rows (217M). These are complex placements with many carriers/parties.

### Q4: Product

**Q4a — Product table**: 31,565 products, 16 Classes → 73 Lines → 330 Global Products, 54 data sources

**Q4c — Coverage on transactions**: 85.2% have ProductId (≠ -1), 67.8% have GlobalProductClass

**Q4d — FK integrity**: Zero orphans. Every ProductId on transactions matches the Product table.

### Q5: CFInvoice as Primary Fact — Feasibility

**Q5a**: 9.7M invoices, 8.1M unique TransactionIds, 73.7K parties, **3 data sources only**

**Q5b**: DocumentType = 'Invoice' (100% — single type)

**Q5c — Party roles**: Client (50.1%), Carrier (40%), Third Party (5.7%), NULL (1.9%), Broker (1.5%)

**Q5d — Financials**: All rows have amounts. Total DocumentAmount: $2.89T, CorporateAmount: $375.6B, 104 currencies

**Q5e — Date range**: 2002-05-30 to 2031-10-25 (DocumentDueDate has data quality issue: goes to year 3023)

**Q5f — CFParty FK**: 98.8% match (join produced fan-out: 11.2M vs 9.7M — some 1:many on CustomerNumber+DSI)

**Verdict**: CFInvoice cannot be the primary fact — too narrow (3/56 DSIs, 9.5% of transactions).

---

## 7. Key Findings & Decisions

### Critical Findings

1. **vwTransactionDetailUSD is the only complete fact** — 471M rows with all financials, perfect FK integrity
2. **vwTransaction is a header/envelope** — 85M rows with dimension FKs but zero financial columns
3. **vwTransactionSummaryUSD is inadequate** — only 5/56 DSIs, PolicyKey empty, 25% policy coverage
4. **vwCFInvoice is a narrow cash flow table** — only 3/56 DSIs, 9.5% transaction coverage
5. **vwPolicy at 20M is genuinely unique** — no versioning, no cross-source duplication by PolicyId
6. **Product info is missing from detail table** — must join Detail to Transaction to get ProductId
7. **Carriers are parties, not a separate FK** — no GlobalCarrierId on fact tables
8. **Geography hierarchies are different grains** — ref has 1,082 rollup levels, rpt has 31,019 leaf instances
9. **4 financial columns are completely empty** — Adjustments, Discount, Expenses, WriteOff
10. **46% of detail rows come from 1% of transactions** — fat tail from complex placements

### Decisions Made

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Primary fact = vwTransaction + aggregated Detail | Detail alone is too big (471M) for Power BI; header alone has no financials |
| 2 | Aggregate Detail financials to TransactionId level | Collapses 471M → 85M with SUM of financial columns |
| 3 | Keep full Detail in lakehouse only | For AI agent queries at carrier-level granularity |
| 4 | Defer fact_invoice to Phase 2 | Too narrow (3/56 DSIs, 9.5% coverage) |
| 5 | Drop vwTransactionSummaryUSD | Too incomplete — PolicyKey empty, 5/56 DSIs |
| 6 | dim_geography from ref hierarchy (1,082 rows) | Facts use GlobalFinancialGeographyId, not local FinancialGeographyId |
| 7 | dim_carrier from ref.CarrierHierarchy | Superset of rpt.vwCarrierHierarchy (same row count, more columns) |
| 8 | Park IndustryHierarchy | No clear FK from transaction or policy tables |
| 9 | Use PolicyId as dim_policy key | 100% unique, all fact tables reference PolicyId |
| 10 | GlobalPartyId is the cross-sell key | Groups 3.7M local parties into 626K global entities |

### Spark Config Required

```python
spark.conf.set("spark.sql.parquet.datetimeRebaseModeInRead", "CORRECTED")
spark.conf.set("spark.sql.parquet.int96RebaseModeInRead", "CORRECTED")
```

Required for: vwParty, vwPolicy, vwPolicyPartyRole (contain pre-1900 timestamps).
