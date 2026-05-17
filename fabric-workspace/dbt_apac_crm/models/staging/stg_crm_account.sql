-- Staging: CRM Account
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_account
-- Output:  APAC_Reporting_WH.staging.stg_crm_account

with source as (
    select * from {{ source('bronze', 'src_crm_account') }}
),

renamed as (
    select
        cast(AccountKey             as nvarchar(255))  as AccountKey,
        cast(GCID                   as nvarchar(255))  as GCID,
        cast(AccountName            as nvarchar(500))  as AccountName,
        cast(ParentAccountName      as nvarchar(500))  as ParentAccountName,
        cast(GlobalParentAccountName as nvarchar(500)) as GlobalParentAccountName,
        cast(DunsNumber             as nvarchar(255))  as DunsNumber,
        cast(Tiers                  as nvarchar(255))  as Tiers,
        cast(Industry               as nvarchar(255))  as Industry,
        cast(PrimarySICCode         as nvarchar(255))  as PrimarySICCode,
        upper(ltrim(rtrim(cast(Country as nvarchar(255))))) as Country,
        cast(CreateDate             as datetime2)      as CreateDate,
        cast(ModifiedDate           as datetime2)      as ModifiedDate
    from source
    where AccountKey is not null
)

select * from renamed
