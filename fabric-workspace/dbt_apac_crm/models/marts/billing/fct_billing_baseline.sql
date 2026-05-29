-- Mart: fct_billing_baseline
-- Output: apac_billing_gold.fct_billing_baseline (table)
-- Unified baseline fact -- UNION ALL of all 7 billing sources, conformed to 22-column schema.
--
-- Extra columns (NULL-padded for sources that don't populate them):
--   * SystemProductClass2 -- only Eclipse CRB populates (= ClassOfBusiness)
--   * SubProduct/Service  -- only WR SPM populates (= 'RDI')
--   * Product/Service     -- only WR SPM populates (= 'RDI')
--   * OpptyState          -- only HWC_CRM populates (not yet wired -- see TODO below)
--
-- TODO (not yet wired -- to mirror the legacy baseline_final_TX gold view):
--   1. Add HWC_CRM source (from CRM side, not billing)
--   2. Apply baseline_ExchangeRate to convert non-USD Revenue/Premium
--   3. Apply baseline_ProductMapping to derive Product/Service & SubProduct/Service
--   4. Apply final transformations: SystemProductClass override for Eclipse,
--      RevenueCountry normalization (KOREA -> SOUTH KOREA, INDIA CONSULTING -> INDIA, Viet Nam -> Vietnam),
--      GCID cleaning (REPLACE '-')

with arias as (
    select
        SystemClientName,
        SystemProductClass,
        TX_ID,
        IncomeInceptionDate,
        Revenue,
        Premium,
        SystemID,
        RevenueCountry,
        ClientID,
        DataSource,
        Segment,
        BusinessType,
        RecurringRevenue,
        RevenueCities,
        DUNSNO,
        Currency,
        GCID,
        [Source],
        cast(null as nvarchar(255)) as [SubProduct/Service],
        cast(null as nvarchar(255)) as [Product/Service],
        cast(null as nvarchar(255)) as SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__arias_enriched') }}
),

saiba as (
    select
        SystemClientName, SystemProductClass, TX_ID, IncomeInceptionDate,
        Revenue, Premium, SystemID, RevenueCountry, ClientID,
        DataSource, Segment, BusinessType, RecurringRevenue, RevenueCities,
        DUNSNO, Currency, GCID, [Source],
        cast(null as nvarchar(255)) as [SubProduct/Service],
        cast(null as nvarchar(255)) as [Product/Service],
        cast(null as nvarchar(255)) as SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__saiba_enriched') }}
),

eclipse_crb as (
    select
        SystemClientName, SystemProductClass, TX_ID, IncomeInceptionDate,
        Revenue, Premium, SystemID, RevenueCountry, ClientID,
        DataSource, Segment, BusinessType, RecurringRevenue, RevenueCities,
        DUNSNO, Currency, GCID, [Source],
        cast(null as nvarchar(255)) as [SubProduct/Service],
        cast(null as nvarchar(255)) as [Product/Service],
        SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__eclipse_crb_enriched') }}
),

eglobal_income as (
    select
        SystemClientName, SystemProductClass, TX_ID, IncomeInceptionDate,
        Revenue, Premium, SystemID, RevenueCountry, ClientID,
        DataSource, Segment, BusinessType, RecurringRevenue, RevenueCities,
        DUNSNO, Currency, GCID, [Source],
        cast(null as nvarchar(255)) as [SubProduct/Service],
        cast(null as nvarchar(255)) as [Product/Service],
        cast(null as nvarchar(255)) as SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__eglobal_income_enriched') }}
),

gswin as (
    select
        SystemClientName, SystemProductClass, TX_ID, IncomeInceptionDate,
        Revenue, Premium, SystemID, RevenueCountry, ClientID,
        DataSource, Segment, BusinessType, RecurringRevenue, RevenueCities,
        DUNSNO, Currency, GCID, [Source],
        cast(null as nvarchar(255)) as [SubProduct/Service],
        cast(null as nvarchar(255)) as [Product/Service],
        cast(null as nvarchar(255)) as SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__gswin_enriched') }}
),

ret_oracle as (
    select
        SystemClientName, SystemProductClass, TX_ID, IncomeInceptionDate,
        Revenue, Premium, SystemID, RevenueCountry, ClientID,
        DataSource, Segment, BusinessType, RecurringRevenue, RevenueCities,
        DUNSNO, Currency, GCID, [Source],
        cast(null as nvarchar(255)) as [SubProduct/Service],
        cast(null as nvarchar(255)) as [Product/Service],
        cast(null as nvarchar(255)) as SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__ret_oracle_enriched') }}
),

wr_spm as (
    select
        SystemClientName, SystemProductClass, TX_ID, IncomeInceptionDate,
        Revenue, Premium, SystemID, RevenueCountry, ClientID,
        DataSource, Segment, BusinessType, RecurringRevenue, RevenueCities,
        DUNSNO, Currency, GCID, [Source],
        [SubProduct/Service],
        [Product/Service],
        cast(null as nvarchar(255)) as SystemProductClass2,
        cast(null as nvarchar(50))  as OpptyState
    from {{ ref('int_billing__wr_spm_enriched') }}
),

unioned as (
    select * from arias
    union all select * from saiba
    union all select * from eclipse_crb
    union all select * from eglobal_income
    union all select * from gswin
    union all select * from ret_oracle
    union all select * from wr_spm
)

select * from unioned
