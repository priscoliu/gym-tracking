-- Staging: CRM Opportunity-Tag Bridge
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_tags_bridge_opportunity
-- Output:  apac_crm_silver.stg_crm_tags_bridge_opportunity (view)
-- One row per opportunity-tag pair. STRING_AGG aggregation is intermediate layer responsibility.

with source as (
    select * from {{ source('bronze', 'src_crm_tags_bridge_opportunity') }}
),

renamed as (
    select
        cast(opportunityid  as nvarchar(50))   as OpportunityId,
        cast(rs_tagslistid  as nvarchar(50))   as TagId,
        cast(TagName        as nvarchar(255))  as TagName
    from source
    where opportunityid is not null
)

select * from renamed
