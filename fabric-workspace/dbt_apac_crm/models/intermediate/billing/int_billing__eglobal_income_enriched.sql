-- Intermediate: eGlobal Income enriched
-- Source:  {{ ref('stg_billing__eglobal_income') }}
-- Output:  apac_billing_silver.int_billing__eglobal_income_enriched (table)
-- Non-CRB departments (EMB, RET, EBD, EBC, etc) filtered. RevenueCountry/Currency from SourceName pattern.

with stg as (
    select * from {{ ref('stg_billing__eglobal_income') }}
    where Department not in (
        'EMB', 'RET', 'EBD', 'EBC', 'EBM', 'EBS', 'ECS', 'GBM',
        'BEB', 'MEB', 'PEB', 'SEB', 'AEB', 'CEB', 'WEB', 'UEB',
        'HBB', 'HCB'
    )
),

with_country as (
    select
        *,
        case
            when SourceName like '%_AU_%' then cast('Australia'   as nvarchar(50))
            when SourceName like '%_CN.%' then cast('China'       as nvarchar(50))
            when SourceName like '%_HK.%' then cast('Hong Kong'   as nvarchar(50))
            when SourceName like '%_ID.%' then cast('Indonesia'   as nvarchar(50))
            when SourceName like '%_KR.%' then cast('South Korea' as nvarchar(50))
            when SourceName like '%_NZ.%' then cast('New Zealand' as nvarchar(50))
            when SourceName like '%_PH_%' then cast('Philippines' as nvarchar(50))
            when SourceName like '%_RO.%' then cast('Australia'   as nvarchar(50))
            when SourceName like '%_SG.%' then cast('Singapore'   as nvarchar(50))
            when SourceName like '%_TW.%' then cast('Taiwan'      as nvarchar(50))
            else cast('' as nvarchar(50))
        end as DerivedRevenueCountry,
        case
            when SourceName like '%_AU_%' then cast('AUD' as nvarchar(10))
            when SourceName like '%_CN.%' then cast('CNY' as nvarchar(10))
            when SourceName like '%_HK.%' then cast('HKD' as nvarchar(10))
            when SourceName like '%_ID.%' then cast('IDR' as nvarchar(10))
            when SourceName like '%_KR.%' then cast('KRW' as nvarchar(10))
            when SourceName like '%_NZ.%' then cast('NZD' as nvarchar(10))
            when SourceName like '%_PH_%' then cast('PHP' as nvarchar(10))
            when SourceName like '%_RO.%' then cast('AUD' as nvarchar(10))
            when SourceName like '%_SG.%' then cast('SGD' as nvarchar(10))
            when SourceName like '%_TW.%' then cast('TWD' as nvarchar(10))
            else cast('' as nvarchar(10))
        end as DerivedCurrency
    from stg
),

derived as (
    select
        ClientName                                                            as SystemClientName,
        Risk                                                                  as SystemProductClass,
        InvNo                                                                 as TX_ID,
        EffectiveDate                                                         as IncomeInceptionDate,
        TotalIncome                                                           as Revenue,
        Premium                                                               as Premium,
        isnull(Company,'') + isnull(Branch,'') + isnull(ClientNo,'')          as SystemID,
        DerivedRevenueCountry                                                 as RevenueCountry,
        case
            when PartyId is null or PartyId = ''
                then isnull(Company,'') + isnull(Branch,'') + isnull(ClientNo,'')
            else PartyId
        end                                                                   as ClientID,
        cast('eGlobal' as nvarchar(50))                                       as DataSource,
        cast('CRB' as nvarchar(50))                                           as Segment,
        case
            when IncomeClass = 'RRN'         then 'Renewal'
            when IncomeClass in ('MDIAC','MDI') then 'MDI'
            else 'New Business'
        end                                                                   as BusinessType,
        case
            when IncomeClass in ('RRN','RNE','RNN') then 'Y'
            else 'N'
        end                                                                   as RecurringRevenue,
        cast('' as nvarchar(100))                                             as RevenueCities,
        DunsNo                                                                as DUNSNO,
        DerivedCurrency                                                       as Currency,
        PartyId                                                               as GCID,
        cast('eGlobal' as nvarchar(50))                                       as [Source]
    from with_country
)

select * from derived
