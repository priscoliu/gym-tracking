-- Staging: Product Mapping reference
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_billing_product_mapping
-- Output:  apac_billing_silver.stg_billing__product_mapping (view)
-- One row per (SystemProductClass -> Product/Service / SubProduct/Service) mapping.
-- Renames spaced SharePoint headers to the conformed billing schema names.

with source as (
    select * from {{ source('bronze_billing', 'src_billing_product_mapping') }}
),

renamed as (
    select
        cast([System Product Class]  as nvarchar(255))   as SystemProductClass,
        cast([Wider Product Class]   as nvarchar(255))   as [Product/Service],
        cast([Sub-Product Class]     as nvarchar(255))   as [SubProduct/Service]
    from source
    where [System Product Class] is not null
)

select * from renamed
