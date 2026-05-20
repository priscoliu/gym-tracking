-- Staging: CRM Product Class
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_productclass
-- Output:  apac_crm_silver.stg_crm_productclass (view)
-- Product/LOB reference table for opportunity classification.

with source as (
    select * from {{ source('bronze', 'src_crm_productclass') }}
),

renamed as (
    select
        cast(rs_productclassid as nvarchar(50))   as ProductClassId,
        cast(rs_name           as nvarchar(500))  as ProductClassName,
        cast(rs_segmentname    as nvarchar(255))  as SegmentName,
        cast(rs_businessname   as nvarchar(255))  as BusinessName,
        cast(statecodename     as nvarchar(100))  as StateCodeName,
        cast(createdon         as datetime2)      as CreatedOn,
        cast(modifiedon        as datetime2)      as ModifiedOn
    from source
    where rs_productclassid is not null
)

select * from renamed
