-- Staging: CRM CRB Key / Large Accounts
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_crb_key_large_accounts
-- Output:  apac_crm_silver.stg_crm_crb_key_large_accounts (view)
-- Key account tag inheritance — subsidiary and main accounts with LOB classification.

with source as (
    select * from {{ source('bronze', 'src_crm_crb_key_large_accounts') }}
),

renamed as (
    select
        cast(GCID           as nvarchar(255))  as Gcid,
        cast(TaggedAccount  as nvarchar(500))  as TaggedAccount,
        upper(ltrim(rtrim(cast(Country as nvarchar(255))))) as Country,
        cast(AccountTagList as nvarchar(500))  as AccountTagList,
        cast(Lob            as nvarchar(255))  as Lob,
        cast(AccountName    as nvarchar(500))  as AccountName,
        cast(KeyAccountType as nvarchar(50))   as KeyAccountType
    from source
    where Gcid is not null
)

select * from renamed
