-- =============================================================================
-- 02_silver_clean_crm_opportunity_unified
-- Was:    [dbo].[vw_Bronze_Opportunity_Unified]
-- Output: clean_crm_opportunity_unified  (intermediate Silver — consumed by clean_crm_opportunity)
-- Source: src_crm_opportunity (Bronze) + Legacy CIS _Bronze_
-- Layer:  Silver (intermediate)
-- Note:   Despite old name containing "Bronze", this is Silver logic —
--         it merges Bronze + Legacy and must run BEFORE clean_crm_opportunity.
--
-- Issues to resolve before converting to notebook:
--   1. Legacy CIS _Bronze_ is NOT in the new Bronze pipeline yet.
--      Add a "Copy Legacy CIS" activity to 01_bronze_ingest_CRM.
--   2. Source table [Bronze Opportunity] → new name: src_crm_opportunity
--   3. ROW_NUMBER in legacy MainKey generation is non-deterministic.
--      Fix: use OpptyID + hash(ColleagueInvolved + CreatedOn) for stable key.
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[clean_crm_opportunity_unified] AS
SELECT
    CAST(MainKey AS VARCHAR(255)) AS MainKey,
    CAST(OpptyID AS VARCHAR(255)) AS OpptyID,
    OpptyName,
    OpptyOwner,
    ColleagueInvolved,
    LobProductClass,
    Service,
    PipelinePhase,
    Description,
    FormName,
    OpptyStatus,
    OpptyState,
    OpptyType,
    OpptySubType,
    LikelihoodOfWin,
    Frequency,
    ProjectStartDate,
    OriginatingLeadID,
    ReportingOffice,
    ReportingOfficeCountry,
    ReportingOfficeRegion,
    ProfitCenter,
    CreatedOn,
    ModifiedOn,
    FirstIncomeDate,
    DataSource
FROM [dbo].[src_crm_opportunity]    -- was: [Bronze Opportunity]

UNION ALL

SELECT * FROM (
    SELECT
        CAST(CAST(OpptyID AS VARCHAR(255)) + '_' +
        CAST(ROW_NUMBER() OVER (
            PARTITION BY OpptyID
            ORDER BY ColleagueInvolved, CreatedOn
        ) AS VARCHAR(10)) AS VARCHAR(255)) AS MainKey,

        CAST(OpptyID AS VARCHAR(255)) AS OpptyID,
        CAST(OpptyName AS VARCHAR(MAX)) AS OpptyName,
        CAST(OpptyOwner AS VARCHAR(MAX)) AS OpptyOwner,
        CAST(ColleagueInvolved AS VARCHAR(MAX)) AS ColleagueInvolved,
        CAST(LobProductClass AS VARCHAR(MAX)) AS LobProductClass,
        CAST(Service AS VARCHAR(MAX)) AS Service,
        CAST(NULL AS VARCHAR(MAX)) AS PipelinePhase,
        CAST(NULL AS VARCHAR(MAX)) AS Description,
        CAST(NULL AS VARCHAR(MAX)) AS FormName,
        CAST(OpptyStatus AS VARCHAR(MAX)) AS OpptyStatus,
        CAST(OpptyState AS VARCHAR(MAX)) AS OpptyState,
        CAST(NULL AS VARCHAR(MAX)) AS OpptyType,
        CAST(NULL AS VARCHAR(MAX)) AS OpptySubType,
        CAST([Likelihood of Win] AS VARCHAR(MAX)) AS LikelihoodOfWin,
        CAST(Frequency AS VARCHAR(MAX)) AS Frequency,
        CAST(NULL AS DATETIME) AS ProjectStartDate,
        CAST(NULL AS VARCHAR(MAX)) AS OriginatingLeadID,
        CAST(ReportingOffice AS VARCHAR(MAX)) AS ReportingOffice,
        CAST(ReportingOfficeCountry AS VARCHAR(MAX)) AS ReportingOfficeCountry,
        CAST(ReportingOfficeRegion AS VARCHAR(MAX)) AS ReportingOfficeRegion,
        CAST(ProfitCenter AS VARCHAR(MAX)) AS ProfitCenter,
        CreatedOn,
        CAST(NULL AS DATETIME) AS ModifiedOn,
        [First Income Date] AS FirstIncomeDate,
        CAST('Legacy CIS' AS VARCHAR(MAX)) AS DataSource
    FROM [dbo].[src_crm_legacy_cis]    -- was: [Legacy CIS _Bronze_]
    WHERE NOT EXISTS (
        SELECT 1
        FROM [dbo].[src_crm_opportunity] bo    -- was: [Bronze Opportunity]
        WHERE CAST(bo.OpptyID AS VARCHAR(255)) = CAST([src_crm_legacy_cis].OpptyID AS VARCHAR(255))
    )
) AS LegacyData
