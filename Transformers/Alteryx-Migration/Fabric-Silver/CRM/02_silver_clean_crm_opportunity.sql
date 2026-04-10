-- =============================================================================
-- 02_silver_clean_crm_opportunity
-- Was:    [dbo].[Final Oppty]
-- Output: clean_crm_opportunity
-- Source: clean_crm_opportunity_unified (Silver intermediate) + ref mapping tables
-- Layer:  Silver
-- Depends on: clean_crm_opportunity_unified (must run first)
--
-- Issues to resolve before converting to notebook:
--   1. Hard-coded date '2025-10-13' for isExpired — should be a config parameter.
--   2. Hard-coded list of ~50 profit centers for 'Asia Specialty' classification —
--      should be a ref table (ref_crm_asia_specialty_profitcenters or similar).
--   3. Hard-coded country exclusion list in WHERE clause —
--      should be a ref table (ref_crm_excluded_countries).
--   4. Ref tables [Frequency Mapping], [Pipeline Phasing Mapping],
--      [CRB_Sub Product Class to GLOB Mapping], [CRB_Profit Center to GLOB Mapping]
--      need to exist in Bronze or be uploaded as static ref tables.
--   5. Source [vw_Bronze_Opportunity_Unified] → new name: clean_crm_opportunity_unified
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[clean_crm_opportunity] AS
SELECT
    o.MainKey,
    o.OpptyID,
    o.OpptyName,
    o.LobProductClass,
    o.Service,
    UPPER(COALESCE(pm.[New Pipeline Phase], o.PipelinePhase, 'Unmapped')) AS PipelinePhase,
    o.Description,
    o.FormName,
    o.OpptyStatus,
    o.OpptyState,
    o.OpptyType,
    o.OpptySubType,
    REPLACE(o.LikelihoodOfWin, '%', '') AS LikelihoodOfWin,
    COALESCE(fm.Frequency, o.Frequency, 'Unmapped') AS Frequency,
    o.ProjectStartDate,
    o.OriginatingLeadID,
    o.ReportingOffice,
    CASE
        WHEN o.ProfitCenter IN (
            -- TODO: move this list to ref_crm_asia_specialty_profitcenters table
            'CONSTRUCTION - ASIA SPECIALTY', 'SINGAPORE PROPERTY (P&C - GB)', 'TPV SINGAPORE - TERRORISM & POLITICAL VIOLENCE',
            'CASUALTY - ASIA SPECIALTY', 'DOWNSTREAM - ASIA SPECIALTY', 'STRATEGIC RISK CONSULTING - ASIA', 'FINEX - ASIA SPECIALTY',
            'FS - SINGAPORE - GB', 'FS SINGAPORE', 'MARINE - ASIA SPECIALTY', 'NATURAL RESOURCES - ASIA SPECIALTY',
            'PROPERTY & CASUALTY - ASIA SPECIALTY', 'RENEWABLES - ASIA SPECIALTY', 'MARINE HULL - ASIA SPECIALTY',
            'POWER - ASIA SPECIALTY', 'P&C - ASIA SPECIALTY', 'NON GL - ASIA', 'CLIMATE - ASIA', 'CAPTIVES - ASIA',
            'GLOBAL FAC - ASIA SPECIALTY', 'FINANCIAL SOLUTIONS - SINGAPORE', 'FORENSIC ACCOUNTING & COMPLEX CLAIMS - ASIA',
            'FS - HONG KONG - GB', 'FS SINGAPORE - GB', 'MARINE CARGO - ASIA SPECIALTY', 'TMT- ASIA SPECIALTY',
            'ALTERNATIVE RISK TRANSFER - ASIA', 'AEROSPACE - ASIA SPECIALTY', 'LARGE ACCOUNT - ASIA', 'BROKING SUPPORT - ASIA',
            'TERRORISM - SINGAPORE', 'FS BANKS & ECAS - GB', 'INTERNATIONAL PROPERTY - GB', 'FS INTERNATIONAL - GB',
            'FS TRINITY - GB', 'RISK & ANALYTICS - ASIA SPECIALTY', 'FS US - GB', 'TPV NA - TERRORISM & POLITICAL VIOLENCE',
            'F C - MEA/AUSTRALASIA/ASIA PAC - GB', 'INTERNATIONAL CASUALTY - GB', 'TPV SINGAPORE - ACTIVE ASSAILANT',
            'TPV SINGAPORE - OTHER', 'UPSTREAM - ASIA SPECIALTY', 'AVIATION - ASIA PACIFIC - GB', 'BOUYGUES - GB',
            'ENVIRONMENTAL - GB', 'FS ASSETS & AVIATION - GB', 'FS GLOBAL STRUCTURING - GB', 'LARGE ACCOUNTS - SINGAPORE',
            'PRODUCT RECALL - GB', 'RA CORPORATE - ASIA', 'RFCA - ASIA', 'UPSTREAM ASIA - GB'
        )
        THEN 'Asia Specialty'
        WHEN o.ProfitCenter = 'JAPAN DESK - SINGAPORE'
        THEN 'Asia Desk Reporting'
        ELSE REPLACE(REPLACE(o.ReportingOfficeCountry, 'Viet Nam', 'Vietnam'), 'Korea, Republic of', 'South Korea')
    END AS ReportingOfficeCountry,
    o.ReportingOfficeRegion,
    o.ProfitCenter,
    o.CreatedOn,
    o.ModifiedOn,
    o.DataSource,
    COALESCE(pm.[New Pipeline Phase], o.PipelinePhase, 'Unmapped') AS NewPipelinePhase,
    CASE
        WHEN o.DataSource = 'Income Assignment'
        THEN 'https://wtwcrb.crm.dynamics.com/main.aspx?appid=af96b65c-0084-ea11-a813-000d3a579b83&forceUCI=1&pagetype=entityrecord&etn=rs_incomeassignment&id=' + o.MainKey
        WHEN o.DataSource = 'Opportunity Service (No IA)'
        THEN 'https://wtwcrb.crm.dynamics.com/main.aspx?appid=af96b65c-0084-ea11-a813-000d3a579b83&forceUCI=1&pagetype=entityrecord&etn=rs_opportunityservice&id=' + o.MainKey
        ELSE 'https://wtwcrb.crm.dynamics.com/main.aspx?appid=af96b65c-0084-ea11-a813-000d3a579b83&forceUCI=1&pagetype=entityrecord&etn=opportunity&id=' + o.MainKey
    END AS OpptyLink,
    CASE
        WHEN o.FirstIncomeDate < '2025-10-13' THEN 'Y'    -- TODO: make this a config parameter
        ELSE 'N'
    END AS isExpired,
    CASE
        WHEN (CASE WHEN o.FirstIncomeDate < '2025-10-13' THEN 'Y' ELSE 'N' END = 'Y') AND o.OpptyState = 'Open' THEN 'Overdue'
        WHEN COALESCE(pm.[New Pipeline Phase], o.PipelinePhase, 'Unmapped') = '1 - Discover' AND o.OpptyState = 'Open' THEN 'Draft'
        WHEN COALESCE(pm.[New Pipeline Phase], o.PipelinePhase, 'Unmapped') IN ('2 - DEVELOP', '3 - DESIGN', '4 - PROPOSE') AND o.OpptyState = 'Open' THEN 'Open'
        WHEN COALESCE(pm.[New Pipeline Phase], o.PipelinePhase, 'Unmapped') = '5 - Finalise' AND o.OpptyState = 'Open' AND REPLACE(o.LikelihoodOfWin, '%', '') IN ('80', '100') THEN 'Won'
        ELSE o.OpptyState
    END AS Status,
    CASE
        WHEN o.OpptyType = 'Renewal' AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') = 'Renewal' THEN 'RENEWAL'
        WHEN o.OpptyType = 'Renewal' AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') IN ('One off', 'Unmapped') THEN 'ONE OFF'
        WHEN o.OpptyType = 'Renewal' AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') = 'Recurring & One off' THEN 'RENEWAL'
        WHEN o.OpptyType IN ('New From Existing', 'New-New', 'Global FAC', 'Cross Sell', 'Wholesale') AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') = 'Recurring' THEN 'NEW BUSINESS'
        WHEN o.OpptyType IN ('New From Existing', 'New-New', 'Global FAC', 'Cross Sell', 'Wholesale') AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') = 'One off' THEN 'ONE OFF'
        WHEN o.OpptyType IN ('New From Existing', 'New-New', 'Global FAC', 'Cross Sell', 'Wholesale') AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') = 'Recurring & One off' THEN 'NEW BUSINESS'
        WHEN o.OpptyType IN ('New From Existing', 'New-New', 'Global FAC', 'Cross Sell', 'Wholesale') AND COALESCE(fm.Frequency, o.Frequency, 'Unmapped') = 'Unmapped' THEN 'ONE OFF'
        ELSE o.OpptyType
    END AS AUNZOpptyType,
    COALESCE(glob_prod.[GLOB Mapping], glob_pc.[Profit Center to GLOB Mapping], 'Not CRB') AS [GLOB Mapping]
FROM [dbo].[clean_crm_opportunity_unified] o    -- was: [vw_Bronze_Opportunity_Unified]
LEFT JOIN [APAC_CRM_Analytics_LH].[dbo].[Frequency Mapping] fm
    ON UPPER(COALESCE(o.Frequency, 'Unmapped')) = fm.[CRM Frequency]
LEFT JOIN [APAC_CRM_Analytics_LH].[dbo].[Pipeline Phasing Mapping] pm
    ON UPPER(COALESCE(o.PipelinePhase, 'Unmapped')) = pm.[D365 Pipeline Phase]
LEFT JOIN [APAC_CRM_Analytics_LH].[dbo].[CRB_Sub Product Class to GLOB Mapping] glob_prod
    ON UPPER(o.Service) = UPPER(glob_prod.[D365 Product Sub Class])
LEFT JOIN [APAC_CRM_Analytics_LH].[dbo].[CRB_Profit Center to GLOB Mapping] glob_pc
    ON UPPER(o.ProfitCenter) = UPPER(glob_pc.[D365 Profit Center])
WHERE o.ReportingOfficeCountry NOT IN ('Canada', 'Germany', 'Great Britain', 'Turkey', 'United Kingdom', 'United States', 'USA')
    AND o.ReportingOfficeRegion IN ('Asia', 'Australasia', 'Vietnam- to be deleted')
    AND REPLACE(REPLACE(o.ReportingOfficeCountry, 'Viet Nam', 'Vietnam'), 'Korea, Republic of', 'South Korea')
        NOT IN ('Brazil', 'Chile', 'Denmark', 'Mexico', 'Norway', 'South Africa', 'Spain', 'Venezuela')
