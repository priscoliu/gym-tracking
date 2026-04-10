-- =============================================================================
-- 02_silver_clean_crm_product
-- Was:    [dbo].[Final ProductClass]
-- Output: clean_crm_product
-- Source: src_crm_product (Bronze) + Legacy CIS _Bronze_
-- Layer:  Silver
--
-- Issues to resolve before converting to notebook:
--   1. ROW_NUMBER() for LEGACY_PROD_ keys is non-deterministic on re-runs.
--      Fix: use hash of ProductName as stable key.
--   2. Legacy CIS _Bronze_ is NOT in the new Bronze pipeline yet.
--   3. Source table [Bronze Product] → new name: src_crm_product
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[clean_crm_product] AS
SELECT
    CAST(ProductClassKey AS VARCHAR(255)) AS ProductClassKey,
    CAST(ProductName AS VARCHAR(500)) AS ProductName,
    CAST(Segment AS VARCHAR(255)) AS Segment,
    CAST(Business AS VARCHAR(255)) AS Business,
    CAST(Status AS VARCHAR(255)) AS Status,
    CreateDate,
    ModifiedDate
FROM [dbo].[src_crm_product]    -- was: [Bronze Product]

UNION ALL

SELECT
    'LEGACY_PROD_' + CAST(ROW_NUMBER() OVER (ORDER BY LobProductClass) AS VARCHAR(50)) AS ProductClassKey,
    CAST(LobProductClass AS VARCHAR(500)) AS ProductName,
    CAST(NULL AS VARCHAR(255)) AS Segment,
    CAST(NULL AS VARCHAR(255)) AS Business,
    CAST('Legacy' AS VARCHAR(255)) AS Status,
    CAST(NULL AS DATETIME) AS CreateDate,
    CAST(NULL AS DATETIME) AS ModifiedDate
FROM (
    SELECT DISTINCT LobProductClass
    FROM [dbo].[src_crm_legacy_cis]    -- was: [Legacy CIS _Bronze_]
) l
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[src_crm_product] bp    -- was: [Bronze Product]
    WHERE UPPER(LTRIM(RTRIM(bp.ProductName))) = UPPER(LTRIM(RTRIM(l.LobProductClass)))
)
