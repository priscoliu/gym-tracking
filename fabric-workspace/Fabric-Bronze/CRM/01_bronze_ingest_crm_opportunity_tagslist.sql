-- =============================================================================
-- 01_bronze_ingest_crm_opportunity_tagslist
-- Output: src_crm_opportunity_tagslist  -> APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse - rs_rs_tagslist_opportunity junction table
-- Layer:  Bronze
--
-- Bronze contract: raw many-to-many junction between opportunity and rs_tagslist.
-- TagName lookup is dbt intermediate responsibility (join to stg_crm_tagslist).
--
-- Composite key: opportunityid + rs_tagslistid
-- =============================================================================

SELECT
    opportunityid,
    rs_tagslistid
FROM
    rs_rs_tagslist_opportunity
