-- Staging: CRM Product / LOB Product Class
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_product
-- Output:  APAC_Reporting_WH.staging.stg_crm_product

with source as (
    select * from {{ source('bronze', 'src_crm_product') }}
),

renamed as (
    select
        cast(ProductClassKey as nvarchar(255))   as ProductClassKey,
        -- normalise for join with ref_product
        upper(ltrim(rtrim(cast(ProductName as nvarchar(500))))) as ProductName,
        cast(Segment         as nvarchar(255))   as Segment,
        cast(Business        as nvarchar(255))   as Business,
        cast(Status          as nvarchar(100))   as Status,
        cast(CreateDate      as datetime2)       as CreateDate,
        cast(ModifiedDate    as datetime2)       as ModifiedDate
    from source
    where ProductClassKey is not null
)

select * from renamed
