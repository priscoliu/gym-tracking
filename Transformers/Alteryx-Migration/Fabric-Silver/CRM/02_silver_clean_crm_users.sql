-- =============================================================================
-- 02_silver_clean_crm_users
-- Was:    [dbo].[Final Users]
-- Output: clean_crm_users
-- Source: src_crm_users (Bronze) + Legacy CIS _Bronze_
-- Layer:  Silver
--
-- Issues to resolve before converting to notebook:
--   1. ROW_NUMBER() for LEGACY_USER_ keys is non-deterministic on re-runs.
--      Fix: CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', UPPER(LTRIM(RTRIM(UserName)))), 2)
--   2. Legacy CIS _Bronze_ is NOT in the new Bronze pipeline yet.
--   3. Source table [Bronze Users] → new name: src_crm_users
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[clean_crm_users] AS
SELECT
    CAST(UserKey AS VARCHAR(255)) AS UserKey,
    CAST(UserName AS VARCHAR(500)) AS UserName,
    CAST(UserUPN AS VARCHAR(500)) AS UserUPN,
    CAST(UserStatus AS VARCHAR(255)) AS UserStatus,
    CAST(LicensStatus AS VARCHAR(255)) AS LicensStatus,
    CAST(LicenseType AS VARCHAR(255)) AS LicenseType,
    CAST(Region AS VARCHAR(255)) AS Region,
    CAST(BusinessUnit AS VARCHAR(255)) AS BusinessUnit,
    CAST(ProfitCenter AS VARCHAR(500)) AS ProfitCenter,
    CAST(SegmentLob AS VARCHAR(255)) AS SegmentLob,
    CAST(BusinessName AS VARCHAR(255)) AS BusinessName,
    CAST(OfficeName AS VARCHAR(255)) AS OfficeName,
    CAST(OfficeCountry AS VARCHAR(255)) AS OfficeCountry,
    CreatedDate,
    ModifiedDate
FROM [dbo].[src_crm_users]    -- was: [Bronze Users]

UNION ALL

SELECT
    'LEGACY_USER_' + CAST(ROW_NUMBER() OVER (ORDER BY UserName) AS VARCHAR(50)) AS UserKey,
    CAST(UserName AS VARCHAR(500)) AS UserName,
    CAST(NULL AS VARCHAR(500)) AS UserUPN,
    CAST('Legacy' AS VARCHAR(255)) AS UserStatus,
    CAST(NULL AS VARCHAR(255)) AS LicensStatus,
    CAST(NULL AS VARCHAR(255)) AS LicenseType,
    CAST(NULL AS VARCHAR(255)) AS Region,
    CAST(NULL AS VARCHAR(255)) AS BusinessUnit,
    CAST(NULL AS VARCHAR(500)) AS ProfitCenter,
    CAST(NULL AS VARCHAR(255)) AS SegmentLob,
    CAST(NULL AS VARCHAR(255)) AS BusinessName,
    CAST(NULL AS VARCHAR(255)) AS OfficeName,
    CAST(NULL AS VARCHAR(255)) AS OfficeCountry,
    CAST(NULL AS DATETIME) AS CreatedDate,
    CAST(NULL AS DATETIME) AS ModifiedDate
FROM (
    SELECT DISTINCT UserName
    FROM (
        SELECT OpptyOwner AS UserName FROM [dbo].[src_crm_legacy_cis]    -- was: [Legacy CIS _Bronze_]
        UNION
        SELECT ColleagueInvolved AS UserName FROM [dbo].[src_crm_legacy_cis]
    ) AS AllUsers
    WHERE UserName IS NOT NULL
      AND LTRIM(RTRIM(UserName)) <> ''
      AND LEN(LTRIM(RTRIM(UserName))) > 0
) l
WHERE NOT EXISTS (
    SELECT 1
    FROM [dbo].[src_crm_users] bu    -- was: [Bronze Users]
    WHERE UPPER(LTRIM(RTRIM(bu.UserName))) = UPPER(LTRIM(RTRIM(l.UserName)))
)
