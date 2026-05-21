-- =============================================================================
-- 01_bronze_ingest_crm_office
-- Output: src_crm_office  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — rs_office entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. Pull all active offices — used at
-- Silver for subregion/country fallback in APAC filter logic.
--
-- dbt Phase 2: joins to src_crm_opportunity on rs_office = rs_officeid
--   and to src_crm_opportunity_service on rs_office = rs_officeid.
-- =============================================================================

SELECT
    rs_officeid,
    rs_name,
    rs_countryname,
    rs_subregionname,
    statecodename
FROM
    rs_office
WHERE
    statecode = 0
