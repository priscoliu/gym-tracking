-- =============================================================================
-- 01_bronze_ingest_crm_account
-- Output: src_crm_account  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — account entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. No filter by region — accounts are
-- global reference data used for enrichment at Silver.
--
-- dbt Phase 2: joins to src_crm_opportunity on parentaccountid = accountid.
-- =============================================================================

SELECT
    accountid,
    accountnumber,
    [name],
    parentaccountid,
    parentaccountidname,
    rs_ultimateglobalparentname,
    rs_dunsnumber,
    rs_clientsegmentationname,
    rs_industryname,
    rs_primarysiccodename,
    rs_address1countryname,
    address1_stateorprovince,
    statecodename
FROM
    account
WHERE
    statecode = 0
