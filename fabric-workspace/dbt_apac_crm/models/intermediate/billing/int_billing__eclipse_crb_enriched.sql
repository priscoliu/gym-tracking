-- Intermediate: Eclipse CRB enriched
-- Source:  {{ ref('stg_billing__eclipse_crb') }}
-- Output:  apac_billing_silver.int_billing__eclipse_crb_enriched (table)
-- Indonesia and Taiwan legal entities filtered. Currency=USD hardcoded. RevenueCountry derived from
-- BusinessUnit+Team (Singapore retail) or LegalEntity text-contains (HK / Philippines / Indonesia).
-- Eclipse populates SystemProductClass2 (= ClassOfBusiness) -- other sources NULL pad it in the mart.

with stg as (
    select * from {{ ref('stg_billing__eclipse_crb') }}
    where LegalEntity not in (
        'PT. Willis Reinsurance Brokers Indonesia',
        'Willis Towers Watson Taiwan Limited'
    )
),

derived as (
    select
        Insured                                                               as SystemClientName,
        BusinessUnit + '+' + Team + '+' + ClassOfBusiness                     as SystemProductClass,
        ClassOfBusiness                                                       as SystemProductClass2,
        PolicyRef                                                             as TX_ID,
        InceptionDate                                                         as IncomeInceptionDate,
        NetBkgeUsdPlan                                                        as Revenue,
        GrossPremNonTtyUsdPlan                                                as Premium,
        'ECLIPSE-' + isnull(InsuredId, '')                                    as SystemID,
        case
            when BusinessUnit + '+' + Team in (
                'Retail+Corporate', 'Retail+Commercial', 'Retail+FINEX', 'Retail+Network',
                'Retail+Asia Finex M&A', 'Retail+Asia Placement',
                'Retail+Client Service Team 1', 'Retail+Client Service Team 2', 'Retail+Client Service Team 3'
            ) then 'Singapore'
            when LegalEntity like '%Hong Kong%'   then 'Hong Kong'
            when LegalEntity like '%Philippines%' then 'Philippines'
            when LegalEntity like '%Indonesia%'   then 'Indonesia'
            else 'Asia Virtual'
        end                                                                   as RevenueCountry,
        case
            when WillisPartyId is null or WillisPartyId = ''
                then 'ECLIPSE-' + isnull(InsuredId, '')
            else WillisPartyId
        end                                                                   as ClientID,
        cast('ECLIPSE' as nvarchar(50))                                       as DataSource,
        BuSegment                                                             as Segment,
        case
            when RevenueType = 'New/Existing-One Off'    then 'New Business'
            when RevenueType = 'New/New - Recurring'     then 'Renewal'
            when RevenueType = 'New'                     then 'New Business'
            when RevenueType = 'New / New - One-Off'     then 'New Business'
            else RevenueType
        end                                                                   as BusinessType,
        case
            when RevenueType in ('New/Existing-One Off', 'New / New - One-Off') then 'N'
            else 'Y'
        end                                                                   as RecurringRevenue,
        cast('' as nvarchar(100))                                             as RevenueCities,
        DunsNo                                                                as DUNSNO,
        cast('USD' as nvarchar(10))                                           as Currency,
        WillisPartyId                                                         as GCID,
        cast('ECLIPSE' as nvarchar(50))                                       as [Source]
    from stg
)

select * from derived
