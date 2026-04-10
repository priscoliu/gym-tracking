-- =============================================================================
-- 02_silver_master_crm_sales
-- Was:    [dbo].[Final FactSales]
-- Output: master_crm_sales
-- Source: src_crm_sales (Bronze) + Legacy CIS _Bronze_
-- Layer:  Silver
-- Depends on: clean_crm_account, clean_crm_users, clean_crm_product,
--             clean_crm_profitcenter (all must be materialised first)
--
-- Issues to resolve before converting to notebook:
--   1. VIEW-ON-VIEW dependency — joins to Final Users, Final Account, etc.
--      In notebooks these must be materialised Delta tables, not views.
--      Execution order: account/users/product/profitcenter → THEN this notebook.
--   2. Legacy MainKey uses ROW_NUMBER — non-deterministic on re-runs.
--      Fix: use OpptyID + CAST(ROW_NUMBER as stable surrogate) or hash.
--   3. Legacy CIS _Bronze_ is NOT in the new Bronze pipeline yet.
--   4. [Final Users/Account/ProductClass/ProfitCenter] → new names:
--      clean_crm_users / clean_crm_account / clean_crm_product / clean_crm_profitcenter
--   5. Source [Bronze CRM Sales] → new name: src_crm_sales
-- =============================================================================

CREATE OR ALTER VIEW [dbo].[master_crm_sales] AS
SELECT
    CAST(MainKey AS VARCHAR(255)) AS MainKey,
    CAST(OpportunityID AS VARCHAR(255)) AS OpportunityID,
    CAST(AccountKey AS VARCHAR(255)) AS AccountKey,
    CAST(OpportunityOwnerKey AS VARCHAR(255)) AS OpportunityOwnerKey,
    CAST(ColleagueInvolvedKey AS VARCHAR(255)) AS ColleagueInvolvedKey,
    CurrencyKey,
    CampaignKey,
    CAST(ProductClassKey AS VARCHAR(255)) AS ProductClassKey,
    CAST(ProfitCenterKey AS VARCHAR(255)) AS ProfitCenterKey,
    CreatedDate,
    CloseDate,
    ModifiedDate,
    FirstIncomeDate,
    EstRevenueLCY,
    EstRevenueUSD,
    WtRevenueLCY,
    WtRevenueUSD,
    CAST(DataSource AS VARCHAR(255)) AS DataSource
FROM [dbo].[src_crm_sales]    -- was: [Bronze CRM Sales]

UNION ALL

SELECT
    -- TODO: replace ROW_NUMBER with stable key
    CAST(l.OpptyID AS VARCHAR(255)) + '_' +
    CAST(ROW_NUMBER() OVER (PARTITION BY l.OpptyID ORDER BY l.ColleagueInvolved, l.CreatedOn) AS VARCHAR(10)) AS MainKey,

    CAST(l.OpptyID AS VARCHAR(255)) AS OpportunityID,
    CAST(COALESCE(a.AccountKey, l.Account) AS VARCHAR(255)) AS AccountKey,
    CAST(COALESCE(u1.UserKey, l.OpptyOwner) AS VARCHAR(255)) AS OpportunityOwnerKey,
    CAST(COALESCE(u2.UserKey, l.ColleagueInvolved) AS VARCHAR(255)) AS ColleagueInvolvedKey,
    CAST(NULL AS VARCHAR(255)) AS CurrencyKey,
    CAST(NULL AS VARCHAR(255)) AS CampaignKey,
    CAST(COALESCE(p.ProductClassKey, l.LobProductClass) AS VARCHAR(255)) AS ProductClassKey,
    CAST(COALESCE(pc.ProfitcenterKey, l.ProfitCenter) AS VARCHAR(255)) AS ProfitCenterKey,
    CAST(l.CreatedOn AS DATE) AS CreatedDate,
    CAST(l.CloseDate AS DATE) AS CloseDate,
    CAST(NULL AS DATE) AS ModifiedDate,
    CAST(l.[First Income Date] AS DATE) AS FirstIncomeDate,
    CAST(NULL AS BIGINT) AS EstRevenueLCY,
    CAST(l.[Est. Revenue _USD_] AS BIGINT) AS EstRevenueUSD,
    CAST(NULL AS BIGINT) AS WtRevenueLCY,
    CAST(l.[Wt. Revenue _USD_] AS BIGINT) AS WtRevenueUSD,
    CAST('Legacy CIS' AS VARCHAR(255)) AS DataSource
FROM [dbo].[src_crm_legacy_cis] l    -- was: [Legacy CIS _Bronze_]
LEFT JOIN [dbo].[clean_crm_users] u1
    ON UPPER(LTRIM(RTRIM(l.OpptyOwner))) = UPPER(LTRIM(RTRIM(u1.UserName)))
LEFT JOIN [dbo].[clean_crm_users] u2
    ON UPPER(LTRIM(RTRIM(l.ColleagueInvolved))) = UPPER(LTRIM(RTRIM(u2.UserName)))
LEFT JOIN [dbo].[clean_crm_product] p
    ON UPPER(LTRIM(RTRIM(l.LobProductClass))) = UPPER(LTRIM(RTRIM(p.ProductName)))
LEFT JOIN [dbo].[clean_crm_profitcenter] pc
    ON UPPER(LTRIM(RTRIM(l.ProfitCenter))) = UPPER(LTRIM(RTRIM(pc.ProfitCenter)))
LEFT JOIN [dbo].[clean_crm_account] a
    ON UPPER(LTRIM(RTRIM(l.Account))) = UPPER(LTRIM(RTRIM(a.AccountName)))
WHERE CAST(l.OpptyID AS VARCHAR(255)) NOT IN (
    SELECT OpportunityID FROM [dbo].[src_crm_sales]    -- was: [Bronze CRM Sales]
)
