-- =============================================================================
-- 01_bronze_ingest_crm_productsubclass
-- Output: src_crm_productsubclass -> APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse - rs_productsubclass entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No statecode filter at Bronze - keep
-- all rows including inactive sub-classes for historical opportunity lookup.
--
-- dbt Phase 2: source for dim_product (child of rs_productclass).
-- =============================================================================

SELECT
    rs_productsubclassid,
    createdon,
    modifiedon,
    rs_name,
    rs_productclass,
    rs_productclassname,
    statecodename
FROM
    rs_productsubclass
ORDER BY
    rs_name ASC
