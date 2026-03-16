# Source Table Audit — What We Use, What We Don't, and Why

> **Date**: 2026-03-16  
> **Purpose**: Human-friendly review of all 18 PAS silver tables to verify nothing is missed.  
> **How to read**: Each table gets a verdict (✅ Used / ⚠️ Standalone / ❌ Not Used) with a plain-English explanation.

---

## Quick Summary

| # | Source Table | Rows | Gold Table | Verdict |
|---|-------------|------|-----------|---------|
| 1 | ref.CarrierHierarchy | 37K | dim_carrier | ✅ Standalone reference dim |
| 2 | ref.FinancialGeographyHierarchy | 1K | dim_geography | ✅ Used |
| 3 | ref.FinancialSegmentHierarchy | 4K | dim_financial_segment | ✅ Used |
| 4 | ref.IndustryHierarchy | 1K | — | ❌ No FK path to any table |
| 5 | rpt.vwAddress | 3.7M | — | ❌ Parked (could enrich dim_party later) |
| 6 | rpt.vwCarrierHierarchy | 37K | — | ❌ Subset of ref.CarrierHierarchy |
| 7 | rpt.vwCFInvoice | 9.7M | — | ❌ Deferred (too narrow: 3/56 DSIs) |
| 8 | rpt.vwCFParty | 71K | — | ❌ CF-specific party subset |
| 9 | rpt.vwDataSourceInstance | 81 | dim_data_source | ✅ Used |
| 10 | rpt.vwFinancialGeography | 31K | — | ❌ Wrong grain (leaf level, not hierarchy) |
| 11 | rpt.vwParty | 3.7M | dim_party | ✅ Used |
| 12 | rpt.vwPolicy | 20M | dim_policy | ✅ Used |
| 13 | rpt.vwPolicyLayer | 91K | — | ❌ Niche (excess/limit data, 2 DSIs only) |
| 14 | rpt.vwPolicyPartyRole | 48.7M | bridge_policy_party | ✅ Used |
| 15 | rpt.vwProduct | 31K | dim_product | ✅ Used |
| 16 | rpt.vwTransaction | 85M | fact_transaction (header) | ✅ Used |
| 17 | rpt.vwTransactionDetailUSD | 471M | fact_transaction (financials) | ✅ Used (aggregated) |
| 18 | rpt.vwTransactionSummaryUSD | 80M | — | ❌ Too incomplete |

**Score**: 10 of 18 tables used • 1 standalone reference • 7 not used (with documented reasons)

---

## ✅ Tables We Use

---

### 1. rpt.vwTransaction → fact_transaction (header)

**What it is**: Transaction header — one row per business transaction across 54 data sources.

**Why we use it**: Contains all dimension FKs (PolicyId, ProductId, GlobalFinancialGeographyId, GlobalFinancialSegmentId) plus three denormalized party IDs (ClientPartyId, InsuredPartyId, ReinsuredPartyId). This is the backbone of the fact table.

**What it does NOT have**: Any financial columns. Zero. All money lives in the detail table.

**Columns we keep** (24):

| Column | Type | Purpose |
|--------|------|---------|
| TransactionId | int | PK |
| TransactionKey | string | Business key (scoped to DSI) |
| DataSourceInstanceId | int | FK → dim_data_source |
| PolicyId | int | FK → dim_policy |
| ProductId | int | FK → dim_product |
| GlobalFinancialGeographyId | int | FK → dim_geography |
| GlobalFinancialSegmentId | int | FK → dim_financial_segment |
| GlobalLegalEntityId | int | Legal entity reference |
| ClientPartyId | int | Denormalized FK → dim_party (client) |
| InsuredPartyId | int | Denormalized FK → dim_party (insured) |
| ReinsuredPartyId | int | Denormalized FK → dim_party (reinsured) |
| GlobalProductClass | string | Denormalized from product (for quick slicing) |
| GlobalProductLine | string | Denormalized from product |
| GlobalProduct | string | Denormalized from product |
| TransactionDate | timestamp | When the transaction happened |
| InvoiceDate | timestamp | When the invoice was raised |
| TransactionDateKey | int | Derived YYYYMMDD → dim_date |
| InvoiceDateKey | int | Derived YYYYMMDD → dim_date |
| TransactionReference | string | External reference number |
| SegmentCode | string | CRB/HCB/IRR shortcode |
| OwnershipOrganisation | string | Which WTW entity owns this |
| IsDirectSettled | boolean | Direct settlement flag |
| IsFee | boolean | Fee-only transaction flag |
| IsDeleted | boolean | Soft delete |
| IsParentDeleted | boolean | Parent record deleted |

**Columns we drop** (25): SourceQuery, SourceKey, ClientPartyKey, InsuredPartyKey, ReinsuredPartyKey, FinancialGeographyKey, FinancialGeographyId, FinancialSegmentKey, FinancialSegmentId, LegalEntityKey, LegalEntityId, OwnershipOrganisationKey, OwnershipOrganisationId, PolicyKey, PolicySectionKey, PolicySectionId, TransactionStatusKey, TransactionStatusId, ProductKey, GlobalProductClassId, GlobalProductLineId, GlobalProductId, SourceLastUpdateDate, ETLCreatedDate, ETLUpdatedDate, ETLLoadedDate

**Why we drop them**: Redundant Key/Id pairs (we keep Global* versions), audit columns, Source* columns that are internal ETL metadata.

---

### 2. rpt.vwTransactionDetailUSD → fact_transaction (financials)

**What it is**: Line-level financial detail — one row per transaction × party × carrier combination.

**Why we use it**: This is the ONLY table with financial columns (premiums, brokerage, fees, claims). We aggregate it by TransactionId and LEFT JOIN to the header.

**How we use it**: `GROUP BY TransactionId` with SUM on 15 financial columns. This collapses 471M → ~81M groups, which then LEFT JOIN to the 85M header rows.

**Columns we aggregate** (15 financial + 1 count):

| Column | Aggregation | Non-null rows | Coverage |
|--------|------------|--------------|---------|
| GrossPremium | SUM | 91M | 19.4% |
| NetPremium | SUM | 124M | 26.3% |
| GrossBrokerage | SUM | 105M | 22.3% |
| NetBrokerage | SUM | 64M | 13.5% |
| GrossFee | SUM | 12M | 2.5% |
| NetFee | SUM | 11M | 2.4% |
| Claim | SUM | 12M | 2.5% |
| AdditionalCommission | SUM | 7M | 1.5% |
| ContingentCommission | SUM | 762K | 0.2% |
| MarketDerivedIncome | SUM | 9M | 2.0% |
| Deduction | SUM | 2M | 0.5% |
| CostOtherExpense | SUM | 18M | 3.8% |
| CostCompanyExpense | SUM | 5M | 1.1% |
| SharedBrokerage | SUM | 16M | 3.3% |
| SharedFee | SUM | 2M | 0.5% |
| DetailRowCount | COUNT | — | Diagnostic |

**Columns we drop — empty** (4): Adjustments, Discount, Expenses, WriteOff (all have 0 distinct values — completely unpopulated)

**Columns we drop — carrier detail** (lost during aggregation): CarrierOwnRef, IsLeadCarrier, CarrierSignedLinePercentage, CarrierWrittenLinePercentage, AccountPartyId, AccountPartyRole, GlobalPartyId, GlobalPartyRole, Party1-4 columns, all currency columns, all geography/segment columns (already on header)

**What we lose by aggregating**: Carrier-level breakdowns. A single transaction with 5 carriers becomes 1 row with summed financials. For carrier-level analysis, use `fact_transaction_detail` (lakehouse only, Phase 2).

---

### 3. rpt.vwPolicy → dim_policy

**What it is**: Policy master data — 20M genuinely unique policies from 56 global data sources.

**Why it's big**: Not duplicated. Each of 56 data sources contributes unique PolicyIds. Epic US alone has 4.8M policies.

**Columns we keep** (28):

| Column | Type | Purpose |
|--------|------|---------|
| PolicyId | int | PK (100% unique) |
| PolicyKey | string | Business key (not globally unique — 72.6%) |
| DataSourceInstanceId | int | FK → dim_data_source |
| PolicyReference | string | Human-readable policy number |
| PolicyDescription | string | Free text description |
| SegmentCode | string | CRB/HCB/IRR |
| GlobalFinancialGeographyId | int | FK → dim_geography |
| GlobalFinancialSegmentId | int | FK → dim_financial_segment |
| GlobalLegalEntityId | int | Legal entity |
| GlobalCurrencyCode | string | Policy currency |
| InceptionDate | timestamp | When cover starts |
| ExpiryDate | timestamp | When cover ends |
| FirstInceptionDate | timestamp | Original inception (for renewals) |
| RenewalDate | timestamp | Next renewal date |
| PolicyIssuedDate | timestamp | When policy was issued |
| InceptionDateKey | int | Derived YYYYMMDD → dim_date |
| ExpiryDateKey | int | Derived YYYYMMDD → dim_date |
| RefInsuranceType | string | Direct/Reinsurance/Facultative |
| RefPolicyStatus | string | Active/Cancelled/Expired |
| OpportunityType | string | New Business/Renewal/Endorsement |
| OwnershipOrganisation | string | WTW entity that owns it |
| AnnualizedCommission | decimal | Annual commission amount |
| AnnualizedPremium | decimal | Annual premium amount |
| SumInsured | decimal | Total insured value |
| RenewedFromPolicyId | int | Self-referencing FK (renewal chain) |
| IsRenewable | boolean | Can be renewed |
| PolicyIssued | boolean | Has been issued |
| IsDeleted | boolean | Soft delete |

**Columns we drop — CONSTANT** (7): AutoInvoice, AutoRenewal, IsWholeOrder, RetentionStructure, SumInsuredCurrencyKey, SumInsuredCurrencyId, WillisPercentageOfOrder (all 0-1 distinct values)

**Columns we drop — redundant** (many): All Key/Id pairs where we keep the Global version, SourceQuery, SourceKey, ClaimManagementApproach, ParentKey/Id, all *TypeKey/*TypeId/*StatusKey/*StatusId pairs, all ETL dates

---

### 4. rpt.vwParty → dim_party

**What it is**: Master table of all entities — clients, carriers, brokers, third parties. 3.7M rows across 56 data sources.

**Why it's critical**: `GlobalPartyId` groups ~3.7M local parties into ~626K global entities. This is the foundation for cross-sell analysis.

**Columns we keep** (15):

| Column | Type | Purpose |
|--------|------|---------|
| PartyId | int | PK (100% unique) |
| PartyKey | string | Business key (97% unique) |
| PartyName | string | Renamed from "Party" |
| GlobalPartyId | int | Cross-sell grouping key (626K distinct) |
| GlobalPartyRoleId | int | Role code |
| GlobalPartyRole | string | Client/Carrier/Broker/etc. (12 values) |
| CompCode | string | Carrier company code (13,920 distinct — links to dim_carrier) |
| DUNSNumber | string | D&B identifier |
| GlobalCountryId | int | Country FK |
| GlobalCountryCode | string | ISO country code |
| DataSourceInstanceId | int | FK → dim_data_source |
| IsActive | boolean | Active flag |
| IsIndividual | boolean | Person vs Organization |
| PartyRoles | string | Comma-separated role list (27 combinations) |
| IsDeleted | boolean | Soft delete |

**Columns we drop** (22): SourceQuery, SourceKey, PartyMappingKey, BusinessKey, BusinessOwnerOrganisationKey/Id, EmailAddress, GeographyKey, GeographyId, PhoneNumber, ParentKey, ParentId, SourcePartyId, IsObfuscated, LastActivityDate, LastActivityUpdatedDate (CONSTANT), LastUpdatedDate, SourceCreatedDate, all ETL dates

---

### 5. rpt.vwPolicyPartyRole → bridge_policy_party

**What it is**: Many-to-many bridge linking policies to parties with roles. One policy can have multiple parties (client, broker, multiple carriers). One party can appear on many policies.

**Why we use it**: This is the ONLY way to link a client to their policies for cross-sell analysis.

**Columns we keep** (9):

| Column | Type | Purpose |
|--------|------|---------|
| PolicyPartyRoleId | int | PK (100% unique) |
| PolicyId | int | FK → dim_policy |
| PartyId | int | FK → dim_party |
| GlobalPartyId | int | Cross-sell grouping |
| GlobalPartyRoleId | int | Role code |
| GlobalPartyRole | string | Client/Carrier/Broker (12 values) |
| IsPrimaryParty | boolean | Primary party flag (for cross-sell filter) |
| DataSourceInstanceId | int | FK → dim_data_source |
| IsDeleted | boolean | Soft delete |

**Columns we drop** (9): SourceQuery, PartyKey, PolicyKey, PartyRoleKey, PartyRoleId, SourceLastUpdateDate, ETLCreatedDate, ETLUpdatedDate, ETLLoadedDate

**Cross-sell filter**: `WHERE GlobalPartyRole = 'Client' AND IsPrimaryParty = true`

---

### 6. rpt.vwProduct → dim_product

**What it is**: Product catalogue — 31K products organized in a 4-level hierarchy.

**Why we use it**: Products are the cross-sell categories. The 16 GlobalProductClasses define what a client buys.

**Columns we keep** (12):

| Column | Type | Purpose |
|--------|------|---------|
| ProductId | int | PK |
| ProductKey | string | Business key |
| ProductName | string | Renamed from "Product" |
| ProductDescription | string | Description |
| GlobalProductClassId | int | Top hierarchy level (16 values) |
| GlobalProductClass | string | Property/Casualty/Marine/Benefits/etc. |
| GlobalProductLineId | int | Mid hierarchy (73 values) |
| GlobalProductLine | string | Line name |
| GlobalProductId | int | Lower hierarchy (330 values) |
| GlobalProduct | string | Product name |
| DataSourceInstanceId | int | FK → dim_data_source |
| IsDeleted | boolean | Soft delete |

**Columns we drop** (9): SourceQuery, SourceKey, ParentKey, ParentId, IsMDSMappable, SourceLastUpdateDate, ETLCreatedDate, ETLUpdatedDate, ETLLoadedDate

---

### 7. ref.FinancialSegmentHierarchy → dim_financial_segment

**What it is**: WTW's internal financial classification — 5-level hierarchy mapping teams to business segments.

**Why we use it**: SegmentCode (CRB/HCB/IRR) is a primary cross-sell axis. "Does client A buy from both CRB and HCB segments?"

**Hierarchy**: Segment (8) → Business (57) → LOB (177) → ProductService (552) → Team (3,203)

**Columns we keep** (12): GlobalFinancialSegmentId (PK), SegmentCode, SegmentName, BusinessCode, BusinessName, LOBCode, LOBName, ProductServiceCode, ProductServiceName, TeamCode, TeamName, IsDeleted

**Columns we drop** (9): SecurityCode, all Id columns, all ETL dates

---

### 8. ref.FinancialGeographyHierarchy → dim_geography

**What it is**: WTW's geographic hierarchy — 9 levels from Region down to Location.

**Why we use it**: Facts reference `GlobalFinancialGeographyId` (196 distinct values on transactions). This table provides the rollup from location to region.

**Hierarchy**: Region (4) → SubRegion (15) → CountryGroup (16) → Cluster (39) → Country (127) → Division (9) → Market (73) → Office (512) → Location (1,081)

**Columns we keep** (20): GlobalFinancialGeographyId (PK), 9 levels × (Code + Name), IsDeleted

**Columns we drop** (15): LOBId/Code/Name (all CONSTANT — empty), all Id columns, all ETL dates

---

### 9. ref.CarrierHierarchy → dim_carrier

**What it is**: Insurance carrier hierarchy — 37K carriers organized by GlobalParent → OperatingCompany → CarrierName.

**Why we use it**: Standalone reference dimension. Carrier-level analysis requires `fact_transaction_detail` (Phase 2), but this table is ready for when that data becomes available.

**How it connects**: `dim_party.CompCode = dim_carrier.CompCode` for carrier-type parties. Not directly on fact_transaction (carrier info is at detail level only).

**Columns we keep** (9): GlobalCarrierId (PK), CompCode (join key, unique), CarrierName, OperatingCompanyId, OperatingCompany, GlobalParentId, GlobalParent, CountryCode, IsDeleted

**Columns we drop** (4): SourceLastUpdateDate, ETLCreatedDate, ETLUpdatedDate, ETLLoadedDate

---

### 10. rpt.vwDataSourceInstance → dim_data_source

**What it is**: Metadata about the 81 data source systems feeding PAS (56 production + 25 test/deprecated).

**Why we use it**: Every table has `DataSourceInstanceId`. This tells you "this record came from Epic US" or "this came from Eclipse".

**Columns we keep** (7): DataSourceInstanceId (PK), DataSourceInstanceName, DataSourceName, SourceSystem, IsIMRSource, IsEnabled, IsDeleted

**Columns we drop** (5): DataSourceInstanceKey, DataSourceId, SourceLastUpdateDate, ETLCreatedDate, ETLUpdatedDate

---

### 11. dim_date (Generated — no source table)

**What it is**: Calendar dimension generated by PySpark. 13K rows covering 2000-01-01 to 2035-12-31.

**Why we need it**: DateKey columns (YYYYMMDD integers) on fact_transaction and dim_policy join to this table. Supports Australian fiscal year (Jul-Jun).

**Columns** (20): DateKey (PK), FullDate, Year, Quarter, QuarterLabel, Month, MonthName, MonthNameShort, Day, DayOfWeek, DayName, YearMonth, YearMonthLabel, FiscalYear, FiscalYearLabel, FiscalQuarter, FiscalQuarterLabel, FiscalMonth, IsWeekend, IsWeekday

---

## ❌ Tables We Don't Use (and Why)

---

### 12. ref.IndustryHierarchy — ❌ No FK Path

**Rows**: 1,005 | **Columns**: 21

**What it has**: SIC87 industry codes with a 4-level hierarchy (Division → MajorGroup → IndustryGroup → Industry) plus Willis-specific mapping (WillisIndustry → WillisIndustrySector → WillisIndustrySubsector).

**Why we can't use it**: We checked **every column** across all 18 tables. No table has an SIC code, industry ID, or any column that could join to IndustryHierarchy. It's a reference table that PAS loaded but never linked to policies or parties.

**Could we use it later?** Only if PAS adds an industry classification column to vwParty or vwPolicy. Currently impossible.

---

### 13. rpt.vwCarrierHierarchy — ❌ Duplicate of ref

**Rows**: 37,180 | **Columns**: 9

**Why not**: Identical row count to ref.CarrierHierarchy but with fewer columns (9 vs 13). We use the ref version which is a superset. No reason to use both.

---

### 14. rpt.vwCFInvoice — ❌ Too Narrow (Deferred Phase 2)

**Rows**: 9,744,807 | **Columns**: 20

**What it has**: Cash flow invoices with DocumentAmount, CorporateAmount, 104 currencies, PartyId, TransactionId.

**Why not now**: Only 3 out of 56 data sources contribute invoices. Only 9.5% of transactions have an invoice. Building a fact table from this gives a very incomplete picture.

**When to revisit**: If cash flow reporting becomes a priority and stakeholders understand the 3-DSI limitation.

---

### 15. rpt.vwCFParty — ❌ CF-Specific Subset

**Rows**: 70,579 | **Columns**: 9

**What it has**: CustomerNumber, CustomerName, CountryCode — a tiny subset of party data specific to cash flow invoices.

**Why not**: Only relevant if we build fact_invoice. Even then, it's a subset of vwParty — we'd just use vwParty instead.

---

### 16. rpt.vwAddress — ❌ Parked (Enrichment Candidate)

**Rows**: 3,722,322 | **Columns**: 28

**What it has**: AddressLine1-3, City, Country, PostCode, StateOrProvince, EmailAddress, PhoneNumber. One row per address (≈1:1 with parties).

**Why not now**: Not needed for cross-sell or financial reporting. Adding address data to dim_party would make it wider without clear business value yet.

**When to revisit**: If geocoding, territory analysis, or contact information becomes important.

---

### 17. rpt.vwFinancialGeography — ❌ Wrong Grain

**Rows**: 31,019 | **Columns**: 20

**What it has**: Leaf-level financial geography instances with local names and Level1-5 hierarchy.

**Why not**: Fact tables use `GlobalFinancialGeographyId` (only 196 distinct values), which maps to `ref.FinancialGeographyHierarchy` (1,082 rows). This table has 31,019 local instances that don't join cleanly — it's a different grain. Using the ref hierarchy gives us the correct rollup.

---

### 18. rpt.vwPolicyLayer — ❌ Niche

**Rows**: 91,178 | **Columns**: 21

**What it has**: Excess/limit layer data for policies (PolicyLayerExcess, PolicyLayerLimit, PolicyLayerNum, currency).

**Why not**: Only 2 data sources contribute. Only 43K unique policies have layers (out of 20M total). Very niche — relevant only for specialty/London Market reinsurance analysis.

**When to revisit**: If layer-level pricing analysis becomes a requirement.

---

### 19. rpt.vwTransactionSummaryUSD — ❌ Too Incomplete

**Rows**: 80,126,002 | **Columns**: 44

**What it has**: Pre-aggregated transaction data with multi-level party hierarchy and financial columns.

**Why not** (multiple fatal issues):
- **PolicyKey = CONSTANT** (completely empty — zero distinct values)
- **PolicySectionKey = CONSTANT** (empty)
- **GrossBrokerageAndFee = CONSTANT** (empty)
- **NetBrokerageAndFee = CONSTANT** (empty)
- **LowestLevelPartyRole = CONSTANT** (empty)
- **Only 5 data sources** (Eclipse, WIBS, Gras Savoye, COL, Broking.net) vs 56 in other tables
- **Only 5M unique PolicyIds** (vs 15M on vwTransaction)

This table appears to be a legacy pre-aggregation from a subset of sources. It's missing too much data to be useful.

---

## Things That Could Be Missing

| Concern | Status | Notes |
|---------|--------|-------|
| **Currency conversion** | ⚠️ Not in gold layer | vwTransactionDetailUSD already has USD amounts + USDExchangeRate. If local currency analysis needed, would need to add currency columns. |
| **Industry classification** | ❌ Impossible | No FK path from IndustryHierarchy to any other table. |
| **Address/geocoding** | ❌ Parked | vwAddress exists but not linked to gold. Available for future enrichment. |
| **Policy layers (excess/limit)** | ❌ Parked | vwPolicyLayer has only 91K rows from 2 DSIs. |
| **Legal entity dimension** | ⚠️ Not built | GlobalLegalEntityId exists on fact_transaction and dim_policy (91 distinct values) but no source table for legal entity names. Could create a junk dimension from distinct values. |
| **Transaction status** | ❌ Dropped | TransactionStatusKey/Id on vwTransaction (35-61 values) dropped. No reference table for status names found. |
| **Carrier on fact table** | ❌ Not available | Carrier info only at detail level (471M rows). Lost during aggregation. Available in Phase 2 fact_transaction_detail. |

---

## Final Gold Layer — What Gets Built

| Gold Table | Source(s) | Rows | Columns |
|-----------|----------|------|---------|
| dim_date | Generated | 13K | 20 |
| dim_product | vwProduct | 31K | 12 |
| dim_party | vwParty | 3.7M | 15 |
| dim_financial_segment | FinancialSegmentHierarchy | 4K | 12 |
| dim_carrier | CarrierHierarchy | 37K | 9 |
| dim_geography | FinancialGeographyHierarchy | 1K | 20 |
| dim_data_source | vwDataSourceInstance | 81 | 7 |
| dim_policy | vwPolicy | 20M | 28 |
| bridge_policy_party | vwPolicyPartyRole | 48.7M | 9 |
| fact_transaction | vwTransaction + agg(vwTransactionDetailUSD) | 85M | 41 |
| **Total** | | **~157M** | |
