# Gold Layer Documentation — R&B SalesOps

## Overview

The Gold layer is a star schema built from PAS (Policy Administration System) Silver layer tables in Microsoft Fabric. It powers cross-sell, white space, and premium placement analysis for the R&B SalesOps team.

**Architecture:** PAS Silver (source) → Gold (this layer) → Power BI (consumption)

---

## Gold Tables

| Notebook | Gold Table | Grain | Source Tables |
|----------|-----------|-------|---------------|
| 01_dim_client.py | Gold_SalesOps_Dim_Client | 1 row per PartyId (source-level party) | Party + PartyDetails |
| 02_dim_financial_geography.py | Gold_SalesOps_Dim_FinancialGeography | 1 row per GlobalFinancialGeographyId | FinancialGeographyHierarchy |
| 03_fact_transaction.py | Gold_SalesOps_Fact_Transaction | 1 row per TransactionDetailId | TransactionDetail + Transaction + Policy + Product + Organisation |
| 04_fact_transaction_premium.py | Gold_SalesOps_Fact_TransactionPremium | 1 row per ClientUnderwriterPremiumId | ClientUnderwriterPremium + Transaction + Policy + Organisation |
| 05_dim_policy.py | Gold_SalesOps_Dim_Policy | 1 row per PolicyId | Policy |
| 06_dim_product.py | Gold_SalesOps_Dim_Product | 1 row per ProductId | Product |
| 07_dim_organisation.py | Gold_SalesOps_Dim_Organisation | 1 row per OrganisationId | Organisation |
| 08_cross_sell_checks_and_views.ipynb | Gold_SalesOps_Dim_ProductLine | 1 row per GlobalProductLineId | Gold_SalesOps_Fact_Transaction |

---

## Dim_Client (01_dim_client.py)

### Grain
One row per **PartyId** — the source-level party identifier. One entity (e.g., "Singtel") may have multiple PartyIds across different source systems (Epic, Eclipse, WIBS, etc.), all linked by a single **GlobalPartyId**.

### Source Tables & Join Path
```
Party (base — all source-level party records)
  └── LEFT JOIN PartyDetails ON GlobalPartyId
        └── LEFT JOIN PartyDetails (self-join) ON GUOPartyId → GUOClientName
```

### Key Fields
| Field | Description |
|-------|-------------|
| PartyId | Source-level party ID (primary key) |
| GlobalPartyId | Cross-source deduplicated party ID |
| ClientName | Party name from source system |
| GUOPartyId | Global Ultimate Owner (parent company) |
| GUOClientName | GUO name (resolved via self-join to PartyDetails) |
| Segmentation | Client segmentation tier |
| IndustryName/GroupName/MajorGroupName/DivisionName | Industry classification hierarchy |
| CountryName, CountryCode, City, State | Location |
| DUNSNumber | Dun & Bradstreet identifier |
| TotalEmployeeCount, OperatingRevenueUSD | Firmographics |
| OwnershipType, PartyType, IsIndividual | Party classification |

### Key Decisions
- **PartyId as grain**, not GlobalPartyId — because the fact table needs to join at the source-level party to trace from TransactionDetail → Transaction → Party
- **No IsActive filter** — all parties included regardless of status
- **PartyDetails is 1 row per GlobalPartyId** — confirmed unique, safe LEFT JOIN with no dedup needed

---

## Dim_FinancialGeography (02_dim_financial_geography.py)

### Grain
One row per **GlobalFinancialGeographyId** — WTW's financial reporting geography.

### Source Table
Single table: `FinancialGeographyHierarchy` — no joins required.

### Key Fields
| Field | Description |
|-------|-------------|
| GlobalFinancialGeographyId | Primary key |
| Region | Top-level region (e.g., International, North America) |
| SubRegion | Sub-region |
| CountryGroup | Country grouping |
| Cluster | Cluster grouping |
| Country | Country name |
| CountryCode | ISO country code |

---

## Fact_Transaction (03_fact_transaction.py)

### Grain
One row per **TransactionDetailId** — the most granular transaction record. This is the raw grain from the source system, not aggregated.

### Volume
400M+ rows and growing.

### Source Tables & Join Path
```
TransactionDetail (base — 400M+ rows, filtered: IsDeleted=False, PolicyId != -1)
  ├── LEFT JOIN Transaction ON TransactionId
  │     → Brings: InsuredPartyId, ClientPartyId
  │     → COALESCE(InsuredPartyId, ClientPartyId) = ClientPartyId
  │
  ├── LEFT JOIN Policy ON PolicyId
  │     → Brings: InceptionDate, FirstInceptionDate, ExpiryDate, RenewalDate, RefInsuranceTypeId, RefInsuranceType
  │     → PolicyId is UNIQUE in Policy — safe join, zero duplicate risk
  │
  ├── LEFT JOIN Product ON ProductId
  │     → Brings: GlobalProductClassId/Line/Product (fallback for NULL values in TransactionDetail)
  │     → ProductId is UNIQUE in Product — safe join, zero duplicate risk
  │     → COALESCE(TD.GlobalProductLineId, Product.GlobalProductLineId) fills 24% NULL gap
  │
  └── LEFT JOIN Organisation ON OwnershipOrganisationId = OrganisationId
        → Brings: Organisation name (WTW team/office)
        → OrganisationId is UNIQUE in Organisation — safe join, zero duplicate risk
```

### Join Key Validation (tested)
| Join | Key | Unique? | Duplicate Risk |
|------|-----|---------|----------------|
| TD → Transaction | TransactionId | Yes in Transaction | None |
| TD → Policy | PolicyId | Yes in Policy | None |
| TD → Product | ProductId | Yes in Product | None |
| TD → Organisation | OwnershipOrganisationId = OrganisationId | Yes in Organisation | None |

### Client Resolution
TransactionDetail does NOT have the client directly. The client is resolved via:
1. Join TransactionDetail → Transaction on TransactionId
2. Transaction has `InsuredPartyId` and `ClientPartyId`
3. `COALESCE(InsuredPartyId, ClientPartyId)` = the insured client
4. This `ClientPartyId` joins to `Dim_Client.PartyId` for the client name

### Product Resolution
TransactionDetail has `GlobalProductLineId` but 24% are NULL. Resolved via COALESCE:
1. TransactionDetail.GlobalProductLineId (76% populated)
2. Product table lookup via ProductId (fills some of the 24% gap — Product table has 56% global mapping coverage)
3. NULL (genuinely unmapped source-specific products)

### UW & Pool Resolution (for ShareBroker rows)
For network/inbound placements, the AccountPartyRole = "ShareBroker" and the actual UW/Pool is hidden in Party1-Party4 columns. Two derived columns extract them:

- **UWPartyId**: For ShareBroker rows → scan Party1Role through Party4Role for "UW" and take the corresponding PartyId. For UW/Carrier rows → use AccountPartyId directly.
- **PoolPartyId**: Same logic but scanning for "Pool" role.

Validation: 95.1% of ShareBroker rows have a UW in Party1-4. 10.1% have a Pool. Zero rows have multiple UWs.

### Revenue Columns (USD)
All amounts converted to USD via `Amount × USDExchangeRate`. NULL amounts treated as 0.

| Column | Description |
|--------|-------------|
| GrossBrokerageUSD | Gross brokerage |
| NetBrokerageUSD | Net brokerage |
| **NetBrokerageUSD_Adj** | COALESCE: if NetBrokerageUSD is 0, use GrossBrokerageUSD |
| GrossFeeUSD | Gross fee |
| NetFeeUSD | Net fee |
| **NetFeeUSD_Adj** | COALESCE: if NetFeeUSD is 0, use GrossFeeUSD |
| AdditionalCommissionUSD | Additional commission |
| ContingentCommissionUSD | Contingent commission |
| MarketDerivedIncomeUSD | Market derived income |
| GrossPremiumUSD | Gross premium |
| NetPremiumUSD | Net premium |
| TotalWTWRevenueUSD | NetBrokerage + NetFee + AdditionalCommission + ContingentCommission + MarketDerivedIncome |
| **TotalWTWRevenueUSD_Adj** | Same formula but using NetBrokerageUSD_Adj + NetFeeUSD_Adj |

### AccountPartyRole Patterns (discovered via data analysis)
Revenue and premium flow differently depending on the placement type:

| Pattern | AccountPartyRole | What it carries |
|---------|-----------------|-----------------|
| **Direct placement** | Client | GrossPremium only |
| | UW/Carrier | NetPremium only |
| | Bureau (ILU, LPSO) | NetPremium + TotalWTWRevenue |
| **Network/inbound** | Client | GrossPremium only |
| | ShareBroker | GrossBrokerage (positive) + NetPremium (negative) |
| | ThirdParty | Negative SharedBrokerage or zero |
| **US billing** | Billing Company | Acts as insurer — premium sits here |
| **Fee-only policies** | Client | NetFee only, no premium |

- ~0.05% of clients (6,086 out of 12M) have ShareBroker revenue — network placements are edge cases
- ShareBroker revenue contribution varies widely (2% to 96%) per client

### CRITICAL: Premium Calculation Rules for Power BI

**Always filter by `GlobalPartyRoleId`, never trust `AccountPartyRole` alone.** AccountPartyRole can be misleading — e.g., a fronting carrier (Zurich) may appear as AccountPartyRole = "Client" but GlobalPartyRoleId = 102 (Carrier).

| Question | Column | Filter | Why |
|----------|--------|--------|-----|
| "What did the client pay?" | GrossPremiumUSD | GlobalPartyRoleId = 100 | Client-side view only |
| "Which insurer underwrites the risk?" | NetPremiumUSD | GlobalPartyRoleId = 102 | Actual risk-taker only |
| "What is WTW's revenue?" | TotalWTWRevenueUSD_Adj | No role filter, sum all | Revenue sits on different roles depending on placement type |

### GlobalPartyRoleId Reference

| GlobalPartyRoleId | GlobalPartyRole |
|---|---|
| 100 | Client |
| 101 | Insured |
| 102 | Carrier |
| 103 | Client (Prospective) |
| 104 | Third Party - Other |
| 107 | Agent - other |
| 113 | Third Party - Co-Broker |
| 117 | Third Party - Introducer |
| 118 | Third Party - Introducer Consultant |
| 121 | Third Party - Producing Broker |

### Common Traps — DO NOT

- **DO NOT** sum GrossPremiumUSD without filtering by GlobalPartyRoleId = 100 → double/triple counts (same premium appears on Client, Bureau, ShareBroker rows)
- **DO NOT** sum NetPremiumUSD without filtering by GlobalPartyRoleId = 102 → mixes client premium with insurer premium (opposite signs on ShareBroker rows)
- **DO NOT** assume AccountPartyRole = "Client" means the actual insured → could be a fronting carrier (e.g., Zurich collects premium but XL Re underwrites the risk)
- **DO NOT** sum GrossPremiumUSD + NetPremiumUSD together → they are two views of the same money, not additive
- **DO NOT** use Bureau rows (ILU, LPSO) for insurer analysis → Bureaus are settlement/processing agents, not risk-takers

### Fronting Carriers

A "fronting carrier" issues the policy and collects premium but passes the risk to another insurer. In the data:
- **Fronting carrier** appears as GlobalPartyRoleId = 100 with GrossPremium (client paid premium to them)
- **Actual underwriter** appears as GlobalPartyRoleId = 102 with NetPremium (they take the risk)

Example: Client pays Zurich (fronting) → Zurich passes risk to XL Re Europe (actual UW). Both appear in the data for the same policy.

### Key Dimensions & Joins
```
Dim_Client ─────────── ClientPartyId ──────┐
Dim_Client (as AcctParty) ─ AccountPartyId ┤
Dim_Client (as UW) ──── UWPartyId ─────────┤
Dim_Client (as Pool) ── PoolPartyId ───────┤  Fact_Transaction
Dim_FinancialGeography ─ GlobalFinGeoId ───┤
Dim_Policy ──────────── PolicyId ───────────┤
                                            │
Dim_Organisation ←── Dim_Policy.OwnershipOrganisationId
Dim_Product ←── standalone lookup by GlobalProductLineId
```

```
Dim_Client ────────── ClientPartyId ───────┐
Dim_Client (as UW) ── UWGlobalPartyId ─────┤  Fact_TransactionPremium
Dim_Policy ─────────── PolicyId ────────────┤  (Note: UW joins on GlobalPartyId, not PartyId!)
```
All four party dimension roles use the **same physical Gold table** (Gold_SalesOps_Dim_Client), aliased with different names in Power BI.

### Date Columns
| Column | Source | Description |
|--------|--------|-------------|
| TransactionDate | TransactionDetail | When the transaction occurred |
| TransactionDetailDate | TransactionDetail | Detail-level date |
| GLAccountingDate | TransactionDetail | GL accounting period |
| InceptionDate | Policy | Policy inception date |
| FirstInceptionDate | Policy | Original first inception |
| ExpiryDate | Policy | Policy expiry |
| RenewalDate | Policy | Renewal date |
| InceptionYear | Derived | YEAR(InceptionDate) — used for YoY analysis |

---

## Fact_TransactionPremium (04_fact_transaction_premium.py)

### Purpose
Premium placement detail showing how premium flows between client, underwriter, and intermediaries. Provides **explicit underwriter columns** (unlike Fact_Transaction where UW is derived from Party1-4 fields). Use this table for underwriter analysis, market share, placement details, and written/signed line analysis.

### Grain
One row per **ClientUnderwriterPremiumId** — each record represents one client-underwriter premium allocation on a policy section transaction.

### Volume
Large (comparable to Fact_Transaction). Always use WHERE filters.

### Source Tables & Join Path
```
ClientUnderwriterPremium (base, filtered: IsDeleted=False, PolicyId != -1)
  ├── LEFT JOIN Transaction ON TransactionId
  │     → Brings: InsuredPartyId, ClientPartyId, OwnershipOrganisationId
  │     → Brings: ProductKey, GlobalProductClassId/Line/Product (product columns)
  │     → COALESCE(InsuredPartyId, ClientPartyId) = ClientPartyId
  │
  ├── LEFT JOIN Policy ON PolicyId
  │     → Brings: InceptionDate, FirstInceptionDate, ExpiryDate, RenewalDate, RefInsuranceTypeId, RefInsuranceType
  │     → PolicyId is UNIQUE in Policy — safe join, zero duplicate risk
  │
  └── LEFT JOIN Organisation ON OwnershipOrganisationId = OrganisationId
        → Brings: Organisation name (WTW team/office)
```

### Key Fields
| Field | Description |
|-------|-------------|
| ClientUnderwriterPremiumId | Primary key — premium allocation record |
| PolicyId, PolicySectionId, TransactionId | Links to policy and transaction |
| ClientPartyId | Insured client (COALESCE of InsuredPartyId, ClientPartyId from Transaction) |
| Organisation | WTW team/office (NOT the client) |

### Underwriter Columns (explicit — not derived)
| Field | Description |
|-------|-------------|
| Underwriter | Underwriter name |
| UnderwriterId | Underwriter party ID |
| UWGlobalPartyId | Cross-source deduplicated UW party ID. **Joins to Dim_Client.GlobalPartyId** (not PartyId!) |
| UWRole | Underwriter role |
| UWCountry | Underwriter country |
| UWParent | Underwriter parent company |
| UWDescName | Underwriter descriptive name |

### Market & Placement Details
| Field | Description |
|-------|-------------|
| Lead | Lead underwriter indicator |
| WrittenLine | Written line percentage |
| SignedLine | Signed line percentage |
| PlacementType | Placement type |
| MarketLevel1-4 | Market hierarchy (4 levels) |
| MarketRole1 | Market role |
| Bureau, BureauId | Bureau name and ID (ILU, LPSO, etc.) |
| CoBroker, CoBrokerId | Co-broker name and ID |

### Revenue Columns (USD)
All amounts converted to USD via `Amount × USDExchangeRate`. NULL amounts treated as 0.

| Column | Description |
|--------|-------------|
| ClientGrossPremiumUSD | Client gross premium — what the client pays |
| ClientNetPremiumUSD | Client net premium |
| UWGrossPremiumUSD | Underwriter gross premium |
| UWNetPremiumUSD | Underwriter net premium — what the UW receives |
| ClientCommissionUSD | Client commission |
| ClientFeeUSD | Client fee |
| ClientMDIUSD | Client market derived income |
| UWMDIUSD | Underwriter MDI |
| UWFeeUSD | Underwriter fee |
| GrossBrokerageUSD | Gross brokerage |
| GrossPremiumUSD | Gross premium |
| WTWNetRevenueUSD | WTW net revenue |
| WTWGrossRevenueUSD | WTW gross revenue |
| ContingentCommissionUSD | Contingent commission |
| ClientAdditionalCommissionUSD | Client additional commission |
| UWAdditionalCommissionUSD | Underwriter additional commission |

### Key Decisions
- **Why a separate table from Fact_Transaction?** Fact_Transaction is built from TransactionDetail (the broadest transaction grain with all AccountPartyRoles). Fact_TransactionPremium is built from ClientUnderwriterPremium (a pre-joined Silver table with explicit UW columns). Use Fact_Transaction for revenue/client/product analysis; use Fact_TransactionPremium for UW/market/placement analysis.
- **UWGlobalPartyId joins on GlobalPartyId**, not PartyId — different from Fact_Transaction's UWPartyId which joins on PartyId. This is because the CUP table uses the cross-source deduplicated UW identity.
- **Product columns come from Transaction table**, not from a Product table join — the Transaction table carries denormalized product fields.

### When to Use Which Fact Table

| Question | Use |
|----------|-----|
| "What is WTW's revenue?" | Fact_Transaction |
| "Who are our top clients?" | Fact_Transaction |
| "Which products does client X buy?" | Fact_Transaction |
| "Which underwriters write the most premium?" | **Fact_TransactionPremium** |
| "What is the written line for this placement?" | **Fact_TransactionPremium** |
| "Market share by insurer?" | **Fact_TransactionPremium** |
| "Who is the lead underwriter?" | **Fact_TransactionPremium** |

---

## Dim_Policy (05_dim_policy.py)

### Grain
One row per **PolicyId** — confirmed unique in the Policy table.

### Source Table
Single table: `Policy` (Silver) — no joins required.

### Key Fields
| Field | Description |
|-------|-------------|
| PolicyId | Primary key |
| SourceId | Source system identifier |
| PolicyKey | Source-level policy key |
| InceptionDate | Policy inception date |
| FirstInceptionDate | Original first inception (for renewal chains) |
| ExpiryDate | Policy expiry date |
| RenewalDate | Renewal date |
| PolicyReference | Policy reference number |
| PolicyDescription | Policy description text |
| RefPolicyStatusId | Policy status ID |
| RefPolicyStatus | Policy status name (Active, Lapsed, Cancelled, etc.) |
| RefInsuranceTypeId | Insurance type ID (100=Insurance, 101=Reinsurance, 102=Advisory) |
| RefInsuranceType | Insurance type name |
| OpportunityType | Opportunity classification |
| IsRenewable | Whether policy is renewable |
| IsWholeOrder | Whole-order flag |
| GlobalCurrencyCode | Policy currency |
| OwnershipOrganisationId | FK → Dim_Organisation (WTW team that owns this policy) |
| OwnershipOrganisation | WTW team name (denormalized) |
| GlobalFinancialGeographyId | FK → Dim_FinancialGeography |
| GlobalFinancialSegmentId | Financial segment ID (no Gold dimension table for this) |
| GlobalLegalEntityId | Legal entity |
| RenewedFromPolicyId | Previous policy in renewal chain (NULL if not a renewal) |

### Key Decisions
- **Separate dimension** — policy-level attributes (status, renewal chain, ownership) can be queried directly without hitting the 400M+ fact table.
- **RenewedFromPolicyId** enables tracing renewal chains — follow the chain backward to find the original policy.
- **OwnershipOrganisation is denormalized** — the WTW team name is included directly, but `OwnershipOrganisationId` also joins to Dim_Organisation for hierarchy analysis.

---

## Dim_Product (06_dim_product.py)

### Grain
One row per **ProductId** — the source-level product identifier. Confirmed unique.

### Source Table
Single table: `Product` (Silver) — no joins required.

### Key Fields
| Field | Description |
|-------|-------------|
| ProductId | Primary key (source-level product) |
| SourceId | Source system identifier |
| ProductKey | Source-level product key |
| Product | Product name (source-specific) |
| ProductDescription | Product description |
| GlobalProductClassId | Product class ID — top of hierarchy (nullable) |
| GlobalProductClass | Product class name (e.g., "Property", "Casualty") |
| GlobalProductLineId | Product line ID — mid-level (nullable) |
| GlobalProductLine | Product line name (e.g., "Property D&F", "General Liability") |
| GlobalProductId | Specific product ID — bottom of hierarchy (nullable) |
| GlobalProduct | Product name (most specific level) |

### Product Hierarchy
```
GlobalProductClass (broadest — e.g., "Property", "Casualty")
  └── GlobalProductLine (mid — e.g., "Property D&F", "General Liability")
        └── GlobalProduct (finest — specific product)
```

### Key Decisions
- **Global fields are nullable** — some source systems (e.g., source 50502, Latin America) have all `GlobalProductClassId/LineId/ProductId` as NULL. These products are unmapped to the global taxonomy.
- **Fact table carries denormalized product columns** — Fact_Transaction already has GlobalProductClassId/Line/Product via COALESCE. This dimension is for standalone product lookups and product hierarchy browsing, not typically joined to the fact table (the fact already has the product columns).
- **Cross-sell analysis uses GlobalProductLine** — this is the mid-level grouping that defines "product lines" for white space analysis.

---

## Dim_Organisation (07_dim_organisation.py)

### Grain
One row per **OrganisationId** — a unique WTW team, office, or entity.

### Source Table
Single table: `Organisation` (Silver) — no joins required.

### ⚠️ CRITICAL: Organisation ≠ Client
This table represents **WTW's own internal structure** — companies, branches, departments, offices. It is **NOT** the client. Clients come from `Dim_Client` (Party + PartyDetails).

`Dim_Organisation` shows which WTW team owns a policy (via `Dim_Policy.OwnershipOrganisationId`). The `Organisation` column on fact tables is denormalized from this dimension.

### Key Fields
| Field | Description |
|-------|-------------|
| OrganisationId | Primary key — WTW organisation unit ID |
| SourceId | Source system identifier |
| OrganisationKey | Source-level organisation key |
| Organisation | WTW team/office/entity name |
| Level1 | Hierarchy level 1 (broadest) |
| Level2 | Hierarchy level 2 |
| Level3 | Hierarchy level 3 |
| Level4 | Hierarchy level 4 (most specific) |
| Level1Code | Level 1 code |
| Level2Code | Level 2 code |
| Level3Code | Level 3 code |
| Level4Code | Level 4 code |
| ParentId | Parent organisation ID (for recursive hierarchy traversal, nullable) |

### Key Decisions
- **4-level hierarchy** — Level1 is the broadest (e.g., company), Level4 is the most specific (e.g., team).
- **ParentId** enables recursive hierarchy queries if needed.
- **Joined to fact tables via Dim_Policy** — `Dim_Policy.OwnershipOrganisationId` → `Dim_Organisation.OrganisationId`. Not directly joined to fact tables (the `Organisation` column on facts is denormalized).

---

## Dim_ProductLine (08_cross_sell_checks_and_views.ipynb)

### Grain
One row per **GlobalProductLineId**.

### Source Table
Derived view over `Gold_SalesOps_Fact_Transaction`.

### Key Fields
| Field | Description |
|-------|-------------|
| GlobalProductLineId | Primary key |
| GlobalProductLine | Product line name |
| GlobalProductClassId | Product class ID |
| GlobalProductClass | Product class name |

### Key Decisions
- **Derived View** — Extracted as a distinct view from `Fact_Transaction` using `CREATE OR REPLACE VIEW`. This decouples the product lines to act as a proper dimension in the Power BI semantic model for cross-sell and whitespace analysis.
