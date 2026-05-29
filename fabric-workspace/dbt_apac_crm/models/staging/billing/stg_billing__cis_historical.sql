-- Staging: CIS Historical (pre-2023 HWC CRM)
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_billing_cis_historical
-- Output:  apac_billing_silver.stg_billing__cis_historical (view)
-- Renames the spaced SharePoint headers + type casts. NO filters here -- the <2023-01-01 cutoff
-- and Source='CIS' hardcode live in int_billing__cis_historical_enriched.

with source as (
    select * from {{ source('bronze_billing', 'src_billing_cis_historical') }}
),

renamed as (
    select
        cast([System ID]                       as nvarchar(50))    as SystemID,
        cast([System Client Name]              as nvarchar(500))   as SystemClientName,
        cast(TX_ID                             as nvarchar(100))   as TX_ID,
        cast([Sub Product/Service]             as nvarchar(255))   as [SubProduct/Service],
        cast([Revenue Country]                 as nvarchar(50))    as RevenueCountry,
        try_cast(Revenue                       as decimal(18,2))   as Revenue,
        cast(ClientID                          as nvarchar(50))    as ClientID,
        cast([Product/Service]                 as nvarchar(255))   as [Product/Service],
        cast(Segment                           as nvarchar(50))    as Segment,
        cast([System Product Class]            as nvarchar(255))   as SystemProductClass,
        cast([Data Source]                     as nvarchar(50))    as DataSource,
        try_cast([Income Date/Inception Date]  as datetime)        as IncomeInceptionDate,
        cast([Revenue Cities]                  as nvarchar(100))   as RevenueCities,
        cast([Recurring Revenue]               as nvarchar(10))    as RecurringRevenue,
        cast([Business Type]                   as nvarchar(50))    as BusinessType
    from source
)

select * from renamed
