-- =============================================================================
-- 01_bronze_ingest_crm_systemuser
-- Output: src_crm_systemuser  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — systemuser entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. Pull all active users — this is
-- reference data used at Silver for both opportunity owner and colleague involved.
--
-- dbt Phase 2: joins to src_crm_opportunity on ownerid = systemuserid
--   and to src_crm_income_assignment on rs_colleague = systemuserid.
-- =============================================================================

SELECT
    systemuserid,
    [fullname],
    domainname,
    territoryidname,
    rs_officename,
    address1_country,
    rs_profitcentername
FROM
    systemuser
WHERE
    isdisabled = 0
    AND islicensed = 1
