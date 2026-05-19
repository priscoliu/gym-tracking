-- =============================================================================
-- 01_bronze_ingest_crm_currency
-- Output: src_crm_currency  → APAC_CRM_Analytics_bronze_LH
-- Source: Dataverse — transactioncurrency entity
-- Layer:  Bronze
--
-- Bronze contract: raw D365 columns only. Pull all active currencies.
--
-- dbt Phase 2: source for dim_currency.
-- =============================================================================

SELECT
    transactioncurrencyid,
    currencyname,
    exchangerate,
    currencysymbol,
    isocurrencycode,
    statecode
FROM
    transactioncurrency
WHERE
    statecode = 0
