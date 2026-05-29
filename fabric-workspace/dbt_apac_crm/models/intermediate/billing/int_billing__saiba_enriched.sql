-- Intermediate: Saiba enriched
-- Source:  {{ ref('stg_billing__saiba') }}
-- Output:  apac_billing_silver.int_billing__saiba_enriched (table)
-- EB/HB/H&B departments filtered. RevenueCountry=India, Currency=INR, Segment=CRB hardcoded.

with stg as (
    select * from {{ ref('stg_billing__saiba') }}
    where Department not in ('EB', 'HB', 'H&B')
),

derived as (
    select
        CustName                                                              as SystemClientName,
        PolicyType                                                            as SystemProductClass,
        case
            when Cno is null or Cno = '' then ''
            else Cno + isnull(InstNo, '')
        end                                                                   as TX_ID,
        StartDate                                                             as IncomeInceptionDate,
        Brokerage                                                             as Revenue,
        BrokPrem                                                              as Premium,
        case
            when CustCode is null or CustCode = '' then ''
            else 'Saiba-' + CustCode
        end                                                                   as SystemID,
        cast('India' as nvarchar(50))                                         as RevenueCountry,
        case
            when Gcid is null or ltrim(rtrim(isnull(Gcid, ''))) in ('', '-')
                then case when CustCode is null or CustCode = '' then '' else 'Saiba-' + CustCode end
            else Gcid
        end                                                                   as ClientID,
        cast('Saiba' as nvarchar(50))                                         as DataSource,
        cast('CRB'   as nvarchar(50))                                         as Segment,
        case
            when BizType in ('Expanded', 'New') then 'New Business'
            else BizType
        end                                                                   as BusinessType,
        cast('' as nvarchar(10))                                              as RecurringRevenue,
        cast('' as nvarchar(100))                                             as RevenueCities,
        cast('' as nvarchar(50))                                              as DUNSNO,
        cast('INR' as nvarchar(10))                                           as Currency,
        Gcid                                                                  as GCID,
        cast('Saiba' as nvarchar(50))                                         as [Source]
    from stg
)

select * from derived
