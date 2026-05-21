-- =============================================================================
-- 01_bronze_ingest_crm_productclass
-- Output: src_crm_productclass  -> APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse - rs_productclass entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No statecode filter at Bronze - keep
-- all rows including inactive product classes for historical opportunity lookup.
--
-- dbt Phase 2: source for dim_product.
-- =============================================================================

SELECT
    rs_productclassid,
    createdon,
    modifiedon,
    rs_name,
    rs_segmentname,
    rs_businessname,
    statecodename
FROM
    rs_productclass
ORDER BY
    rs_name ASC
