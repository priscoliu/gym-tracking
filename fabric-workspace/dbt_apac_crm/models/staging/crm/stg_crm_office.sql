-- Staging: CRM Office
-- Source:  APAC_CRM_Analytics_bronze_LH.dbo.src_crm_office
-- Output:  apac_crm_silver.stg_crm_office (view)
-- Office reference table used in intermediate layer for APAC subregion/country fallback.

with source as (
    select * from {{ source('bronze', 'src_crm_office') }}
),

renamed as (
    select
        cast(rs_officeid      as nvarchar(50))   as OfficeId,
        cast(rs_name          as nvarchar(255))  as OfficeName,
        -- normalised for country-based joins in intermediate layer
        upper(ltrim(rtrim(cast(rs_countryname  as nvarchar(255))))) as Country,
        cast(rs_subregionname as nvarchar(255))  as SubRegionName,
        cast(statecodename    as nvarchar(100))  as StateCodeName
    from source
    where rs_officeid is not null
)

select * from renamed
