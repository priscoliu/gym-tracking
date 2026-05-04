-- =============================================================================
-- 02_silver_clean_crm_account
-- Was:    [dbo].[Final Account]
-- Output: clean_crm_account
-- Source: src_crm_account (Bronze) + Legacy CIS _Bronze_
-- Layer:  Silver
--
-- Issues to resolve before converting to notebook:
--   1. ROW_NUMBER() for LEGACY_ keys is non-deterministic on re-runs.
--      Fix: replace with HASHBYTES or a stable natural key (GCID + AccountName hash).
--   2. Legacy CIS _Bronze_ is NOT in the new Bronze pipeline yet.
--      Add a "Copy Legacy CIS" activity to 01_bronze_ingest_CRM.
--   3. Source table [Bronze Account] → new name: src_crm_account
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[clean_crm_account] AS
SELECT
    CAST(AccountKey AS VARCHAR(255)) AS AccountKey,
    CAST(GCID AS VARCHAR(255)) AS GCID,
    CAST(AccountName AS VARCHAR(500)) AS AccountName,
    CAST(ParentAccountName AS VARCHAR(500)) AS ParentAccountName,
    CAST(GlobalParentAccountName AS VARCHAR(500)) AS GlobalParentAccountName,
    CAST(DunsNumber AS VARCHAR(255)) AS DunsNumber,
    CAST(Tiers AS VARCHAR(255)) AS Tiers,
    CAST(Industry AS VARCHAR(255)) AS Industry,
    CAST(PrimarySICCode AS VARCHAR(255)) AS PrimarySICCode,
    CAST(Country AS VARCHAR(255)) AS Country,
    CreateDate,
    ModifiedDate
FROM [dbo].[src_crm_account]    -- was: [Bronze Account]

UNION ALL

SELECT
    'LEGACY_' + CAST(ROW_NUMBER() OVER (ORDER BY Account, GCID) AS VARCHAR(50)) AS AccountKey,
    CAST(GCID AS VARCHAR(255)) AS GCID,
    CAST(Account AS VARCHAR(500)) AS AccountName,
    CAST(NULL AS VARCHAR(500)) AS ParentAccountName,
    CAST(NULL AS VARCHAR(500)) AS GlobalParentAccountName,
    CAST(NULL AS VARCHAR(255)) AS DunsNumber,
    CAST(Tiers AS VARCHAR(255)) AS Tiers,
    CAST([Industry _Account Name_ _Account_] AS VARCHAR(255)) AS Industry,
    CAST(NULL AS VARCHAR(255)) AS PrimarySICCode,
    CAST(NULL AS VARCHAR(255)) AS Country,
    CAST(NULL AS DATETIME) AS CreateDate,
    CAST(NULL AS DATETIME) AS ModifiedDate
FROM (
    SELECT DISTINCT
        Account,
        GCID,
        Tiers,
        [Industry _Account Name_ _Account_]
    FROM [dbo].[src_crm_legacy_cis]    -- was: [Legacy CIS _Bronze_]
) l
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[src_crm_account] ba    -- was: [Bronze Account]
    WHERE
        (CAST(ba.GCID AS VARCHAR(255)) = CAST(l.GCID AS VARCHAR(255)) AND l.GCID IS NOT NULL)
        OR
        UPPER(LTRIM(RTRIM(ba.AccountName))) = UPPER(LTRIM(RTRIM(l.Account)))
)
