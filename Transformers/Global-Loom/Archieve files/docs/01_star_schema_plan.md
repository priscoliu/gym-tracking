# Phase 1 — Star Schema Implementation Plan

> **Project**: Global Loom  
> **Lakehouse**: `The_Global_Loom`  
> **Date**: 2026-03-13  
> **Status**: Notebooks created, awaiting execution in Fabric  
> **Key Goal**: Build gold layer star schema for Power BI + AI Agent, with cross-sell analysis as primary use case

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Join Map](#2-join-map)
3. [Cross-Sell Design](#3-cross-sell-design)
4. [Table Specifications](#4-table-specifications)
5. [Build Order & Notebooks](#5-build-order--notebooks)
6. [Coding Standards](#6-coding-standards)
7. [Parked / Deferred Items](#7-parked--deferred-items)
8. [Open Questions](#8-open-questions)

---

## 1. Architecture Overview

### Gold Layer Tables (11 total)

```
FACT TABLES (2):
  fact_transaction          ← vwTransaction (85M) + SUM(vwTransactionDetailUSD) by TransactionId
  fact_invoice              ← vwCFInvoice (10M) + vwTransaction enrichment  [DEFERRED Phase 2]

DIMENSION TABLES (7):
  dim_date                  ← Generated (Australian FY Jul-Jun, ~13K rows)
  dim_product               ← rpt.vwProduct (31K rows)
  dim_party                 ← rpt.vwParty (3.7M rows)
  dim_financial_segment     ← ref.FinancialSegmentHierarchy (4K rows)
  dim_carrier               ← ref.CarrierHierarchy (37K rows)
  dim_geography             ← ref.FinancialGeographyHierarchy (1K rows)
  dim_data_source           ← rpt.vwDataSourceInstance (81 rows)

OUTLIER DIMENSION (1):
  dim_policy                ← rpt.vwPolicy (20M rows — genuinely unique, no dedup needed)

BRIDGE TABLE (1):
  bridge_policy_party       ← rpt.vwPolicyPartyRole (48.7M rows)

LAKEHOUSE ONLY (not in Power BI semantic model):
  fact_transaction_detail   ← rpt.vwTransactionDetailUSD (471M rows, full grain for AI agent)
```

### fact_transaction — Build Logic

The primary fact is built by:

1. Read `vwTransaction` (85M rows) — select header columns (dimension FKs, dates, flags)
2. Read `vwTransactionDetailUSD` (471M rows) — aggregate 15 financial columns by TransactionId using SUM
3. LEFT JOIN header + aggregated detail ON TransactionId
4. Coalesce null financials → 0 (for the 4.8% of headers with no detail rows)
5. Derive DateKey columns (YYYYMMDD integers) for TransactionDate and InvoiceDate

```sql
-- Conceptual SQL
SELECT
    t.TransactionId, t.PolicyId, t.ProductId, t.GlobalFinancialGeographyId,
    t.GlobalFinancialSegmentId, t.TransactionDate, t.ClientPartyId, ...
    SUM(d.GrossPremium)     AS GrossPremium,
    SUM(d.NetPremium)       AS NetPremium,
    SUM(d.GrossBrokerage)   AS GrossBrokerage,
    ... (15 financial columns total)
    COUNT(d.TransactionDetailId) AS DetailRowCount
FROM rpt.vwTransaction t
LEFT JOIN rpt.vwTransactionDetailUSD d ON t.TransactionId = d.TransactionId
GROUP BY t.TransactionId, t.PolicyId, ...
```

---

## 2. Join Map

### Relationships with Specific Keys

```
fact_transaction
  → dim_policy                ON PolicyId
  → dim_product               ON ProductId
  → dim_geography             ON GlobalFinancialGeographyId
  → dim_financial_segment     ON GlobalFinancialSegmentId
  → dim_data_source           ON DataSourceInstanceId
  → dim_date                  ON TransactionDateKey (YYYYMMDD int)
  → dim_date                  ON InvoiceDateKey (role-playing)

fact_invoice (Phase 2)
  → dim_policy                ON PolicyId (via Transaction join)
  → dim_product               ON ProductId (via Transaction join)
  → dim_party                 ON PartyId
  → dim_data_source           ON DataSourceInstanceId
  → dim_date                  ON DocumentDateKey

bridge_policy_party
  → dim_policy                ON PolicyId
  → dim_party                 ON PartyId

dim_party
  → dim_carrier               ON CompCode (snowflake — carrier parties only)
```

### Key Join Relationships Between Source Tables

| From → To | Join Key | Type |
|-----------|----------|------|
| vwTransactionDetailUSD → vwTransaction | TransactionId | Many:1 (5.8 avg details per txn) |
| vwCFInvoice → vwTransaction | TransactionId | Many:1 (1.2 avg invoices per txn) |
| vwPolicyPartyRole → vwPolicy | PolicyId | Many:1 |
| vwPolicyPartyRole → vwParty | PartyId | Many:1 |
| vwTransaction → vwPolicy | PolicyId | Many:1 |
| vwTransaction → vwProduct | ProductId | Many:1 |
| vwParty → dim_carrier | CompCode | 1:1 (for carrier parties) |

### How vwTransaction Acts as Central Hub

```
vwCFInvoice →(TransactionId)→ vwTransaction ←(TransactionId)← vwTransactionDetailUSD
                                    │
                    ┌───────────────┼───────────────────┐
                    ↓               ↓                   ↓
               vwPolicy        vwProduct        FinancialGeographyHierarchy
              (PolicyId)      (ProductId)    (GlobalFinancialGeographyId)
```

Invoice and Detail both lack ProductId — they inherit it through Transaction.

---

## 3. Cross-Sell Design

### Business Goal

Identify clients who buy one type of insurance (e.g., Property) but NOT another (e.g., Marine) — these are cross-sell opportunities.

### Cross-Sell Query Path

```
dim_party (filter: GlobalPartyRole = 'Client')
  → bridge_policy_party       ON PartyId (filter: IsPrimaryParty = true)
    → dim_policy               ON PolicyId
      → fact_transaction       ON PolicyId
        → dim_product          ON ProductId  ← "What do they buy?" (16 GlobalProductClasses)
        → dim_financial_segment ON GlobalFinancialSegmentId ← "Which segment?" (CRB/HCB/IRR)
        → dim_geography        ON GlobalFinancialGeographyId ← "Which country?"
```

### Cross-Sell Matrix (conceptual)

| Client (GlobalPartyId) | Property | Casualty | Benefits | Marine | Financial Risk |
|------------------------|----------|----------|----------|--------|---------------|
| Global Client A | ✅ $2M | ✅ $500K | ❌ | ❌ | ✅ $1M |
| Global Client B | ✅ $5M | ❌ | ✅ $3M | ❌ | ❌ |

❌ = cross-sell opportunity

### Critical Fields for Cross-Sell

| Field | Table | Why |
|-------|-------|-----|
| `GlobalPartyId` | dim_party, bridge_policy_party | Groups ~3.7M local parties into ~626K global entities. Without this, same client in different systems looks like different clients. |
| `GlobalProductClass` | dim_product, fact_transaction | The 16 product classes define cross-sell categories |
| `SegmentCode` | dim_financial_segment, fact_transaction | CRB/HCB/IRR are the main business segments — cross-segment selling is highest value |
| `IsPrimaryParty` | bridge_policy_party | Filters to the actual client (not broker, carrier, etc.) |
| `GlobalPartyRole` | bridge_policy_party, dim_party | Must be 'Client' for cross-sell |

---

## 4. Table Specifications

### 4.1 dim_date

| Property | Value |
|----------|-------|
| Grain | One row per calendar date |
| Source | Generated |
| PK | DateKey (int, YYYYMMDD) |
| Rows | ~13,150 |
| Range | 2000-01-01 to 2035-12-31 |

**Columns**: DateKey, FullDate, Year, Quarter, QuarterLabel, Month, MonthName, MonthNameShort, Day, DayOfWeek, DayName, YearMonth, YearMonthLabel, FiscalYear, FiscalYearLabel, FiscalQuarter, FiscalQuarterLabel, FiscalMonth, IsWeekend, IsWeekday

**Fiscal Year**: Australian FY (Jul–Jun). July 2025 = FY2026. FQ1=Jul-Sep, FQ2=Oct-Dec, FQ3=Jan-Mar, FQ4=Apr-Jun.

---

### 4.2 dim_product

| Property | Value |
|----------|-------|
| Grain | One row per ProductId |
| Source | rpt.vwProduct |
| PK | ProductId (int) |
| Rows | 31,565 + 1 Unknown |

**Columns**: ProductId, ProductKey, ProductName (renamed from Product), ProductDescription, GlobalProductClassId, GlobalProductClass, GlobalProductLineId, GlobalProductLine, GlobalProductId, GlobalProduct, DataSourceInstanceId, IsDeleted

**Dropped**: SourceQuery, SourceKey, ParentKey, ParentId, IsMDSMappable, ETL dates

**Hierarchy**: GlobalProductClass (16) → GlobalProductLine (73) → GlobalProduct (330) → Product (31,565)

---

### 4.3 dim_party

| Property | Value |
|----------|-------|
| Grain | One row per PartyId |
| Source | rpt.vwParty |
| PK | PartyId (int) |
| Rows | 3,736,109 + 1 Unknown |
| Spark config | datetime rebase CORRECTED |

**Columns**: PartyId, PartyKey, PartyName (renamed from Party), GlobalPartyId, GlobalPartyRoleId, GlobalPartyRole, CompCode, DUNSNumber, GlobalCountryId, GlobalCountryCode, DataSourceInstanceId, IsActive, IsIndividual, PartyRoles, IsDeleted

**Dropped**: SourceQuery, SourceKey, PartyMappingKey, BusinessKey, BusinessOwnerOrganisationKey/Id, EmailAddress, GeographyKey, GeographyId, PhoneNumber, ParentKey, ParentId, SourcePartyId, IsObfuscated, LastActivityDate, LastActivityUpdatedDate (CONSTANT), LastUpdatedDate, SourceCreatedDate, ETL dates

---

### 4.4 dim_financial_segment

| Property | Value |
|----------|-------|
| Grain | One row per GlobalFinancialSegmentId |
| Source | ref.FinancialSegmentHierarchy |
| PK | GlobalFinancialSegmentId (int) |
| Rows | 3,993 + 1 Unknown |

**Columns**: GlobalFinancialSegmentId, SegmentCode, SegmentName, BusinessCode, BusinessName, LOBCode, LOBName, ProductServiceCode, ProductServiceName, TeamCode, TeamName, IsDeleted

**Hierarchy**: Segment (8) → Business (57) → LOB (177) → ProductService (552) → Team (3,203)

---

### 4.5 dim_carrier

| Property | Value |
|----------|-------|
| Grain | One row per GlobalCarrierId |
| Source | ref.CarrierHierarchy |
| PK | GlobalCarrierId (int) |
| Rows | 37,180 + 1 Unknown |

**Columns**: GlobalCarrierId, CompCode (unique — join key to dim_party), CarrierName, OperatingCompanyId, OperatingCompany, GlobalParentId, GlobalParent, CountryCode, IsDeleted

**Hierarchy**: GlobalParent → OperatingCompany → CarrierName

**Note**: rpt.vwCarrierHierarchy has same row count but fewer columns — ref is the superset.

---

### 4.6 dim_geography

| Property | Value |
|----------|-------|
| Grain | One row per GlobalFinancialGeographyId |
| Source | ref.FinancialGeographyHierarchy |
| PK | GlobalFinancialGeographyId (int) |
| Rows | 1,082 + 1 Unknown |

**Columns**: GlobalFinancialGeographyId, RegionCode, Region, SubRegionCode, SubRegion, CountryGroupCode, CountryGroup, ClusterCode, Cluster, CountryCode, Country, DivisionCode, Division, MarketCode, Market, OfficeCode, Office, LocationCode, Location, IsDeleted

**Dropped**: LOBId/Code/Name (all CONSTANT/empty), all Id columns, ETL dates

**Hierarchy**: Region (4) → SubRegion (15) → CountryGroup (16) → Cluster (39) → Country (127) → Division (9) → Market (73) → Office (512) → Location (1,081)

---

### 4.7 dim_data_source

| Property | Value |
|----------|-------|
| Grain | One row per DataSourceInstanceId |
| Source | rpt.vwDataSourceInstance |
| PK | DataSourceInstanceId (int) |
| Rows | 81 + 1 Unknown |

**Columns**: DataSourceInstanceId, DataSourceInstanceName, DataSourceName, SourceSystem, IsIMRSource, IsEnabled, IsDeleted

---

### 4.8 dim_policy

| Property | Value |
|----------|-------|
| Grain | One row per PolicyId |
| Source | rpt.vwPolicy |
| PK | PolicyId (int) |
| Rows | 20,057,914 + 1 Unknown |
| Spark config | datetime rebase CORRECTED |

**Columns**: PolicyId, PolicyKey, DataSourceInstanceId, PolicyReference, PolicyDescription, SegmentCode, GlobalFinancialGeographyId, GlobalFinancialSegmentId, GlobalLegalEntityId, GlobalCurrencyCode, InceptionDate, ExpiryDate, FirstInceptionDate, RenewalDate, PolicyIssuedDate, InceptionDateKey (derived YYYYMMDD), ExpiryDateKey (derived YYYYMMDD), RefInsuranceType, RefPolicyStatus, OpportunityType, OwnershipOrganisation, AnnualizedCommission, AnnualizedPremium, SumInsured, RenewedFromPolicyId, IsRenewable, PolicyIssued, IsDeleted

**Dropped (CONSTANT)**: AutoInvoice, AutoRenewal, IsWholeOrder, RetentionStructure, SumInsuredCurrencyKey, SumInsuredCurrencyId, WillisPercentageOfOrder

**Dropped (redundant/audit)**: SourceQuery, SourceKey, ClaimManagementApproach, all Key/Id pairs (keep GlobalIds), ParentKey/Id, PolicyTypeKey/Id, PolicyStatusKey/Id, InsuranceTypeKey/Id, OpportunityTypeKey/Id, LegalEntityKey/Id, OwnershipOrganisationKey/Id, CurrencyKey/Id, FinancialGeographyKey/Id, FinancialSegmentKey/Id, ETL dates

---

### 4.9 bridge_policy_party

| Property | Value |
|----------|-------|
| Grain | One row per PolicyPartyRoleId (Policy × Party × Role) |
| Source | rpt.vwPolicyPartyRole |
| PK | PolicyPartyRoleId (int) |
| Rows | 48,740,661 |
| Spark config | datetime rebase CORRECTED |

**Columns**: PolicyPartyRoleId, PolicyId (FK dim_policy), PartyId (FK dim_party), GlobalPartyId, GlobalPartyRoleId, GlobalPartyRole, IsPrimaryParty, DataSourceInstanceId, IsDeleted

**Dropped**: SourceQuery, PartyKey, PolicyKey, PartyRoleKey, PartyRoleId, ETL dates

---

### 4.10 fact_transaction (Primary Fact)

| Property | Value |
|----------|-------|
| Grain | One row per TransactionId |
| Source | rpt.vwTransaction LEFT JOIN aggregated rpt.vwTransactionDetailUSD ON TransactionId |
| PK | TransactionId (int) |
| Rows | ~85,262,175 |
| Spark config | datetime rebase CORRECTED, adaptive query enabled |

**Header columns** (from vwTransaction):
TransactionId, TransactionKey, DataSourceInstanceId, PolicyId, ProductId, GlobalFinancialGeographyId, GlobalFinancialSegmentId, GlobalLegalEntityId, ClientPartyId, InsuredPartyId, ReinsuredPartyId, GlobalProductClass, GlobalProductLine, GlobalProduct, TransactionDate, InvoiceDate, TransactionDateKey (derived), InvoiceDateKey (derived), TransactionReference, SegmentCode, OwnershipOrganisation, IsDirectSettled, IsFee, IsDeleted, IsParentDeleted

**Aggregated financial columns** (SUM from vwTransactionDetailUSD grouped by TransactionId):
GrossPremium, NetPremium, GrossBrokerage, NetBrokerage, GrossFee, NetFee, Claim, AdditionalCommission, ContingentCommission, MarketDerivedIncome, Deduction, CostOtherExpense, CostCompanyExpense, SharedBrokerage, SharedFee, DetailRowCount

**Null handling**: Financial columns coalesced to 0 for the 4.8% of headers with no detail rows.

**Dropped from Detail**: Adjustments, Discount, Expenses, WriteOff (all empty), carrier columns, party1-4 columns, all Keys/ETL dates

---

### 4.11 fact_invoice (DEFERRED — Phase 2)

| Property | Value |
|----------|-------|
| Grain | One row per DocumentKey |
| Source | rpt.vwCFInvoice LEFT JOIN rpt.vwTransaction ON TransactionId |
| PK | DocumentKey (string) |
| Rows | 9,744,807 |
| Status | **Deferred** — only 3/56 DSIs, 9.5% transaction coverage |

**Columns**: DocumentKey, TransactionId, PolicyId (from txn), ProductId (from txn), GlobalFinancialGeographyId (from txn), GlobalFinancialSegmentId (from txn), PartyId, DataSourceInstanceId, DocumentDateKey (derived), DocumentDueDateKey (derived), DocumentDate, DocumentDueDate, DocumentAmount, CorporateAmount, Currency, Company, CompanyCode, CustomerNumber, DocumentNumber, GlobalPartyRole, DirectSettlement

---

## 5. Build Order & Notebooks

| # | Notebook | Gold Table | Rows | Status |
|---|----------|-----------|------|--------|
| 1 | `03_gold_dim_date.ipynb` | dim_date | ~13K | ✅ Created |
| 2 | `03_gold_dim_product.ipynb` | dim_product | 31K | ✅ Created |
| 3 | `03_gold_dim_party.ipynb` | dim_party | 3.7M | ✅ Created |
| 4 | `03_gold_dim_financial_segment.ipynb` | dim_financial_segment | 4K | ✅ Created |
| 5 | `03_gold_dim_carrier.ipynb` | dim_carrier | 37K | ✅ Created |
| 6 | `03_gold_dim_geography.ipynb` | dim_geography | 1K | ✅ Created |
| 7 | `03_gold_dim_data_source.ipynb` | dim_data_source | 81 | ✅ Created |
| 8 | `03_gold_dim_policy.ipynb` | dim_policy | 20M | ✅ Created |
| 9 | `03_gold_bridge_policy_party.ipynb` | bridge_policy_party | 48.7M | ✅ Created |
| 10 | `03_gold_fact_transaction.ipynb` | fact_transaction | 85M | ✅ Created |
| 11 | `03_gold_fact_invoice.ipynb` | fact_invoice | 9.7M | ❌ Deferred |
| 12 | `03_gold_fact_transaction_detail.ipynb` | fact_transaction_detail | 471M | ❌ Deferred |

### Notebook Template (consistent across all notebooks)

```
Cell 1: Setup & Config (imports, Spark config, table names)
Cell 2: Read silver source + printSchema + count
Cell 3: Transform (select columns, rename, derive DateKeys)
Cell 4: Add "Unknown" member row (for -1 sentinels) — dims only
Cell 5: DQ checks (duplicates, nulls, assertions)
Cell 6: Write to gold Delta table (overwrite mode)
```

fact_transaction has 7 cells (extra cell for reading + aggregating detail).

---

## 6. Coding Standards

| Standard | Implementation |
|----------|---------------|
| Column naming | PascalCase: `PolicyNumber`, `TransactionDate` |
| Surrogate keys | `[Entity]Key` — e.g., `PolicyKey`, `CarrierKey` |
| Date keys | `[Role]DateKey` — e.g., `TransactionDateKey` (YYYYMMDD int) |
| Write mode | `mode("overwrite").option("overwriteSchema", "true")` — idempotent |
| PySpark for transforms | Spark SQL for simple SELECTs |
| Join keys | `F.trim(F.upper())` on both sides (where applicable) |
| Sentinel values | `-1` → "Unknown" member row in each dimension |
| DQ checks | Duplicate PKs, null PKs, assertion failures halt execution |
| Financial nulls | Coalesced to 0 in fact tables |
| Spark config | datetime rebase CORRECTED for pre-1900 timestamps |
| Delta format | `format("delta")` — required for Direct Lake |

---

## 7. Parked / Deferred Items

| Item | Status | Reason | When to Revisit |
|------|--------|--------|-----------------|
| `fact_invoice` | Deferred Phase 2 | Only 3/56 DSIs, 9.5% txn coverage | When cash flow reporting is needed |
| `fact_transaction_detail` | Deferred | 471M rows — lakehouse only for AI | When AI agent needs carrier-level detail |
| `IndustryHierarchy` | Parked | No visible FK from transactions/policies | Investigate if SIC codes link to parties |
| `vwPolicyLayer` | Parked | Only 91K rows, niche | If excess/limit analysis needed |
| `vwAddress` | Parked | Could extend dim_party | If address-level analysis needed |
| `vwCFParty` | Parked | 70K rows, CF party subset | If cash flow party enrichment needed |
| `vwTransactionSummaryUSD` | Dropped | PolicyKey empty, 5/56 DSIs only | Not recommended |
| Carrier FK on fact | Known gap | Carriers are parties, not separate FK | Could denormalize carrier info onto fact |

---

## 8. Open Questions — ✅ RESOLVED

| # | Question | Answer | Impact |
|---|----------|--------|--------|
| 1 | **Fabric SKU / capacity level** | **F16** | ✅ F16 can handle 85M fact + 20M dim_policy via Direct Lake. Row limit: 300M per table. Total model: ~1.5B rows supported. |
| 2 | **PolicyKey uniqueness** | **PolicyId is unique** (100%). PolicyKey is NOT unique (72.6% = 14.5M / 20M). | ✅ Use `PolicyId` as PK. `PolicyKey` is a business key scoped within data source. |
| 3 | **Which 3 DSIs feed CFInvoice?** | **3 data sources** (untitled (17).json shows 3 total) | ✅ Confirmed: CFInvoice coverage is narrow (3/56 DSIs). Deferred to Phase 2 as planned. |
| 4 | **Industry linkage path** | **SIC codes → parties** (user confirmed industry dimension needed) | ✅ **Action required**: Create `03_gold_dim_industry.ipynb`. Link via SIC code fields on party or policy tables. |
| 5 | **dim_carrier connection strategy** | **Denormalize onto dim_party** (user prefers star schema, not snowflake) | ✅ **Decision**: Add carrier hierarchy columns to `dim_party` for parties with `GlobalPartyRole = 'Carrier'`. Drop separate `dim_carrier` table to maintain star schema pattern. |
