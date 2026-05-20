-- Staging: CRM Account-Tag Bridge
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_tags_bridge_account
-- Output:  apac_crm_silver.stg_crm_tags_bridge_account (view)
-- Tag inheritance bridge covering direct, parent, and global parent account tags.

with source as (
    select * from {{ source('bronze', 'src_crm_tags_bridge_account') }}
),

renamed as (
    select
        cast(BridgeKey   as bigint)        as BridgeKey,
        cast(AccountID   as nvarchar(50))  as AccountId,
        cast(TagID       as nvarchar(50))  as TagId,
        cast(TagSource   as nvarchar(50))  as TagSource,
        cast(EntityType  as nvarchar(50))  as EntityType
    from source
    where AccountID is not null
)

select * from renamed
