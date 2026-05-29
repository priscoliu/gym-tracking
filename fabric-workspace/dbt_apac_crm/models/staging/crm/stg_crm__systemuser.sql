-- Staging: CRM System User
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_systemuser
-- Output:  apac_crm_silver.stg_crm_systemuser (view)
-- Licensed, active users only (filter already applied in Bronze).

with source as (
    select * from {{ source('bronze_crm', 'src_crm_systemuser') }}
),

renamed as (
    select
        cast(systemuserid        as nvarchar(50))   as SystemUserId,
        cast([fullname]          as nvarchar(500))  as FullName,
        cast(domainname          as nvarchar(500))  as DomainName,
        cast(territoryidname     as nvarchar(255))  as TerritoryName,
        cast(rs_officename       as nvarchar(255))  as OfficeName,
        cast(address1_country    as nvarchar(255))  as Country,
        cast(rs_profitcentername as nvarchar(500))  as ProfitCenterName
    from source
    where systemuserid is not null
)

select * from renamed
