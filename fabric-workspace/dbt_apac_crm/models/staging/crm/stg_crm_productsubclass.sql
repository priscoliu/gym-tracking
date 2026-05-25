-- Staging: CRM Product Sub-Class Reference (raw)
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_productsubclass
-- Output:  apac_crm_silver.stg_crm_productsubclass (view)
-- Child of stg_crm_productclass. Intermediate joins LOB hierarchy.

with source as (
    select * from {{ source('bronze', 'src_crm_productsubclass') }}
),

renamed as (
    select
        cast(rs_productsubclassid  as nvarchar(50))  as ProductSubClassId,
        cast(rs_name               as nvarchar(255)) as ProductSubClassName,
        cast(rs_productclass     as nvarchar(50))  as ProductClassId,
        cast(rs_productclassname as nvarchar(255)) as ProductClassName,
        cast(statecodename         as nvarchar(100)) as StateCodeName,
        cast(createdon             as datetime2)     as CreatedOn,
        cast(modifiedon            as datetime2)     as ModifiedOn
    from source
    where rs_productsubclassid is not null
)

select * from renamed
