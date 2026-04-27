# Cross-sell intelligence dashboard

**Stage 1 and Stage 2 design record**
R&B SalesOps · Global · April 2026

---

## Context

Cross-sell / LOB penetration is the Stage 1 priority for the Power BI dashboard. This document captures the design decisions made during Stages 1 and 2 (data understanding and semantic model) so work can continue from a clean handoff point into Stage 3 (DAX and UI).

Upstream reference: Gold Layer Documentation — R&B SalesOps. Source: PAS Silver → Gold (Microsoft Fabric) → Power BI.

---

## Stage 1: Data understanding

### Gold tables — grain and keys

| Table | Grain (one row per…) | Primary key |
|---|---|---|
| `Gold_SalesOps_Dim_Client` | Source-level party | `PartyId` |
| `Gold_SalesOps_Dim_FinancialGeography` | WTW financial geography node | `GlobalFinancialGeographyId` |
| `Gold_SalesOps_Fact_Transaction` | Transaction detail line (~434M rows) | `TransactionDetailId` |

### Three levels of "client"

One real-world entity (e.g. Singtel) has multiple `PartyId`s — one per source system (Epic, Eclipse, WIBS, etc.) — all rolling up to a single `GlobalPartyId`. This distinction is the single most important concept for the penetration denominator.

| Identity | From | Represents | Use for |
|---|---|---|---|
| `PartyId` | Party | Source-system-level party | Joining to transactions |
| `GlobalPartyId` | PartyDetails | Deduplicated real-world entity | **Penetration denominator** |
| `GUOPartyId` | PartyDetails self-join | Corporate parent (Global Ultimate Owner) | Group-level cross-sell view |

Illustrative: if Singtel has Property in Epic, Casualty in Eclipse, and Marine in WIBS, counting `PartyId`s gives 3 clients each with 1 LOB (penetration looks terrible). Counting `GlobalPartyId` gives 1 client with 3 LOBs (real picture).

### Cross-sell relevance of each table

| Table | Role for cross-sell |
|---|---|
| `Fact_Transaction` | **Primary.** Provides both revenue dollars and presence (via DISTINCTCOUNT of Product Lines). |
| `Dim_Client` | Client attributes, segmentation, tier, firmographics. |
| `Dim_ProductLine` | Distinct list of Product Lines for slicers and whitespace mapping. |
| `Dim_FinancialGeography` | Geographic slicing on transactions. |

### Data traps documented in Gold

- Revenue measure is `TotalWTWRevenueUSD_Adj` — sum with NO role filter. Using `SUM(GrossBrokerageUSD)` alone misses ShareBroker revenue; using unfiltered `NetPremiumUSD` double-counts.
- If premium is needed: `GrossPremiumUSD` filtered on `GlobalPartyRoleId = 100`, or `NetPremiumUSD` filtered on `= 102`. Never both summed.
- `GlobalProductLineId` is 24% NULL in `TransactionDetail`. Fact already COALESCEs with Product table. For cross-sell analysis, filter out `GlobalProductLineId IS NULL`.
- ShareBroker is 0.05% of clients — ignore for Stage 1.

---

## Stage 2: Semantic model decisions

### Locked decisions

| Decision | Value | Why |
|---|---|---|
| Penetration grain | `GlobalPartyId` | One real-world client. `PartyId` would understate penetration by splitting entities across source systems. |
| Presence window | Lifetime (ever had the LOB) | Leadership framing is total whitespace; renewal-window nuance comes in later stages. |
| Geographic scope | Global (not APAC) | Global project — region becomes a user-controlled slicer, not a baked filter. |
| `Dim_Client` PK | `PartyId` (unchanged) | Required for `Fact_Transaction` to trace `TransactionDetail → Transaction → Party`. `GlobalPartyId` is an attribute, used in measures via `DISTINCTCOUNT`. |
| Date dimension | Keep `Dim_Date` | Still needed for YoY, new-LOB-wins, lost-clients analysis even under lifetime presence. |

### Model tables

| Role | Model table name | Source | Storage |
|---|---|---|---|
| Fact | `Fact_Transaction` | `Gold_SalesOps_Fact_Transaction` | Direct Lake (fallback: Import + agg) |
| Dim | `Dim_Client` | `Gold_SalesOps_Dim_Client` | Direct Lake |
| Dim | `Dim_ProductLine` | `Gold_SalesOps_Dim_ProductLine` (View) | Import |
| Dim | `Dim_FinancialGeography` | `Gold_SalesOps_Dim_FinancialGeography` | Import |
| Dim | `Dim_Date` | Generated calendar | Import, marked as date table |

Since there is no physical Bridge table, presence metrics will be calculated directly on `Fact_Transaction` using DAX.

### New view: Dim_ProductLine

Required because `Fact_Transaction` carries `GlobalProductLineId` and `GlobalProductLine` as denormalised strings — there is no dedicated product-line dimension in Gold. Without this, the whitespace `CROSS JOIN` has no "all products" axis.

```sql
CREATE OR ALTER VIEW Gold_SalesOps_Dim_ProductLine AS
SELECT DISTINCT
    GlobalProductLineId,
    GlobalProductLine,
    GlobalProductClassId,
    GlobalProductClass
FROM Gold_SalesOps_Fact_Transaction
WHERE GlobalProductLineId IS NOT NULL;
```

Small (~20 rows). Import mode.

### Relationships

```
Dim_Date               1:* ──> Fact_Transaction[InceptionDate]
Dim_Client             1:* ──> Fact_Transaction[ClientPartyId]
Dim_ProductLine        1:* ──> Fact_Transaction[GlobalProductLineId]
Dim_FinancialGeography 1:* ──> Fact_Transaction[GlobalFinancialGeographyId]
```

All single-direction filtering.

### Dim_Client — columns exposed / hidden

**Keep (visible):** `PartyId` (hidden key), `GlobalPartyId`, `GUOPartyId`, `GUOClientName`, `ClientName`, `Segmentation`, `IndustryName`, `GroupName`, `MajorGroupName`, `DivisionName`, `CountryName`, `CountryCode`, `OperatingRevenueUSD`, `TotalEmployeeCount`.

**Hide (Stage 1):** `DUNSNumber`, `OwnershipType`, `PartyType`, `IsIndividual`, `City`, `State`.

---

## Stage 3 preview — measures planned

### Penetration

- `Client Count = DISTINCTCOUNT(Dim_Client[GlobalPartyId])`
- `LOB Count` (per client) — distinct product lines held, calculated via `DISTINCTCOUNT(Fact_Transaction[GlobalProductLineId])`
- `LOB Bucket` — 1 / 2 / 3 / 4+
- `% of clients in bucket`

### Revenue

- `Total Revenue = SUM(Fact_Transaction[TotalWTWRevenueUSD_Adj])`
- `Avg Revenue per Client = Total Revenue / Client Count`
- `Single-LOB Revenue %` — retention risk framing

### Whitespace

- `Has Product` flag (0 / 1)
- `Whitespace Count` — products a client doesn't have

---

## Pre-Stage 3 data-quality checks

Run these before building measures. Results determine whether GUO rollup needs a separate bridge and whether `GlobalPartyId` needs a COALESCE fallback.

### 1. GlobalPartyId completeness in Dim_Client

```sql
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN GlobalPartyId IS NULL THEN 1 ELSE 0 END) AS null_global,
    ROUND(100.0 * SUM(CASE WHEN GlobalPartyId IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_null
FROM Gold_SalesOps_Dim_Client;
```

### 2. Orphan ClientPartyId in Fact_Transaction

```sql
SELECT COUNT(*) AS orphans
FROM Gold_SalesOps_Fact_Transaction f
LEFT JOIN Gold_SalesOps_Dim_Client c ON c.PartyId = f.ClientPartyId
WHERE c.PartyId IS NULL;
```

### 3. Penetration baseline (LOB bucket distribution)

```sql
WITH client_lobs AS (
    SELECT
        COALESCE(dc.GlobalPartyId, dc.PartyId) AS CrossSellEntityId,
        COUNT(DISTINCT f.GlobalProductLineId) AS lob_count
    FROM Gold_SalesOps_Fact_Transaction f
    JOIN Gold_SalesOps_Dim_Client dc ON dc.PartyId = f.ClientPartyId
    WHERE f.GlobalProductLineId IS NOT NULL
    GROUP BY COALESCE(dc.GlobalPartyId, dc.PartyId)
)
SELECT
    CASE
        WHEN lob_count = 1 THEN '1'
        WHEN lob_count = 2 THEN '2'
        WHEN lob_count = 3 THEN '3'
        ELSE '4+'
    END AS lob_bucket,
    COUNT(*) AS client_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM client_lobs
GROUP BY 1
ORDER BY 1;
```

---

## Open questions for Stage 3

- If `GlobalPartyId` null % > 5%, decide on COALESCE fallback (use `PartyId`) or exclude those rows.
- GUO rollup: confirm whether APAC / global teams manage at client or GUO level. If GUO is wanted as a toggle, we need a second "client" role in the model.
- Product line count in the final universe — drives whitespace heatmap legibility. 20 lines renders fine; 200 does not.
- Direct Lake vs Import for `Fact_Transaction` — depends on Fabric capacity SKU. If memory-pressured, build a `ClientPartyId × GlobalProductLineId × InceptionYear` revenue aggregation table.

---

## Next steps

- Run the three pre-Stage 3 SQL checks; share results.
- Create `Dim_ProductLine` view.
- Build semantic model in Power BI following the relationships above.
- Begin Stage 3: DAX measures and dashboard UI/UX design.
