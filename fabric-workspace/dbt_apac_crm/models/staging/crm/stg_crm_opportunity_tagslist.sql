-- Staging: CRM Opportunity-Tag Junction (raw)
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_opportunity_tagslist
-- Output:  apac_crm_silver.stg_crm_opportunity_tagslist (view)
-- Raw many-to-many junction. TagName lookup is intermediate layer responsibility
-- (join to stg_crm_tagslist).

with source as (
    select * from {{ source('bronze', 'src_crm_opportunity_tagslist') }}
),

renamed as (
    select
        cast(opportunityid as nvarchar(50))  as OpportunityId,
        cast(rs_tagslistid as nvarchar(50))  as TagId
    from source
    where opportunityid is not null
      and rs_tagslistid is not null
)

select * from renamed
