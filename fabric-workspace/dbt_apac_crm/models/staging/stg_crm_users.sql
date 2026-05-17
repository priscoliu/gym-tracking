-- Staging: CRM System Users
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_users
-- Output:  APAC_Reporting_WH.staging.stg_crm_users

with source as (
    select * from {{ source('bronze', 'src_crm_users') }}
),

renamed as (
    select
        cast(UserKey      as nvarchar(255))  as UserKey,
        -- normalise for Japan Desk join with ref_japan_desk_owners
        upper(ltrim(rtrim(cast(UserName    as nvarchar(500))))) as UserName,
        cast(UserUPN      as nvarchar(500))  as UserUPN,
        cast(UserStatus   as nvarchar(100))  as UserStatus,
        cast(LicensStatus as nvarchar(100))  as LicenseStatus,
        cast(LicenseType  as nvarchar(100))  as LicenseType,
        cast(Region       as nvarchar(255))  as Region,
        cast(BusinessUnit as nvarchar(255))  as BusinessUnit,
        upper(ltrim(rtrim(cast(ProfitCenter as nvarchar(500))))) as ProfitCenter,
        cast(SegmentLob   as nvarchar(255))  as SegmentLob,
        cast(BusinessName as nvarchar(255))  as BusinessName,
        cast(OfficeName   as nvarchar(255))  as OfficeName,
        upper(ltrim(rtrim(cast(OfficeCountry as nvarchar(255))))) as OfficeCountry,
        cast(CreatedDate  as datetime2)      as CreatedDate,
        cast(ModifiedDate as datetime2)      as ModifiedDate
    from source
    where UserKey is not null
)

select * from renamed
