-- =============================================================================
-- 01_bronze_ingest_crm_profitcenter
-- Output: src_crm_profitcenter  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — rs_profitcenter entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. Pull all active profit centers —
-- used at Silver to resolve Finance Level 1 from income assignment.
--
-- dbt Phase 2: source for dim_profitcenter.
-- =============================================================================

SELECT
    rs_profitcenterid,
    rs_name,
    rs_financelevel1name,
    rs_businessname,
    rs_lobname,
    rs_segmentname,
    statecode
FROM
    rs_profitcenter
WHERE
    statecode = 0
