-- Staging: CRM Account
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_account
-- Output:  apac_crm_silver.stg_crm_account (view)
-- Global account reference — no APAC filter (applied in intermediate layer).

with source as (
    select * from {{ source('bronze_crm', 'src_crm_account') }}
),

renamed as (
    select
        cast(accountid                   as nvarchar(50))   as AccountId,
        cast(accountnumber               as nvarchar(100))  as AccountNumber,
        cast([name]                      as nvarchar(500))  as AccountName,
        cast(parentaccountid             as nvarchar(50))   as ParentAccountId,
        cast(parentaccountidname         as nvarchar(500))  as ParentAccountName,
        cast(rs_ultimateglobalparentname as nvarchar(500))  as GlobalParentAccountName,
        cast(rs_dunsnumber               as nvarchar(50))   as DunsNumber,
        cast(rs_clientsegmentationname   as nvarchar(255))  as ClientSegmentation,
        cast(rs_industryname             as nvarchar(255))  as IndustryName,
        cast(rs_primarysiccodename       as nvarchar(255))  as PrimarySicCode,
        -- normalised for country-based joins in intermediate layer
        upper(ltrim(rtrim(cast(rs_address1countryname as nvarchar(255))))) as Country,
        cast(address1_stateorprovince    as nvarchar(255))  as StateOrProvince,
        cast(statecodename               as nvarchar(100))  as StateCodeName
    from source
    where accountid is not null
)

select * from renamed
