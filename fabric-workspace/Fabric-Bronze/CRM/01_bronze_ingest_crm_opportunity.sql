-- =============================================================================
-- 01_bronze_ingest_crm_opportunity
-- Output: src_crm_opportunity  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — opportunity entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No joins, no aggregation.
-- APAC scope filter applied here on rs_regionname (direct field only).
-- Full APAC filter (via office / territory fallback) is Silver responsibility.
--
-- dbt Phase 2: this table becomes the primary source for stg_crm__opportunity.
-- =============================================================================

SELECT
    opportunityid,
    rs_opportunitynumber,
    [name],
    stepname,
    [description],
    rs_formname,
    rs_productclassname,
    rs_productsubclassname,
    rs_frequencyname,
    statuscodename,
    statecodename,
    statecode,
    rs_opportunitytypename,
    rs_opportunitysubtypename,
    estimatedvalue,
    estimatedvalue_base,
    rs_weightedincome,
    rs_weightedincome_base,
    transactioncurrencyid,
    rs_probabilityname,
    rs_premium_base,
    rs_projectstartdate,
    rs_latestmodifieddate,
    createdon,
    actualclosedate,
    campaignidname,
    parentaccountid,
    parentaccountidname,
    ownerid,
    owneridname,
    rs_regionname,
    rs_officename,
    rs_office,
    rs_incomeassignmentprofitcenter1name,
    rs_incomeassignmentfinancelevel11name,
    rs_inceptiondate,
    originatingleadid
FROM
    opportunity
WHERE
    statuscodename != 'Duplicate Entry'
