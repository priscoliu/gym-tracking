-- =============================================================================
-- DEPRECATED — DO NOT CONVERT TO NOTEBOOK
-- Was:    [dbo].[All lobs]
-- Status: Superseded by new pipeline design
--
-- This view was a UNION of [All lobs_OS] + [All Lobs_O], which were outputs of
-- the old crm_bronze_ETL_allLobs_file pipeline (denormalized, heavy SQL at source).
--
-- With the new 01_bronze_ingest_CRM pipeline:
--   - [All lobs_OS] and [All Lobs_O] no longer exist
--   - master_crm_sales + clean_crm_opportunity + dimension tables replace this view
--   - Downstream reports should be rebased onto master_crm_sales
--
-- Kept here for reference and for mapping old column names to new ones.
-- =============================================================================

-- Old column → New location mapping:
--   DunsNumber              → clean_crm_account.DunsNumber
--   OriginatingLeadID       → clean_crm_opportunity.OriginatingLeadID
--   GUID / OpptyID          → master_crm_sales.MainKey / OpportunityID
--   OpptySummary            → clean_crm_opportunity.OpptyName
--   Pipeline Phase          → clean_crm_opportunity.PipelinePhase
--   ProductClass            → clean_crm_product.ProductName (via ProductClassKey)
--   ProductSubClass         → clean_crm_opportunity.Service
--   Est/Wt Revenue LCY/USD  → master_crm_sales.EstRevenueLCY/USD, WtRevenueLCY/USD
--   CCY                     → needs src_crm_currency (gap — add to pipeline)
--   Premium (USD)           → not in new pipeline (gap — confirm if needed)
--   Source Campaign         → needs src_crm_campaign (gap — add to pipeline)
--   Account / Parent / GP   → clean_crm_account.AccountName/ParentAccountName/GlobalParentAccountName
--   GCID / Tiers            → clean_crm_account.GCID / Tiers
--   Service Region/Office   → clean_crm_opportunity.ReportingOfficeRegion/Office
--   Profit Center           → clean_crm_profitcenter.ProfitCenter (via ProfitCenterKey)
--   Finance Level           → clean_crm_profitcenter.Financelevel
--   Opportunity Owner       → clean_crm_users.UserName (via OpportunityOwnerKey)
--   Colleague Involved      → clean_crm_users.UserName (via ColleagueInvolvedKey)
--   TagList                 → GAP — not in new pipeline (add src_crm_tags)
--   Data Version            → master_crm_sales.DataSource

/*
CREATE OR ALTER VIEW [dbo].[All lobs] AS
SELECT [...] FROM [APAC_CRM_Analytics_LH].[dbo].[All lobs_OS]
UNION
SELECT [...] FROM [APAC_CRM_Analytics_LH].[dbo].[All Lobs_O]
*/
