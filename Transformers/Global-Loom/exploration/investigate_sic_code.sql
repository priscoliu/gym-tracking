-- ============================================================
-- SIC Code Investigation for dim_industry Linkage
-- Run these queries in Fabric notebook attached to The_Global_Loom
-- ============================================================

-- Query 1: Get vwParty schema to find SIC-related columns
-- ============================================================
DESCRIBE rpt.vwParty;

-- Look for columns containing:
-- - "SIC", "Industry", "NAICS", "Sector", "Classification"


-- Query 2: Get vwPolicy schema to find SIC-related columns
-- ============================================================
DESCRIBE rpt.vwPolicy;

-- Look for columns containing:
-- - "SIC", "Industry", "NAICS", "Sector", "Classification"


-- Query 3: Check IndustryHierarchy table structure
-- ============================================================
DESCRIBE ref.IndustryHierarchy;

-- Expected columns: SIC87IndustryId, SIC87FullCode, SIC87IndustryDescription


-- Query 4: Sample IndustryHierarchy data
-- ============================================================
SELECT * FROM ref.IndustryHierarchy LIMIT 10;


-- Query 5: Search for SIC-like patterns in vwParty column names
-- ============================================================
-- Run DESCRIBE first, then manually look for columns with these patterns:
-- SIC, Industry, NAICS, Sector, Class, Code


-- Query 6: If SIC column found on vwParty, check population
-- ============================================================
-- REPLACE [SicColumnName] with actual column name found in Query 1

SELECT
    COUNT(*) AS TotalParties,
    COUNT(DISTINCT [SicColumnName]) AS DistinctSIC,
    SUM(CASE WHEN [SicColumnName] IS NULL THEN 1 ELSE 0 END) AS NullCount,
    ROUND(SUM(CASE WHEN [SicColumnName] IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS NullPct
FROM rpt.vwParty;


-- Query 7: If SIC column found, check sample values
-- ============================================================
SELECT
    [SicColumnName],
    COUNT(*) AS PartyCount
FROM rpt.vwParty
WHERE [SicColumnName] IS NOT NULL
GROUP BY [SicColumnName]
ORDER BY PartyCount DESC
LIMIT 20;


-- Query 8: Try to join Party to IndustryHierarchy
-- ============================================================
-- REPLACE [SicColumnName] with actual column name

SELECT
    p.PartyId,
    p.PartyName,
    p.[SicColumnName],
    i.SIC87IndustryId,
    i.SIC87FullCode,
    i.SIC87IndustryDescription
FROM rpt.vwParty p
LEFT JOIN ref.IndustryHierarchy i
    ON TRIM(UPPER(p.[SicColumnName])) = TRIM(UPPER(i.SIC87FullCode))
WHERE p.[SicColumnName] IS NOT NULL
LIMIT 100;


-- Query 9: Check match rate between Party and IndustryHierarchy
-- ============================================================
SELECT
    COUNT(*) AS TotalPartiesWithSIC,
    SUM(CASE WHEN i.SIC87IndustryId IS NOT NULL THEN 1 ELSE 0 END) AS MatchedToIndustry,
    ROUND(SUM(CASE WHEN i.SIC87IndustryId IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS MatchPct
FROM rpt.vwParty p
LEFT JOIN ref.IndustryHierarchy i
    ON TRIM(UPPER(p.[SicColumnName])) = TRIM(UPPER(i.SIC87FullCode))
WHERE p.[SicColumnName] IS NOT NULL;


-- ============================================================
-- DECISION TREE
-- ============================================================

-- IF SIC column found on vwParty with good population (>10% non-null):
--   → Add IndustryKey FK to dim_party
--   → Join via SIC code column
--   → Create dim_industry notebook

-- IF SIC column found on vwPolicy:
--   → Add IndustryKey FK to dim_policy
--   → Join via SIC code column
--   → Create dim_industry notebook

-- IF SIC column NOT found on either table:
--   → Keep dim_industry as standalone reference table
--   → No FK relationship
--   → Still create dim_industry (for future use or manual lookups)

-- IF SIC column found but <5% populated or 0% match rate:
--   → Keep dim_industry as standalone
--   → Document gap in star schema plan
