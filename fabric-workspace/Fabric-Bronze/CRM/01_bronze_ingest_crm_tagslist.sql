-- =============================================================================
-- 01_bronze_ingest_crm_tagslist
-- Output: src_crm_tagslist  -> APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse - rs_tagslist entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No filter - pull all tags.
-- Tag filtering for APAC business rules is dbt intermediate responsibility.
-- =============================================================================

SELECT
    rs_tagslistid,
    rs_name,
    statecode,
    statecodename,
    createdon,
    modifiedon
FROM
    rs_tagslist
