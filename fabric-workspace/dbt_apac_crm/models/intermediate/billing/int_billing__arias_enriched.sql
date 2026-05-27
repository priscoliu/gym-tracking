-- Intermediate: Arias enriched
-- Source:  {{ ref('stg_billing__arias') }}
-- Output:  apac_billing.int_billing__arias_enriched (table)
-- Applies Silver baseline business logic: HB team filter, BusinessType / RecurringRevenue derivation,
-- hardcoded RevenueCountry/Currency, SystemID/TX_ID/ClientID construction. Conforms to the 18-column
-- standard schema that all 8 baselines feed into fct_billing_baseline.

with stg as (
    select * from {{ ref('stg_billing__arias') }}
    where TeamName <> 'HB' or TeamName is null
),

derived as (
    select
        ClientName                                                            as SystemClientName,
        InsuranceType                                                         as SystemProductClass,
        case
            when InvoiceNumber is null or InvoiceNumber = '' then ''
            else 'ARIAS-' + InvoiceNumber
        end                                                                   as TX_ID,
        InceptionDate                                                         as IncomeInceptionDate,
        Revenue,
        Premium,
        'ARIAS-' + isnull(PolicyNo, '')                                       as SystemID,
        cast('Japan' as nvarchar(50))                                         as RevenueCountry,
        case
            when Gcid is null or Gcid = '' then 'ARIAS-' + isnull(PolicyNo, '')
            else Gcid
        end                                                                   as ClientID,
        cast('ARIAS' as nvarchar(50))                                         as DataSource,
        cast('CRB'   as nvarchar(50))                                         as Segment,
        case
            when RecurringFlag = 'N' then 'New Business'
            when RecurringFlag = 'R' then 'Renewal'
            else RecurringFlag
        end                                                                   as BusinessType,
        case
            when RecurringFlag = 'R' then 'Y'
            when RecurringFlag = 'N' then 'N'
            else RecurringFlag
        end                                                                   as RecurringRevenue,
        cast('' as nvarchar(100))                                             as RevenueCities,
        cast('' as nvarchar(50))                                              as DUNSNO,
        cast('JPY' as nvarchar(10))                                           as Currency,
        Gcid                                                                  as GCID,
        cast('ARIAS' as nvarchar(50))                                         as [Source]
    from stg
)

select * from derived
