-- =============================================================================
-- 02_silver_clean_crm_profitcenter
-- Was:    [dbo].[Final ProfitCenter]
-- Output: clean_crm_profitcenter
-- Source: src_crm_profitcenter (Bronze) + Legacy CIS _Bronze_
-- Layer:  Silver
--
-- Issues to resolve before converting to notebook:
--   1. ROW_NUMBER() for LEGACY_PC_ keys is non-deterministic on re-runs.
--      Fix: use hash of ProfitCenter name as stable key.
--   2. Legacy CIS _Bronze_ is NOT in the new Bronze pipeline yet.
--   3. Source table [Bronze ProfitCenter] → new name: src_crm_profitcenter
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[clean_crm_profitcenter] AS
SELECT
    CAST(ProfitcenterKey AS VARCHAR(255)) AS ProfitcenterKey,
    CAST(ProfitCenter AS VARCHAR(500)) AS ProfitCenter,
    CAST(Financelevel AS VARCHAR(255)) AS Financelevel,
    CAST(OwningBusinessName AS VARCHAR(255)) AS OwningBusinessName,
    CAST(BusinessName AS VARCHAR(255)) AS BusinessName,
    CAST(LobName AS VARCHAR(255)) AS LobName,
    CAST(Segment AS VARCHAR(255)) AS Segment,
    CAST(Statename AS VARCHAR(255)) AS Statename,
    Createdon,
    Modifiedon
FROM [dbo].[src_crm_profitcenter]    -- was: [Bronze ProfitCenter]

UNION ALL

SELECT
    'LEGACY_PC_' + CAST(ROW_NUMBER() OVER (ORDER BY ProfitCenter) AS VARCHAR(50)) AS ProfitcenterKey,
    CAST(ProfitCenter AS VARCHAR(500)) AS ProfitCenter,
    CAST(NULL AS VARCHAR(255)) AS Financelevel,
    CAST(NULL AS VARCHAR(255)) AS OwningBusinessName,
    CAST(NULL AS VARCHAR(255)) AS BusinessName,
    CAST(NULL AS VARCHAR(255)) AS LobName,
    CAST(NULL AS VARCHAR(255)) AS Segment,
    CAST('Legacy' AS VARCHAR(255)) AS Statename,
    CAST(NULL AS DATETIME) AS Createdon,
    CAST(NULL AS DATETIME) AS Modifiedon
FROM (
    SELECT DISTINCT ProfitCenter
    FROM [dbo].[src_crm_legacy_cis]    -- was: [Legacy CIS _Bronze_]
) l
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[src_crm_profitcenter] bpc    -- was: [Bronze ProfitCenter]
    WHERE UPPER(LTRIM(RTRIM(bpc.ProfitCenter))) = UPPER(LTRIM(RTRIM(l.ProfitCenter)))
)
