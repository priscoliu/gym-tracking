-- Intermediate: CIS Historical enriched (HWC CRM pre-2023)
-- Source:  {{ ref('stg_billing__cis_historical') }}
-- Output:  apac_billing_silver.int_billing__cis_historical_enriched (table)
-- Mirrors the legacy CIS M baseline:
--   - Filter to rows with IncomeInceptionDate < 2023-01-01
--   - Add Source = 'CIS' (DataSource stays whatever the source file has, typically 'CRM')
--   - Conform to baseline 18-col schema (DUNSNO, Currency, GCID = NULL since CIS source doesn't have them)
-- Feeds the unified fct_billing_baseline mart; HWC_CRM (post-2023 D365 path) joins separately.

with stg as (
    select * from {{ ref('stg_billing__cis_historical') }}
    where IncomeInceptionDate < cast('2023-01-01' as datetime)
),

derived as (
    select
        SystemClientName,
        SystemProductClass,
        TX_ID,
        IncomeInceptionDate,
        Revenue,
        cast(0.0 as decimal(18,2))                                            as Premium,
        SystemID,
        RevenueCountry,
        ClientID,
        DataSource,
        Segment,
        BusinessType,
        RecurringRevenue,
        RevenueCities,
        cast('' as nvarchar(50))                                              as DUNSNO,
        cast(null as nvarchar(10))                                            as Currency,   -- pre-2023 file has no Currency col
        cast(null as nvarchar(50))                                            as GCID,
        cast('CIS' as nvarchar(50))                                           as [Source],
        [SubProduct/Service],
        [Product/Service]
    from stg
)

select * from derived
