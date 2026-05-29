-- Staging: CRM Tags List
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_tagslist
-- Output:  apac_crm_silver.stg_crm_tagslist (view)
-- Raw tag reference. Filtering to APAC-relevant tag set is intermediate layer responsibility.

with source as (
    select * from {{ source('bronze_crm', 'src_crm_tagslist') }}
),

renamed as (
    select
        cast(rs_tagslistid as nvarchar(50))   as TagId,
        cast(rs_name       as nvarchar(255))  as TagName,
        cast(statecode     as int)            as StateCode,
        cast(statecodename as nvarchar(100))  as StateCodeName,
        cast(createdon     as datetime2)      as CreatedOn,
        cast(modifiedon    as datetime2)      as ModifiedOn
    from source
    where rs_tagslistid is not null
)

select * from renamed
