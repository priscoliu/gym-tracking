-- Intermediate: GSWin enriched
-- Source:  {{ ref('stg_billing__gswin') }}
-- Output:  apac_billing_silver.int_billing__gswin_enriched (table)
-- H&B WillisLine filtered. Currency=USD, RevenueCountry=Vietnam hardcoded.

with stg as (
    select * from {{ ref('stg_billing__gswin') }}
    where WillisLine <> 'H&B'
),

derived as (
    select
        ClientName                                                            as SystemClientName,
        PolicyTypeName                                                        as SystemProductClass,
        PolicyNumber                                                          as TX_ID,
        InceptionDate                                                         as IncomeInceptionDate,
        TotalBrokerageUsd                                                     as Revenue,
        PremiumUsd                                                            as Premium,
        'GSWin-' + isnull(ClientId, '')                                       as SystemID,
        cast('Vietnam' as nvarchar(50))                                       as RevenueCountry,
        case
            when Gcid is null then 'GSWin-' + isnull(ClientId, '')
            else Gcid
        end                                                                   as ClientID,
        cast('GSWin' as nvarchar(50))                                         as DataSource,
        WillisLine                                                            as Segment,
        case
            when NewOrRenew = 'N' then 'New Business'
            when NewOrRenew = 'R' then 'Renewal'
            else NewOrRenew
        end                                                                   as BusinessType,
        case
            when Renewable = 'R' then 'Y'
            when Renewable = 'N' then 'N'
            else 'N'
        end                                                                   as RecurringRevenue,
        cast('' as nvarchar(100))                                             as RevenueCities,
        cast('' as nvarchar(50))                                              as DUNSNO,
        cast('USD' as nvarchar(10))                                           as Currency,
        Gcid                                                                  as GCID,
        cast('GSWin' as nvarchar(50))                                         as [Source]
    from stg
)

select * from derived
