-- Intermediate: Oracle RET enriched
-- Source:  {{ ref('stg_billing__ret_oracle') }}
-- Output:  apac_billing_silver.int_billing__ret_oracle_enriched (table)
-- TW_Service_Offering must start with "RET". Segment=RET, BusinessType=Renewal, Currency=USD hardcoded.
-- TODO: GCID join with OracleID Mapping ref table -- currently GCID stays NULL and ClientID falls back to SystemID.
-- FiscalPeriod fix: 8 older files store dates as YYYYMM integers -- reconstruct to first-of-month.

with stg as (
    select * from {{ ref('stg_billing__ret_oracle') }}
    where TwServiceOffering like 'RET%'
),

fiscal_period_fixed as (
    select
        *,
        case
            when SourceName in (
                'Retirement Project Revenue Dec 2018 YTD .xlsx',
                'Retirement Project Revenue Dec 2019 YTD .xlsx',
                'Retirement Project Revenue December YTD 2020.xlsx',
                'Retirement Project Revenue YTD 2021.xlsx',
                'Retirement Project Revenue YTD 2022.xlsx',
                'Retirement Project Revenue YTD 2023.xlsx',
                'Retirement Project Revenue YTD 2024.xlsx',
                'Retirement Project Revenue December YTD 2025.xlsx'
            )
                then try_cast(
                    substring(FiscalPeriodNumber, 1, 4) + '-' +
                    substring(FiscalPeriodNumber, 5, 2) + '-01'
                    as datetime
                )
            else FiscalPeriod
        end as FiscalPeriodFixed
    from stg
),

derived as (
    select
        CustomerName                                                          as SystemClientName,
        TwServiceOffering                                                     as SystemProductClass,
        ProjectNumber                                                         as TX_ID,
        FiscalPeriodFixed                                                     as IncomeInceptionDate,
        RevenueAmount                                                         as Revenue,
        cast(0.0 as decimal(18,2))                                            as Premium,
        'Oracle-' + case
            when PrimaryCustomerAcctNo is not null
                 and PrimaryCustomerAcctNo <> ''
                 and PrimaryCustomerAcctNo <> '0'
                then PrimaryCustomerAcctNo
            else CustomerName
        end                                                                   as SystemID,
        case
            when ltrim(rtrim(replace(EmployeeMarketCluster, 'Market', ''))) = 'India Consulting' then 'India'
            when replace(EmployeeMarketCluster, 'Market', '') = 'AP DATA MANAGEMENT CENTER' then 'Philippines'
            else replace(EmployeeMarketCluster, 'Market', '')
        end                                                                   as RevenueCountry,
        -- GCID join not yet wired -- ClientID falls back to SystemID
        'Oracle-' + case
            when PrimaryCustomerAcctNo is not null
                 and PrimaryCustomerAcctNo <> ''
                 and PrimaryCustomerAcctNo <> '0'
                then PrimaryCustomerAcctNo
            else CustomerName
        end                                                                   as ClientID,
        cast('Oracle' as nvarchar(50))                                        as DataSource,
        cast('RET'    as nvarchar(50))                                        as Segment,
        cast('Renewal' as nvarchar(50))                                       as BusinessType,
        cast('Y' as nvarchar(10))                                             as RecurringRevenue,
        case
            when ProjectOfficeCode = 'HKG1' then 'Hong Kong'
            when ProjectOfficeCode = 'PH$5' then 'Manila'
            when ProjectOfficeCode = 'MEL2' then 'Melbourne'
            when ProjectOfficeCode = 'BEI1' then 'Beijing'
            when ProjectOfficeCode = 'JPM2' then 'Osaka'
            when ProjectOfficeCode = 'SYD1' then 'Sydney'
            when ProjectOfficeCode = 'ISA1' then 'Mount Isa'
            when ProjectOfficeCode = 'THA1' then 'Bangkok'
            when ProjectOfficeCode = 'GUR3' then 'Gurgaon'
            when ProjectOfficeCode = 'BAN1' then 'Bangalore'
            when ProjectOfficeCode = 'KOL1' then 'Kolkata'
            when ProjectOfficeCode = 'SHA1' then 'Shanghai'
            when ProjectOfficeCode = 'MUM1' then 'Mumbai'
            when ProjectOfficeCode = 'TWN1' then 'Taipei'
            when ProjectOfficeCode = 'SKO1' then 'Seoul'
            when ProjectOfficeCode = 'SHE1' then 'Shenyang'
            when ProjectOfficeCode = 'SGP2' then 'Singapore'
            when ProjectOfficeCode = 'MLS2' then 'Kuala Lumpur'
            when ProjectOfficeCode in ('PHP4','PHP1','PHP2') then 'Manila'
            else ''
        end                                                                   as RevenueCities,
        DunsNo                                                                as DUNSNO,
        cast('USD' as nvarchar(10))                                           as Currency,
        cast(null as nvarchar(50))                                            as GCID,   -- TODO: OracleID Mapping join
        cast('Oracle' as nvarchar(50))                                        as [Source]
    from fiscal_period_fixed
)

select * from derived
