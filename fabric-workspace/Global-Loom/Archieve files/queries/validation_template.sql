-- ============================================================
-- VALIDATION QUERY TEMPLATE — Global Loom Gold Layer
-- Lakehouse: The_Global_Loom
-- Date Filter: Policy InceptionDate in CY2025
-- Revenue: Net Brokerage = WTW earned income
-- Usage: Copy a section, adjust WHERE filters as needed
-- ============================================================


-- ============================================================
-- 1. REVENUE BY COUNTRY
-- Grain: One row per Country
-- Use: Regional revenue validation
-- ============================================================

SELECT
    g.Region,
    g.SubRegion,
    g.Country,

    SUM(f.GrossBrokerage)   AS GrossBrokerage,
    SUM(f.NetBrokerage)     AS NetBrokerage,
    SUM(f.GrossPremium)     AS GrossPremium,
    SUM(f.NetPremium)       AS NetPremium,
    SUM(f.GrossFee)         AS GrossFee,
    SUM(f.NetFee)           AS NetFee,
    COUNT(f.TransactionId)  AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId

WHERE g.Region LIKE '%Asia%'                                     -- << CHANGE REGION
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region, g.SubRegion, g.Country
ORDER BY g.SubRegion, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 2. REVENUE BY COUNTRY + SEGMENT
-- Grain: One row per Country x Segment
-- Use: CRB / HCB / IRR split per country
-- ============================================================

SELECT
    g.Region,
    g.SubRegion,
    g.Country,
    s.SegmentCode,
    s.SegmentName,

    SUM(f.GrossBrokerage)   AS GrossBrokerage,
    SUM(f.NetBrokerage)     AS NetBrokerage,
    SUM(f.GrossPremium)     AS GrossPremium,
    SUM(f.NetPremium)       AS NetPremium,
    COUNT(f.TransactionId)  AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction          f
JOIN The_Global_Loom.dbo.dim_geography             g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_financial_segment     s
    ON f.GlobalFinancialSegmentId = s.GlobalFinancialSegmentId
JOIN The_Global_Loom.dbo.dim_policy                p
    ON f.PolicyId = p.PolicyId

WHERE g.Region LIKE '%Asia%'                                     -- << CHANGE REGION
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region, g.SubRegion, g.Country, s.SegmentCode, s.SegmentName
ORDER BY g.Country, s.SegmentCode;


-- ============================================================
-- 3. REVENUE BY COUNTRY + SEGMENT + LOB
-- Grain: One row per Country x Segment x LOB
-- Use: Drill into line of business within segment
-- ============================================================

SELECT
    g.Region,
    g.SubRegion,
    g.Country,
    s.SegmentCode,
    s.BusinessName,
    s.LOBName,

    SUM(f.GrossBrokerage)   AS GrossBrokerage,
    SUM(f.NetBrokerage)     AS NetBrokerage,
    SUM(f.GrossPremium)     AS GrossPremium,
    SUM(f.NetPremium)       AS NetPremium,
    COUNT(f.TransactionId)  AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction          f
JOIN The_Global_Loom.dbo.dim_geography             g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_financial_segment     s
    ON f.GlobalFinancialSegmentId = s.GlobalFinancialSegmentId
JOIN The_Global_Loom.dbo.dim_policy                p
    ON f.PolicyId = p.PolicyId

WHERE g.Region LIKE '%Asia%'                                     -- << CHANGE REGION
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region, g.SubRegion, g.Country, s.SegmentCode, s.BusinessName, s.LOBName
ORDER BY g.Country, s.SegmentCode, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 4. REVENUE BY COUNTRY + PRODUCT CLASS
-- Grain: One row per Country x GlobalProductClass
-- Use: Product mix validation (Property, Casualty, Marine, etc.)
-- ============================================================

SELECT
    g.Region,
    g.SubRegion,
    g.Country,
    f.GlobalProductClass,

    SUM(f.GrossBrokerage)   AS GrossBrokerage,
    SUM(f.NetBrokerage)     AS NetBrokerage,
    SUM(f.GrossPremium)     AS GrossPremium,
    SUM(f.NetPremium)       AS NetPremium,
    COUNT(f.TransactionId)  AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId

WHERE g.Region LIKE '%Asia%'                                     -- << CHANGE REGION
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region, g.SubRegion, g.Country, f.GlobalProductClass
ORDER BY g.Country, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 5. REVENUE BY COUNTRY + PRODUCT CLASS + PRODUCT LINE
-- Grain: One row per Country x ProductClass x ProductLine
-- Use: Deep product drill-down
-- ============================================================

SELECT
    g.Region,
    g.SubRegion,
    g.Country,
    f.GlobalProductClass,
    f.GlobalProductLine,

    SUM(f.GrossBrokerage)   AS GrossBrokerage,
    SUM(f.NetBrokerage)     AS NetBrokerage,
    SUM(f.GrossPremium)     AS GrossPremium,
    SUM(f.NetPremium)       AS NetPremium,
    COUNT(f.TransactionId)  AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId

WHERE g.Region LIKE '%Asia%'                                     -- << CHANGE REGION
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region, g.SubRegion, g.Country, f.GlobalProductClass, f.GlobalProductLine
ORDER BY g.Country, f.GlobalProductClass, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 6. TOP ACCOUNTS BY COUNTRY
-- Grain: One row per Country x Client (GlobalPartyId)
-- Use: Top client revenue validation
-- Joins: dim_party via ClientPartyId (direct FK on fact)
-- ============================================================

SELECT
    g.Region,
    g.SubRegion,
    g.Country,
    pa.GlobalPartyId,
    pa.PartyName               AS ClientName,

    SUM(f.GrossBrokerage)      AS GrossBrokerage,
    SUM(f.NetBrokerage)        AS NetBrokerage,
    SUM(f.GrossPremium)        AS GrossPremium,
    SUM(f.NetPremium)          AS NetPremium,
    COUNT(DISTINCT f.PolicyId) AS PolicyCount,
    COUNT(f.TransactionId)     AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId
JOIN The_Global_Loom.dbo.dim_party             pa
    ON f.ClientPartyId = pa.PartyId

WHERE g.Region LIKE '%Asia%'                                     -- << CHANGE REGION
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region, g.SubRegion, g.Country, pa.GlobalPartyId, pa.PartyName
ORDER BY g.Country, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 7. TOP ACCOUNTS BY COUNTRY + PRODUCT CLASS
-- Grain: One row per Country x Client x ProductClass
-- Use: Cross-sell validation — what does each client buy?
-- ============================================================

SELECT
    g.Country,
    pa.GlobalPartyId,
    pa.PartyName               AS ClientName,
    f.GlobalProductClass,

    SUM(f.GrossBrokerage)      AS GrossBrokerage,
    SUM(f.NetBrokerage)        AS NetBrokerage,
    SUM(f.GrossPremium)        AS GrossPremium,
    COUNT(DISTINCT f.PolicyId) AS PolicyCount,
    COUNT(f.TransactionId)     AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId
JOIN The_Global_Loom.dbo.dim_party             pa
    ON f.ClientPartyId = pa.PartyId

WHERE g.Country = 'Australia'                                    -- << CHANGE COUNTRY
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Country, pa.GlobalPartyId, pa.PartyName, f.GlobalProductClass
ORDER BY pa.PartyName, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 8. TOP ACCOUNTS FULL DETAIL
-- Grain: One row per Country x Client x Segment x LOB x ProductClass
-- Use: Full validation drill-down for a specific country
-- ============================================================

SELECT
    g.Country,
    pa.GlobalPartyId,
    pa.PartyName               AS ClientName,
    s.SegmentCode,
    s.LOBName,
    f.GlobalProductClass,
    f.GlobalProductLine,

    SUM(f.GrossBrokerage)      AS GrossBrokerage,
    SUM(f.NetBrokerage)        AS NetBrokerage,
    SUM(f.GrossPremium)        AS GrossPremium,
    SUM(f.NetPremium)          AS NetPremium,
    SUM(f.GrossFee)            AS GrossFee,
    SUM(f.NetFee)              AS NetFee,
    SUM(f.Claim)               AS Claims,
    COUNT(DISTINCT f.PolicyId) AS PolicyCount,
    COUNT(f.TransactionId)     AS TransactionCount

FROM The_Global_Loom.dbo.fact_transaction          f
JOIN The_Global_Loom.dbo.dim_geography             g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_financial_segment     s
    ON f.GlobalFinancialSegmentId = s.GlobalFinancialSegmentId
JOIN The_Global_Loom.dbo.dim_policy                p
    ON f.PolicyId = p.PolicyId
JOIN The_Global_Loom.dbo.dim_party                 pa
    ON f.ClientPartyId = pa.PartyId

WHERE g.Country = 'Australia'                                    -- << CHANGE COUNTRY
  AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Country, pa.GlobalPartyId, pa.PartyName,
         s.SegmentCode, s.LOBName, f.GlobalProductClass, f.GlobalProductLine
ORDER BY pa.PartyName, s.SegmentCode, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 9. DATA SOURCE BREAKDOWN
-- Grain: One row per DataSource x Country
-- Use: Check which source systems contribute to each market
-- ============================================================

SELECT
    ds.DataSourceInstanceName  AS DataSource,
    ds.SourceSystem,
    g.Region,
    g.Country,

    SUM(f.NetBrokerage)        AS NetBrokerage,
    SUM(f.NetPremium)          AS NetPremium,
    COUNT(f.TransactionId)     AS TransactionCount,
    COUNT(DISTINCT f.PolicyId) AS PolicyCount

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_data_source       ds
    ON f.DataSourceInstanceId = ds.DataSourceInstanceId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId

WHERE p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY ds.DataSourceInstanceName, ds.SourceSystem, g.Region, g.Country
ORDER BY g.Region, g.Country, SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 10. QUICK TOTALS — SANITY CHECK
-- Grain: One row per Region
-- Use: Quick validation of total numbers before drilling down
-- ============================================================

SELECT
    g.Region,
    COUNT(f.TransactionId)     AS TransactionCount,
    COUNT(DISTINCT f.PolicyId) AS PolicyCount,
    SUM(f.GrossPremium)        AS GrossPremium,
    SUM(f.NetPremium)          AS NetPremium,
    SUM(f.GrossBrokerage)      AS GrossBrokerage,
    SUM(f.NetBrokerage)        AS NetBrokerage,
    SUM(f.GrossFee)            AS GrossFee,
    SUM(f.NetFee)              AS NetFee,
    SUM(f.Claim)               AS Claims

FROM The_Global_Loom.dbo.fact_transaction      f
JOIN The_Global_Loom.dbo.dim_geography         g
    ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
JOIN The_Global_Loom.dbo.dim_policy            p
    ON f.PolicyId = p.PolicyId

WHERE p.InceptionDateKey BETWEEN 20250101 AND 20251231

GROUP BY g.Region
ORDER BY SUM(f.NetBrokerage) DESC;


-- ============================================================
-- 11. CLIENT SUMMARY WITH PRODUCT & REVENUE (CONCATENATED)
-- Grain: One row per Country x Client
-- Output: Products collapsed into single string per client
-- Format: "Property ($1,234,567), Casualty ($890,123)"
-- Equivalent to DAX CONCATENATEX pattern
-- ============================================================

WITH client_product AS (
    SELECT
        g.Country,
        pa.PartyName                AS ClientName,
        pt.GlobalProductClass,
        SUM(f.NetBrokerage)         AS ProductNetBrokerage,
        SUM(f.GrossPremium)         AS ProductGrossPremium,
        COUNT(f.TransactionId)      AS ProductTxnCount

    FROM The_Global_Loom.dbo.fact_transaction          f
    LEFT JOIN The_Global_Loom.dbo.dim_product          pt
        ON f.ProductId = pt.ProductId
    LEFT JOIN The_Global_Loom.dbo.dim_geography        g
        ON f.GlobalFinancialGeographyId = g.GlobalFinancialGeographyId
    LEFT JOIN The_Global_Loom.dbo.dim_policy           p
        ON f.PolicyId = p.PolicyId
    LEFT JOIN The_Global_Loom.dbo.dim_party            pa
        ON f.ClientPartyId = pa.PartyId

    WHERE g.Country = 'Australia'                                -- << CHANGE COUNTRY
      AND p.InceptionDateKey BETWEEN 20250101 AND 20251231

    GROUP BY g.Country, pa.PartyName, pt.GlobalProductClass
)

SELECT
    Country,
    ClientName,

    -- Product & Revenue combined (single string per client)
    STRING_AGG(
        GlobalProductClass + ' ($' + FORMAT(ProductNetBrokerage, 'N0') + ')',
        ', '
    )                              AS ProductAndRevenue,

    -- Totals across all products
    SUM(ProductNetBrokerage)       AS TotalNetBrokerage,
    SUM(ProductGrossPremium)       AS TotalGrossPremium,
    SUM(ProductTxnCount)           AS TotalTransactionCount,
    COUNT(GlobalProductClass)      AS ProductClassCount

FROM client_product
WHERE GlobalProductClass IS NOT NULL

GROUP BY Country, ClientName
ORDER BY SUM(ProductNetBrokerage) DESC;
