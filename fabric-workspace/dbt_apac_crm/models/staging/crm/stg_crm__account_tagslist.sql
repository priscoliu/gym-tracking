-- Staging: CRM Account-Tag Junction (raw)
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_account_tagslist
-- Output:  apac_crm_silver.stg_crm_account_tagslist (view)
-- Raw many-to-many junction. Inheritance logic (Direct/Parent/Global Parent)
-- is intermediate layer responsibility.

with source as (
    select * from {{ source('bronze_crm', 'src_crm_account_tagslist') }}
),

renamed as (
    select
        cast(accountid     as nvarchar(50))  as AccountId,
        cast(rs_tagslistid as nvarchar(50))  as TagId
    from source
    where accountid is not null
      and rs_tagslistid is not null
)

select * from renamed
