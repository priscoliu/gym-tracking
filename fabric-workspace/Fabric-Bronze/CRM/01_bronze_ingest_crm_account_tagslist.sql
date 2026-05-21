-- =============================================================================
-- 01_bronze_ingest_crm_account_tagslist
-- Output: src_crm_account_tagslist  -> APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse - rs_account_rs_tagslist junction table
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. Many-to-many junction between
-- account and rs_tagslist. No filter - pull all rows.
--
-- Composite key: accountid + rs_tagslistid
-- =============================================================================

SELECT
    accountid,
    rs_tagslistid
FROM
    rs_account_rs_tagslist
