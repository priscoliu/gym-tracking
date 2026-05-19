-- =============================================================================
-- 01_bronze_ingest_crm_lead
-- Output: src_crm_lead  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — lead entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No joins, no aggregation, no region
-- filter. ANZ vs APAC scope is Silver responsibility.
-- Replaces: ANZ_Leads.Dataflow + APAC Leads_.Dataflow (two regional variants
-- collapsed into one unfiltered Bronze pull).
--
-- dbt Phase 2: source for stg_crm__lead.
-- =============================================================================

SELECT
    leadid,
    fullname,
    firstname,
    lastname,
    companyname,
    emailaddress1,
    telephone1,
    mobilephone,
    subject,
    [description],
    leadsourcecodename,
    industrycodename,
    sic,
    budgetamount,
    budgetamount_base,
    numberofemployees,
    estimatedvalue,
    estimatedclosedate,
    ownerid,
    owneridname,
    statecode,
    statecodename,
    statuscodename,
    createdon,
    modifiedon
FROM
    lead
WHERE
    statecode IN (0, 1)
