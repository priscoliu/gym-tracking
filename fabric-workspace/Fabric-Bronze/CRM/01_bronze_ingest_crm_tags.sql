-- =============================================================================
-- 01_bronze_ingest_crm_tags
-- Output: src_crm_tags  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — rs_tagslist + rs_rs_tagslist_opportunity (junction)
-- Layer:  Bronze
--
-- Bronze contract: one row per opportunity-tag combination. The STRING_AGG
-- aggregation to produce "tag1 / tag2" strings is Silver responsibility.
--
-- dbt Phase 2: source for bridge_account_tags or inline in stg_crm__opportunity.
-- =============================================================================

SELECT
    ot.opportunityid,
    ot.rs_tagslistid,
    tag.rs_name AS TagName
FROM
    rs_rs_tagslist_opportunity ot
    LEFT JOIN rs_tagslist tag ON tag.rs_tagslistid = ot.rs_tagslistid
