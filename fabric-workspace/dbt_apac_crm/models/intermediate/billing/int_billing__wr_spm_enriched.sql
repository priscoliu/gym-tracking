-- Intermediate: WR SPM enriched
-- Source:  {{ ref('stg_billing__wr_spm') }}
-- Output:  apac_billing_silver.int_billing__wr_spm_enriched (table)
-- 14 Operating Units filtered (HK, TW, CN, PH, SG, MY, ID, TH, JP, KR, IN, AU). Currency kept from source.
-- WR populates Product/Service and SubProduct/Service (= 'RDI') -- other sources NULL pad them in mart.
-- TODO: GCID join with OracleID Mapping ref table -- currently GCID stays NULL and ClientID falls back to SystemID.

with stg as (
    select * from {{ ref('stg_billing__wr_spm') }}
    where OperatingUnit in (
        'TW OU HK 3022-Hong Kong',
        'TW OU TW 3121-Delaware Taiwan',
        'TW OU CN 3241-Shanghai',
        'TW OU PH 3101-Philippines',
        'TW OU CN 3243-Beijing Br',
        'TW OU SG 3042- Willis Towers Watson Consulting (Singapore) Pte Ltd',
        'TW OU MY 3081-Malaysia',
        'TW OU ID 3162-Indonesia',
        'TW OU CN 3248-TW Mgmt Cons Shenzhen',
        'TW OU TH 3221-Thailand',
        'TW OU JP 3062-KK',
        'TW OU KR 3183-Willis Towers Watson Consulting Korea Limited',
        'TW OU IN 3002-India Pvt',
        'TW OU AU 3141-Australia'
    )
),

derived as (
    select
        BillToCustomer                                                        as SystemClientName,
        cast('RDI' as nvarchar(255))                                          as SystemProductClass,
        cast('RDI' as nvarchar(255))                                          as [SubProduct/Service],
        cast('RDI' as nvarchar(255))                                          as [Product/Service],
        Reference                                                             as TX_ID,
        TxnDate                                                               as IncomeInceptionDate,
        InvoiceAmount                                                         as Revenue,
        cast(0.0 as decimal(18,2))                                            as Premium,
        'SPM-' + isnull(BillToCustomerNumber, '')                             as SystemID,
        case
            when OperatingUnit = 'TW OU HK 3022-Hong Kong'                                                          then 'Hong Kong'
            when OperatingUnit = 'TW OU TW 3121-Delaware Taiwan'                                                    then 'Taiwan'
            when OperatingUnit = 'TW OU CN 3241-Shanghai'                                                           then 'China'
            when OperatingUnit = 'TW OU PH 3101-Philippines'                                                        then 'Philippines'
            when OperatingUnit = 'TW OU CN 3243-Beijing Br'                                                         then 'China'
            when OperatingUnit = 'TW OU SG 3042- Willis Towers Watson Consulting (Singapore) Pte Ltd'               then 'Singapore'
            when OperatingUnit = 'TW OU MY 3081-Malaysia'                                                           then 'Malaysia'
            when OperatingUnit = 'TW OU ID 3162-Indonesia'                                                          then 'Indonesia'
            when OperatingUnit = 'TW OU CN 3248-TW Mgmt Cons Shenzhen'                                              then 'China'
            when OperatingUnit = 'TW OU TH 3221-Thailand'                                                           then 'Thailand'
            when OperatingUnit = 'TW OU JP 3062-KK'                                                                 then 'Japan'
            when OperatingUnit = 'TW OU KR 3183-Willis Towers Watson Consulting Korea Limited'                      then 'Korea'
            when OperatingUnit = 'TW OU IN 3002-India Pvt'                                                          then 'India'
            when OperatingUnit = 'TW OU AU 3141-Australia'                                                          then 'Australia'
            else 'NONE'
        end                                                                   as RevenueCountry,
        case
            when OperatingUnit = 'TW OU HK 3022-Hong Kong'                                                          then 'HONG KONG'
            when OperatingUnit = 'TW OU TW 3121-Delaware Taiwan'                                                    then 'Taiwan'
            when OperatingUnit = 'TW OU CN 3241-Shanghai'                                                           then 'Shanghai'
            when OperatingUnit = 'TW OU PH 3101-Philippines'                                                        then 'Philippines'
            when OperatingUnit = 'TW OU CN 3243-Beijing Br'                                                         then 'Beijing'
            when OperatingUnit = 'TW OU SG 3042- Willis Towers Watson Consulting (Singapore) Pte Ltd'               then 'Singapore'
            when OperatingUnit = 'TW OU MY 3081-Malaysia'                                                           then 'Malaysia'
            when OperatingUnit = 'TW OU ID 3162-Indonesia'                                                          then 'Indonesia'
            when OperatingUnit = 'TW OU CN 3248-TW Mgmt Cons Shenzhen'                                              then 'Shenzhen'
            when OperatingUnit = 'TW OU TH 3221-Thailand'                                                           then 'Thailand'
            when OperatingUnit = 'TW OU JP 3062-KK'                                                                 then 'Japan'
            when OperatingUnit = 'TW OU KR 3183-Willis Towers Watson Consulting Korea Limited'                      then 'Korea'
            when OperatingUnit = 'TW OU IN 3002-India Pvt'                                                          then 'India'
            when OperatingUnit = 'TW OU AU 3141-Australia'                                                          then 'Australia'
            else 'NONE'
        end                                                                   as RevenueCities,
        'SPM-' + isnull(BillToCustomerNumber, '')                             as ClientID,
        cast('SPM'     as nvarchar(50))                                       as DataSource,
        cast('W&R'     as nvarchar(50))                                       as Segment,
        cast('Renewal' as nvarchar(50))                                       as BusinessType,
        cast('Y' as nvarchar(10))                                             as RecurringRevenue,
        cast('' as nvarchar(50))                                              as DUNSNO,
        Currency                                                              as Currency,
        cast(null as nvarchar(50))                                            as GCID,   -- TODO: OracleID Mapping join
        cast('SPM' as nvarchar(50))                                           as [Source]
    from stg
)

select * from derived
