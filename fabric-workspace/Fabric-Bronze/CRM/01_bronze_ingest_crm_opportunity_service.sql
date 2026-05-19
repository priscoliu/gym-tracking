-- =============================================================================
-- 01_bronze_ingest_crm_opportunity_service
-- Output: src_crm_opportunity_service  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — rs_opportunityservice entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No joins, no aggregation.
-- Active service lines only (statecode = 0). Inactive lines are irrelevant.
--
-- dbt Phase 2: joins to src_crm_opportunity on rs_opportunity = opportunityid.
-- =============================================================================

SELECT
    rs_opportunityserviceid,
    rs_opportunity,
    rs_opportunityname,
    rs_lobname,
    rs_servicename,
    rs_frequencyname,
    rs_linevalue,
    rs_linevalue_base,
    transactioncurrencyid,
    rs_officename,
    rs_office,
    statecode,
    createdon,
    modifiedon
FROM
    rs_opportunityservice
WHERE
    statecode = 0
