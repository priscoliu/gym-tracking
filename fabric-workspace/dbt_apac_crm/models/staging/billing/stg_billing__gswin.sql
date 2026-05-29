-- Staging: GSWin billing
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_gswin_crb
-- Output:  apac_billing_silver.stg_billing__gswin (view)
-- One row per GSWin policy record. Type cast only -- no filters, no joins.
--
-- WARNING: The source column "New/ \nRenew" contains a literal line-feed character
-- (from the Excel header). T-SQL accepts this inside [...] brackets, BUT some editors
-- will silently normalize the LF to a space or strip it -- if this model errors with
-- "Invalid column name 'New/ Renew'", check the raw bytes of this file.
-- If editing in Fabric, paste this column reference last to avoid trimming.

with source as (
    select * from {{ source('bronze_billing', 'src_gswin_crb') }}
),

renamed as (
    select
        cast(ClientID                     as nvarchar(50))    as ClientId,
        cast([Client Name]                as nvarchar(500))   as ClientName,
        cast([Policy Number]              as nvarchar(100))   as PolicyNumber,
        cast([Policy Type Name]           as nvarchar(255))   as PolicyTypeName,
        cast(Renewable                    as nvarchar(10))    as Renewable,
        cast([New/
Renew]                                                       as nvarchar(10))    as NewOrRenew,
        try_cast([Inception Date]         as datetime)        as InceptionDate,
        cast([Cury Code]                  as nvarchar(10))    as CuryCode,
        try_cast([Premium USD]            as decimal(18,2))   as PremiumUsd,
        try_cast([Total Brokerage in USD] as decimal(18,2))   as TotalBrokerageUsd,
        cast([Willis Line]                as nvarchar(50))    as WillisLine,
        cast(GCID                         as nvarchar(50))    as Gcid
    from source
)

select * from renamed
