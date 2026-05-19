-- =============================================================================
-- 01_bronze_ingest_crm_income_assignment
-- Output: src_crm_income_assignment  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — rs_incomeassignment entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No joins, no aggregation.
-- Include both active (0) and null statecode rows — null is valid for legacy IA.
--
-- dbt Phase 2: joins to src_crm_opportunity_service on
--   rs_serviceline = rs_opportunityserviceid.
-- =============================================================================

SELECT
    rs_incomeassignmentid,
    rs_serviceline,
    rs_colleague,
    rs_colleaguename,
    rs_profitcenter,
    rs_profitcentername,
    rs_share,
    rs_share_base,
    statecode,
    createdon,
    modifiedon
FROM
    rs_incomeassignment
WHERE
    statecode = 0 OR statecode IS NULL
